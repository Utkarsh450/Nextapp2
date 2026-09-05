# Google Apps Script Integration — Mapping (Phase 1b)

## Summary

The Apps Script Web App is used for **exactly one purpose**: sending and verifying
the 6-digit email login code (OTP) used by `features/auth/AuthScreen.tsx`. There is
no "note shared" email, no "habit reminder" email, and no "weekly summary" email —
those don't exist in this app. Reminders are delivered as **local device
notifications** via Capacitor (`lib/native/notifications.ts`), not email.

Crucially, **the Next.js app never lets the browser/mobile client call Apps Script
directly.** The client calls the Next.js API routes (`/api/auth/*`); those routes
run server-side and are the only thing that talks to Apps Script. This matters a
lot for the Flutter port — see "Architectural implication" below.

```
Flutter app (or browser/Capacitor WebView)
        │  POST /api/auth/send-otp   { email }
        │  POST /api/auth/verify-otp { email, otp }
        │  GET  /api/auth/session
        │  POST /api/auth/logout
        ▼
Next.js API routes (app/api/auth/*.ts)  ── holds the shared secret ──▶  Apps Script Web App (doPost)
                                                                              │
                                                                              ▼
                                                                      MailApp.sendEmail (Gmail)
```

## 1. Where the Web App URL lives

- Env var: `APPS_SCRIPT_URL` — read only in `lib/auth/otp.ts` (`callAppsScript`), server-side only. **Not** prefixed `NEXT_PUBLIC_*`, so it is never bundled into client JS.
- Shared secret: `APPS_SCRIPT_SECRET` (falls back to `AUTH_SECRET` if unset) — sent as a `secret` field in every POST body; the Apps Script side checks it against a Script Property named `OTP_SECRET` (`apps-script/Code.gs:26-29`).
- `.env.example` (repo root) documents both as placeholders:
  ```
  APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec
  APPS_SCRIPT_SECRET=replace-with-the-same-value-as-OTP_SECRET-in-apps-script
  ```
- **No secret is hardcoded anywhere in the repo.** `.env.example` only has placeholder text, and the real values live in `.env.local` (gitignored) / host env config. `apps-script/Code.gs` itself reads `OTP_SECRET` from `PropertiesService.getScriptProperties()`, not from a literal in the file. ✅ Nothing to flag here.
- Dev-only fallback: if `APPS_SCRIPT_URL` is unset and `NODE_ENV !== 'production'`, `sendEmailOtp`/`verifyEmailOtp` skip Apps Script entirely and keep the OTP in an in-memory `Map`, logging it to the server console (`console.info('[notes otp] ... → 123456 (dev only...)')`). This must **not** be ported to the Flutter/production build — it's a local-dev convenience only.

## 2. Every place the Apps Script URL is called from

Only one call site: `callAppsScript()` in `lib/auth/otp.ts:23-50`, used by:
- `sendEmailOtp()` (`lib/auth/otp.ts:52`) → invoked from `POST /api/auth/send-otp` (`app/api/auth/send-otp/route.ts`)
- `verifyEmailOtp()` (`lib/auth/otp.ts:76`) → invoked from `POST /api/auth/verify-otp` (`app/api/auth/verify-otp/route.ts`)

No other feature (notes, habits, notebooks, exports, etc.) touches Apps Script or sends any email.

## 3. Request/response shape — client ⇄ Next.js API (what Flutter must mirror)

These are the endpoints a Flutter client actually needs to call — **not** Apps Script directly (see architectural note below).

### `POST {origin}/api/auth/send-otp`
- Headers: `Content-Type: application/json`; `Authorization: Bearer <token>` if a token is already stored (harmless/unused here, but `authFetch` always attaches it when present).
- Body: `{ "email": string }`
- Response `200`: `{ "ok": true, "via": "email" | "terminal" }` (`via: "terminal"` is the dev-only console fallback — production always returns `"email"` or an error)
- Response `400`: `{ "ok": false, "error": string }` — possible errors: `"Enter a valid email address"`, `"Apps Script URL is missing"` (prod, misconfigured), `"Wait a minute before requesting another code"` (Apps Script throttle, 1/min/email), or the Apps Script "invalid response" error below.
- CORS: also serves `OPTIONS` → 204 with `Access-Control-Allow-Origin` (from `AUTH_CORS_ORIGIN`, default `*`), `-Headers: Content-Type, Authorization`, `-Methods: GET, POST, OPTIONS`.

