# Feature Audit — Next.js Notes + Habit Tracker (Phase 1)

Read-only inventory of every screen, flow, and feature in the existing Next.js
app, for Flutter feature-parity planning. Status legend:

- ✅ **Done** — fully implemented and reachable from the UI.
- 🟡 **Partial** — data model / logic exists, but not fully wired to a UI gesture, or intentionally minimal.
- ⚪ **Orphaned** — built, but not imported/used anywhere; dead code.
- ❌ **Missing** — referenced by the porting brief but genuinely absent from this app.

There is **no Next.js page routing** beyond the single `/` route — `app/page.tsx`
just renders `<NotesApp />`. All navigation between "screens" is client-side
React state inside one component tree (tabs, overlay booleans, an "open note
id"), not `next/navigation` routes. For the Flutter port this maps to
`go_router` routes driven by app state / an `IndexedStack`, not literal
page-per-URL routing — see Phase 3.

There are **no explicit TODO/FIXME/"not implemented"/"stub" markers anywhere**
in the codebase (verified by a repo-wide search). Every gap below was found by
reading the code, not by comments flagging it.

---

## 1. Screens & flows

| # | Screen / flow | Component(s) | Status | Notes |
|---|---|---|---|---|
| 1 | Splash / session check | `NotesApp.tsx` (loading branch) | ✅ | Spinner in `PaperStage` while session/onboarding state resolves. |
| 2 | Auth — email + OTP login | `features/auth/AuthScreen.tsx` | ✅ | See `docs/apps-script-integration.md` for the OTP contract. Dev-only "code in terminal" fallback must be excluded from the Flutter/production build. |
| 3 | Onboarding — name entry | `features/auth/OnboardingScreen.tsx` (step 0) | ✅ | Skippable. Not persisted mid-flow (all local component state). |
| 4 | Onboarding — paper skin picker | `features/auth/OnboardingScreen.tsx` (step 1) | ✅ | Picks one of 3 "paper skins" (Classic/Monsoon/Festival); skippable, back button to step 0. |
| 5 | Home dashboard ("Today") | `features/notes/TodayBoard.tsx` | ✅ | Shown only when Notes tab + no filters active. Greeting varies by hour, progress ring, 7-day sparkline, notebook tiles, metric chips. |
| 6 | Notes list (grid/masonry) | `features/notes/NotesGrid.tsx` + `NoteCard.tsx` | ✅ | Filter chips (All/Open/Due/Done/Archive/Trash), notebook filter, color-swatch filter, label filter, sort. |
| 7 | Note viewer (read-only) | `features/notes/NoteDetail.tsx` | ✅ | Full-screen overlay. Wiki-link navigation, backlinks, attachments, due chip. |
| 8 | Note editor | `features/notes/NoteEditor.tsx` | ✅ | Most feature-dense screen — see §2 table below. |
| 9 | Quick capture sheet | `features/notes/CreateSheet.tsx` | ✅ | Bottom sheet from long-press/alt-action on the FAB. |
| 10 | Search | `features/notes/SearchOverlay.tsx` | ✅ | Full-screen overlay, live filter, recents (capped at 8), color/label quick-filters. |
| 11 | Notebooks library | `features/notes/NotebooksView.tsx` | ✅ | Create/rename/recolor notebook, tap to filter. **No delete-notebook action.** |
| 12 | Plan (agenda) | `features/notes/PlanView.tsx` | ✅ | Overdue/Due today/Coming up/Open-lists buckets; embeds Habit tracker. |
| 13 | Habit tracker | `features/notes/HabitsBoard.tsx` | ✅ | GitHub-style 18-week heatmap, streak + best-streak, add/remove habit, tap past/today cells to toggle (future cells disabled). |
| 14 | Account / settings ("You") | `features/account/AccountPanel.tsx` | ✅ (not yet read in depth — see follow-up) | Profile, theme, skin, layout, storage stats, pending-changes count, backup export/import, logout. |
| 15 | Privacy policy | `app/privacy/page.tsx` | ✅ (not yet read in depth) | Static page. |
| 16 | Empty states | `components/ui/EmptyState.tsx` | ✅ | Contextual copy per filter (trash/due/label/default). |
| 17 | Toasts / undo | `components/ui/Toast.tsx` | ✅ | Snackbar with optional action (e.g. "Undo" after delete), auto-dismiss (2.2s / 4.6s with action). |

## 2. Note editor — feature breakdown (screen #8 is worth its own table, it's the core flow)

| Feature | Status | Notes |
|---|---|---|
| Title/body inline editing | ✅ | `patch()` recomputes an 80-char `preview` on every change. |
| Color picker (7 preset colors) | ✅ | |
| Checklist insertion / toggle | ✅ | Custom mini-Markdown (`- [ ]`), not a rich checklist widget. |
| Image insert (file picker) | ✅ | Client-side compression before storage (`lib/notes/image.ts`, canvas resize to 1280px, JPEG q0.72). |
| File attachment (non-image) | ✅ | Stored as `BlobRecord` in IndexedDB, referenced via `notes-blob:<id>` URI in body or in `attachments[]`. |
| Voice dictation | ✅ | Browser `SpeechRecognition` API (`lib/native/speech.ts`) — **web-only API, needs a native equivalent (e.g. `speech_to_text` package) in Flutter.** |
| Markdown preview toggle | ✅ | Custom renderer, intentionally minimal — headings h1–h3, `- [ ]` tasks, `-`/`•` bullets, images. **No bold/italic/code/tables.** Flag as a deliberate scope decision, not a bug, when deciding Flutter parity. |
| Save as template | ✅ | |
| Export single note to `.md` | ✅ | |
| Tag field | ✅ | Free-text, drives `'tag'` sort key and search. |
| Notebook picker | ✅ | `<select>` of existing notebooks. |
| Due date/time + alert lead-time | ✅ | `ReminderFields.tsx`; feeds `lib/notes/reminders.ts` → local notification scheduling. |
| Labels (custom + preset chips) | ✅ | Deterministic color hashing per label (`lib/notes/labels.ts`). |
| Wiki-link `[[Note Title]]` insertion + picker | ✅ | `lib/notes/backlinks.ts`. |
| Remove attachment | ✅ | |
| Pin / unpin | ✅ | Via NoteCard/NoteDetail context actions, not inside the editor itself. |
| Archive / unarchive | ✅ | Via context menu / NoteDetail. |
| Move to trash / restore / delete forever | ✅ | 30-day trash auto-purge (`TRASH_TTL_MS`). |
| Duplicate note | ✅ | Also duplicates any attached blobs with new IDs. |
| **Mark note "done" (`confirmed` field + `toggleDone`)** | ✅ **Decided: port as a real feature** | Data model field exists, `useNotes().toggleDone` exists and is unit-tested, drives the `'done'`/`'open'` filter — but was never wired to a UI in the Next.js app (`components/ui/PaytmTick.tsx`, a fully animated checkmark toggle, was built for this purpose and never imported anywhere). **Decision (2026-09-05): the Flutter app will wire this up as a genuine, tappable "mark done" gesture** — e.g. a checkmark on `NoteCard`/`NoteDetail` calling the equivalent of `toggleDone`, styled after `PaytmTick.tsx`'s check-draw/ripple animation. This is a Flutter-side addition beyond the Next.js app's actual shipped behavior, not a straight port. |
| **Drag-to-reorder notes** | ✅ **Decided: port as a real feature** | `lib/notes/filters.ts::moveNote()` + `hooks/useNotes.ts::reorder` are implemented and unit-tested (`lib/notes/notes.test.ts:162`), and `Note.order` exists — but no drag gesture was ever wired in the Next.js UI. **Decision (2026-09-05): the Flutter app will implement real drag-to-reorder** (e.g. `ReorderableListView`/`ReorderableGridView` on the notes grid, writing back through `order` the same way `moveNote()` does) so the existing, tested reorder logic actually becomes reachable. Also a Flutter-side addition beyond the Next.js app's shipped behavior. |
| **Swipe-to-delete/archive** | ❌ **Missing** | Not implemented anywhere — no swipe gesture handlers exist. Trash/Archive are reachable only via long-press context menu or explicit buttons. |

## 3. Every other feature, including small/easy-to-miss ones

| Feature | Status | Where |
|---|---|---|
| Long-press context menu (480ms) | ✅ | `NoteCard.tsx` (pin/archive/duplicate/trash), also right-click support for desktop/web testing. |
| Long-press alt-actions elsewhere | ✅ | FAB long-press → quick capture (`AppTabs.tsx`); saved-template chip long-press → delete (`NotesApp.tsx`'s local `TemplateChip`). Same 480–550ms hand-rolled pattern in 3 places, no shared gesture library. |
| Bottom nav + integrated FAB | ✅ | `AppTabs.tsx` — 4 tabs (Notes/Books/Plan/You) with a center-notch "+" FAB built into the same dock, not a separate floating button. `Fab.tsx` is a **standalone unused/orphaned component**, superseded by the dock FAB — exclude from the port. |
| "Add" action menu (7 fixed actions + saved templates) | ✅ | Staggered fade-in per row. |
| Search recents | ✅ | Capped at 8 (`SEARCH_RECENTS_LIMIT`), persisted per account. |
| Filters: All/Open/Due/Done/Archive/Trash | ✅ | |
| Filter by notebook / label / color | ✅ | |
| Sort: newest/oldest/title/tag | ✅ | |
| Tags vs Labels (two separate concepts) | ✅ | `tag` = single free-text field (sort key); `labels[]` = multiple colored chips. Worth calling out explicitly since they're easy to conflate. |
| Reminders → local device notifications | ✅ | Capacitor `LocalNotifications`, exact alarms, tap-to-open jumps straight to the note (`pendingOpen` ref + `watchReminderOpens`). **Not email** — see Apps Script doc. |
| Haptic feedback | ✅ | `lib/native/haptics.ts::tickHaptic` (`navigator.vibrate`), called from: Add-menu open, habit add/toggle, checklist-check (only on check, not uncheck). `PaytmTick.tsx` also calls it but is unused. |
| Offline banner | ✅ | `hooks/useOnline.ts` (`navigator.onLine` + online/offline events) → banner in `NotesApp.tsx`. |
| Offline-first local persistence | ✅ | Dexie/IndexedDB, fully local, works with no network at all. |
| **"Pending changes" / sync queue** | 🟡 **Partial (scaffolding only)** | `lib/notes/queue.ts` + `enqueueMutation` calls throughout `storage.ts` implement a capped (120), deduplicated local mutation log, surfaced as an "N changes waiting" counter in AccountPanel — **but nothing anywhere reads this queue to sync to a server.** There is no backend/DB for notes at all (only the OTP auth API touches a server). Treat as: **local persistence is complete; cloud sync was scaffolded but never built.** Decide explicitly whether Flutter should (a) drop this queue/counter entirely since it does nothing, or (b) keep it as future-sync scaffolding. Recommend (a) unless a real sync backend is planned. |
| Multi-account support on one device | ✅ | All storage keyed by `ownerEmail` (Dexie compound keys + `lib/notes/isolation.ts` defense-in-depth filtering); profiles keyed by email in `lib/profile`. |
| Theming: light/dark | ✅ | `lib/theme.ts`, class-toggle based. |
| Theming: "paper skin" (Classic/Monsoon/Festival) | ✅ | 3 skins × light/dark = 6 palette variants, `data-skin` attribute, CSS custom properties. |
| Board layout: masonry ↔ grid | ✅ | Toggle in `AppHeader`, persisted. |
| Decorative "paper sticker" illustrations | ✅ | `components/ui/PaperStickers.tsx` — hand-drawn inline SVGs (star/spark/flower/heart/sun/moon/smile/blob/squiggle/tape/clover), floating CSS animation. Core to the app's visual identity — full extraction happens in Phase 2. |
| Animations/transitions | ✅ | All hand-rolled CSS `@keyframes` (no framer-motion/react-spring/etc. — confirmed via `package.json`, zero animation libraries). Sheet slide-up, fade-up, card stagger-in, sticker float, checkmark draw. |
| Backup export (JSON) | ✅ | `lib/notes/export.ts`, includes ID-collision handling on import. |
| Backup export (Markdown) | ✅ | Concatenated notes with meta header; attachment binaries **not** embedded (filename only). |
| Backup import | ✅ | JSON only. |
| Image compression | ✅ | Canvas resize + JPEG re-encode before storage. |
| Storage usage display | ✅ | `navigator.storage.estimate()` shown in AccountPanel. |
| Wiki-links `[[Note Title]]` + backlinks | ✅ | `lib/notes/backlinks.ts`. |
| Sample/starter content on first run | ✅ | `lib/notes/seed.ts`, ~90 hardcoded notes with generated SVG cover images — this is onboarding content, not a stub. |
| Onboarding tooltips / coach marks | ❌ **Missing** | Not present anywhere — onboarding is only the 2-step name/skin form, no in-app tooltip overlay system. (Matches the porting brief's checklist item, confirmed absent, not an oversight in the audit.) |

## 4. Orphaned / dead code (exclude from 1:1 port, flag for a product decision)

| Item | Why it's dead | Recommendation |
|---|---|---|
| `features/shell/Fab.tsx` | Standalone FAB component, never imported anywhere — superseded by the dock-integrated FAB in `AppTabs.tsx`. | Don't port; use the dock+notch+FAB pattern from `AppTabs.tsx` as the source of truth. |
| `components/ui/PaytmTick.tsx` | Fully built animated checkmark (ripple, pop, SVG check-draw, haptic) — never imported anywhere. | **Decided:** port its animation style to a real, wired-up "mark done" gesture in Flutter (toggles `confirmed` via the `toggleDone` equivalent). |
| Drag-to-reorder (`moveNote`/`reorder`) | Data layer + tests exist; no UI gesture. | **Decided:** implement real drag-reorder in Flutter (e.g. via `ReorderableListView`/`ReorderableGridView`), writing back through `order` the same way `moveNote()` does. |
| Sync/mutation queue (`queue.ts`) | Local bookkeeping with no consumer. | Recommend dropping in Flutter unless a server-sync feature is actually planned; don't reimplement a queue that goes nowhere. |

## 5. Dependencies observed (relevant to Flutter package choices later)

`package.json` — no animation/gesture libraries (no framer-motion, react-beautiful-dnd, dnd-kit, @use-gesture, react-spring). Runtime deps are minimal: `@capacitor/*` (native shell, local notifications), `axios` (not used for Apps Script — that's server-side `fetch`; need to confirm what axios is used for), `dexie` (IndexedDB), `lucide-react` (icon set — relevant for Phase 2 iconography), `next`, `react`. All UI motion is hand-rolled CSS.

## 6. Screens/files not yet read in full depth (follow-up before Phase 2/3)

- `features/account/AccountPanel.tsx` — settings screen; confirmed to exist and host theme/skin/layout toggles, backup export/import, storage stats, pending-count, logout, but not yet read line-by-line.
- `app/privacy/page.tsx`, `app/layout.tsx`, `app/globals.css` (full 594-line design token extraction — deferred to Phase 2 by design).
- `lib/native/speech.ts` — confirmed used for voice dictation (browser SpeechRecognition), not yet read line-by-line for its exact API surface.
- Exact use of `axios` in `package.json` (not yet located — flagging so Phase 1b conclusions on "how the app talks to servers" get double-checked before Phase 3).

---

## Summary for parity planning

The app is **almost entirely local/offline** — the only server-touching feature
in the whole codebase is OTP email login via Apps Script (documented
separately). Everything else (notes, notebooks, templates, habits, backups,
reminders) is IndexedDB + local device notifications, no backend. That
materially simplifies the Flutter architecture: Drift/Hive replaces Dexie
1:1, and the only network client needed is the one hitting the Next.js auth
API. Three features were genuinely half-built in the source app (done/marked
toggle, drag-reorder, sync queue) — despite having code and tests behind
them, they were **not** "already working" in the shipped Next.js app.
**Decided (2026-09-05):** "mark done" and drag-to-reorder will be built as
real, wired-up features in Flutter — genuine additions beyond what the
Next.js app actually did, using the existing tested data-layer logic
(`toggleDone`, `moveNote`/`reorder`, `Note.order`) as the implementation
basis. The sync/mutation queue (`queue.ts`) remains an open decision — still
recommend dropping it in Flutter unless a real sync backend is planned,
since nothing consumes it today.