### `POST {origin}/api/auth/verify-otp`
- Body: `{ "email": string, "otp": string }` (6 digits; whitespace stripped client- and server-side)
- Response `200`: `{ "ok": true, "token": string, "session": { "email": string, "name": string, "handle": string } }`. Also sets an httpOnly cookie `notes_otp_session` (7-day maxAge) — irrelevant for a native client; the `token` field is what a native client should persist and send back as `Authorization: Bearer <token>`.
- Response `400`: `{ "ok": false, "error": string }` — `"Enter the 6-digit code"`, `"Code expired. Request a new one."`, `"Too many attempts. Request a new code."`, `"That code is incorrect"`.
- Token format: `base64url(JSON{email, exp}) + "." + HMAC-SHA256(payload, AUTH_SECRET)`, 7-day expiry (`lib/auth/session.ts`). This is a **stateless signed token**, not a Apps-Script/DB-backed session — verifiable by anything holding `AUTH_SECRET`, but that secret must stay server-side.

### `GET {origin}/api/auth/session`
- Headers: `Authorization: Bearer <token>` (or cookie, on same-origin web).
- Response: `{ "session": { email, name, handle } | null }` — never errors; an invalid/expired/missing token just yields `session: null`.

### `POST {origin}/api/auth/logout`
- No body needed. Clears the server cookie. Client always clears its locally stored token/session regardless of the HTTP result (`hooks/useSession.ts:138-146`) — logout is "best effort" against the server.

### Client-side origin resolution (`lib/auth/client.ts`, `hooks/useSession.ts`)
Because the Capacitor/Android build is a **static export** (API routes are moved out of the bundle for that build — see `scripts/build-capacitor.mjs`), the app running on a phone has no same-origin API to call. It resolves an origin in this order:
1. `NEXT_PUBLIC_AUTH_API_ORIGIN` — baked in at build time (env var, empty for browser `pnpm dev`).
2. Else, fetch bundled static file `/auth-origin.json` at runtime and use its `"origin"` field.
3. If neither yields anything, requests go to the relative path (`credentials: 'include'`, cookie-based) — only works when the frontend and API are actually served from the same origin (plain web deploy, not the packaged Android app).

`public/auth-origin.json` currently contains a **devtunnel URL** (`https://gljk02zb-3000.inc1.devtunnels.ms`) — this is a temporary tunnel to the developer's own machine for phone-over-USB testing, not a real backend deployment. **This is not a usable production endpoint and must be replaced.**

## 4. What Apps Script (`apps-script/Code.gs`) does, end to end

- `doGet()` → health check, returns `{ ok: true, service: 'notes-otp' }`, no auth required.
- `doPost(e)`:
  - Parses JSON body, checks `data.secret === OTP_SECRET` (Script Property) → else `{ ok:false, error:'Unauthorized' }`.
  - Validates email regex → else `{ ok:false, error:'Enter a valid email address' }`.
  - Dispatches on `data.action`: `"send"` → `sendOtp_`, `"verify"` → `verifyOtp_`, else `{ ok:false, error:'Unknown action' }`.
- `sendOtp_(email)`:
  - Uses `LockService` + a `CacheService` throttle key (`otp_wait_<email>`, 60s) to rate-limit to 1 request/minute/email.
  - Generates a random 6-digit code, stores `{ hash: sha256(email+':'+otp), tries: 0 }` in `CacheService` for 600s (10 min) — **the raw OTP is never persisted**, only its hash.
  - Sends via `MailApp.sendEmail` — subject `"Your Notes login code"`, an inline-styled HTML body embedding the plain 6-digit code (`apps-script/Code.gs:62-71`). Fixed template, no personalization.
  - Returns `{ ok: true }` or the throttle error.
- `verifyOtp_(email, otp)`:
  - Requires exactly 6 digits.
  - Looks up the cached hash record; increments `tries`; after 5 failed tries the record is evicted (`"Too many attempts..."`); expired cache entry → `"Code expired..."`; hash mismatch → `"That code is incorrect"` (record kept, tries incremented).
  - On success, clears both cache entries (OTP + throttle key) and returns `{ ok: true }`.
- All responses are `ContentService.createTextOutput(JSON.stringify(payload)).setMimeType(JSON)`.

## 5. How the Next.js app handles success/failure calling Apps Script

`callAppsScript()` (`lib/auth/otp.ts:23-50`):
- POSTs JSON with `redirect: 'manual'` — Apps Script `/exec` URLs 302-redirect from `script.google.com` to `script.googleusercontent.com`; the code manually reads the `location` header and re-fetches it itself rather than trusting automatic redirect-following. **This is exactly the redirect quirk flagged in the task prompt — already handled here, and the Flutter HTTP client will need equivalent handling** (see below).
- If the final response body isn't valid JSON (e.g., Apps Script served an HTML "sign in" page because the deployment isn't set to "Execute as: Me / Anyone"), it returns `{ ok:false, error:'Apps Script returned an invalid response. Redeploy the web app as Anyone.' }` — a deployment-misconfiguration error surfaced straight to the user via the API response chain.
- **No explicit fetch timeout** is set on this call — if Apps Script hangs, the Next.js request just hangs too (bounded only by the platform's own request timeout). This is a latent gap in the original app, not something to blindly copy — the Flutter client should set an explicit timeout (Phase 1b flags this as a place to *improve*, not just replicate).
- No retry logic on the Next.js→Apps Script leg.

Client UI failure handling (`features/auth/AuthScreen.tsx`):
- Any thrown/network error from `sendOtp`/`verifyOtp` → generic `"Network error. Try again."`.
- Any `{ ok:false, error }` response → that exact `error` string is shown inline under the form.
- `via === 'terminal'` (dev fallback) → UI shows *"Look for `[notes otp] {email} → 123456`"* instead of "we sent an email" copy. Should be excluded from a production Flutter build.
- `hooks/useOnline.ts` exposes `navigator.onLine`/`online`/`offline` browser events for general connectivity display elsewhere in the app, but the auth screen itself doesn't consult it before sending — it just tries the request and reports the network error if it fails.

## 6. Does the Apps Script itself need changes for a native (non-browser) client?

- **CORS**: Not applicable here, because the native client never calls Apps Script directly — it calls the Next.js API, which calls Apps Script server-to-server (no browser CORS involved on that leg). If a future design instead has Flutter call Apps Script directly, Apps Script Web Apps don't return normal CORS headers by default and `doPost` would need to be adapted (and the redirect-following behavior above would need to be replicated in `dio`/`http` — set `followRedirects: false` and re-request the `Location` header manually, exactly like the Next.js code does).
- **Recommendation: keep the current shape** — do not have Flutter call Apps Script directly (see next section).

## 7. Architectural implication for the Flutter app (decision needed)

The OTP secret model only works if something server-side holds `APPS_SCRIPT_SECRET`/`AUTH_SECRET` and never ships it to a client. Right now that "server-side" is the Next.js API routes. A native Flutter app has **no such trusted place** — anything bundled into the APK can be extracted.

So, unlike the prompt's assumption that the mobile app might call Apps Script directly:
- **`lib/core/services/email_service.dart` (or rather, an `auth_service.dart`) should call the existing Next.js `/api/auth/*` endpoints, not Apps Script.** This mirrors exactly what the current web/Capacitor client does, keeps the shared secret server-side, and requires zero Apps Script changes.
- This means **the Next.js API routes need to stay deployed somewhere Flutter can reach over HTTPS** (e.g. Vercel), replacing the throwaway devtunnel URL in `public/auth-origin.json`. That base URL is the one config value that belongs in `lib/core/constants/` (or `flutter_dotenv`), swappable at build time — analogous to `NEXT_PUBLIC_AUTH_API_ORIGIN` today.
- If you'd rather have Flutter talk to Apps Script directly and drop the Next.js API layer entirely, that's possible but means embedding `APPS_SCRIPT_SECRET` in the compiled app — **recommended against**, since it can be pulled out of the APK. Flagging this for your decision before Phase 3 architecture planning; default assumption unless you say otherwise: **keep the Next.js API layer as the backend Flutter talks to.**

## 8. Nothing hardcoded to flag as a secret leak

- `APPS_SCRIPT_URL` / `APPS_SCRIPT_SECRET` / `AUTH_SECRET`: env-var only, never literal in source.
- `apps-script/Code.gs`: reads `OTP_SECRET` from Script Properties, not a literal.
- The only URL literal in the repo is the **devtunnel URL** in `public/auth-origin.json` — not a secret, but a stale dev artifact that must be replaced with a real deployed API origin before Flutter (or anyone) ships against it.
