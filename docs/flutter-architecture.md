# Flutter Architecture Plan (Phase 3)

Plan only — **no Dart code is written until this document is explicitly approved.**

Inputs: `docs/feature-audit.md` (17 screens + feature inventory),
`docs/apps-script-integration.md` (auth is the only networked feature),
`docs/design-system.md` (3 paper skins × light/dark, type/spacing/radius
scales, dock geometry). Source of truth for the data model:
`lib/notes/types.ts`, `lib/notes/storage.ts`, `hooks/useNotes.ts`,
`hooks/useHabits.ts`, `lib/theme.ts`, `lib/profile/index.ts`,
`lib/auth/client.ts`.

---

## 0. Shape of the problem (what drives every decision below)

Three facts from Phase 1/1b constrain everything:

1. **The app is offline-first and has no notes backend.** The only network
   call in the entire product is OTP login. So the architecture is
   "local database + UI", not "repository with remote/local sync".
2. **All data is keyed by `ownerEmail`** — multi-account on one device is a
   real, implemented feature (Dexie compound keys `[ownerEmail+id]` plus
   `lib/notes/isolation.ts` as defense-in-depth). Owner scoping must be
   structural in Flutter, not a convention a future query can forget.
3. **The whole app is one route in Next.js.** Navigation is React state
   (`tab`, `openId`, `isEditing`, `searchOpen`, `createOpen`). The port turns
   this into real routes, which is an improvement in behavior (Android back
   button, notification deep-links) with no visual change.

---

## 1. State management — **Riverpod 3** (with `riverpod_generator`)

**Decision: Riverpod.** Justification specific to this app, not generic
preference:

- The source's state graph is a **derived-value pipeline**, not an event
  stream: `notes` + `{search, sortKey, filterKey, notebookId, tag, label,
  color}` → `visibleNotes()` → grid; `notes` → agenda buckets → Plan tab;
  `checks` → heatmap/streaks. Riverpod's `Provider` composition maps 1:1
  onto those `useMemo`-style derivations, with caching and invalidation for
  free. The Bloc equivalent needs hand-written bloc-to-bloc plumbing or one
  large combined state class.
- **Everything hangs off `ownerEmail`.** A `.family` provider keyed by owner
  (`notesProvider(owner)`) makes account isolation a property of the
  provider graph — switching accounts disposes the old subtree via
  `autoDispose` rather than relying on filtering. This is the single
  strongest argument for Riverpod here.
- Async loading/empty/error states (required for every data screen by the
  brief) come free from `AsyncValue` — no hand-rolled `status` enum in every
  state class.
- Providers also cover DI (Drift database, notification service, auth
  client) and override cleanly in tests via
  `ProviderContainer(overrides: [...])`, so no separate service locator.

Rejected: Bloc (ceremony out of proportion to a mostly-local CRUD app, and
its cost lands hardest exactly on the derived-filter pipeline);
`ChangeNotifier`/`provider` (no autoDispose-by-key story for multi-account);
`setState` (that is the pattern being ported away from).

**Conventions**

- `@riverpod` code-gen throughout (`build_runner` is already required by
  Drift, so this adds no new toolchain step).
- Notifiers are the *only* writers of persisted state; widgets call notifier
  methods and never touch a DAO.
- One `AsyncNotifier` per aggregate — `NotesNotifier`, `NotebooksNotifier`,
  `TemplatesNotifier`, `HabitsNotifier`, `ProfileNotifier`,
  `SettingsNotifier`, `SessionNotifier` — mirroring
  `useNotes`/`useHabits`/`useSession` so the port stays reviewable against
  the original.
- Pure derivations (`visibleNotes`, agenda buckets, heatmap, streaks) live in
  **plain Dart functions** under `domain/`, wrapped by thin `Provider`s.
  They are direct ports of `lib/notes/filters.ts`, `agenda.ts`, `habits.ts`,
  `dashboard.ts` — and, like those, unit-testable with zero Flutter deps.

---

## 2. Local persistence — **Drift (SQLite)**

**Decision: Drift.** Justified against the actual Dexie schema, not by default:

| Evidence in the source | What it needs | Hive | Drift |
|---|---|---|---|
| `notes: '[ownerEmail+id], ownerEmail, notebookId, trashedAt, archived, updatedAt'` | compound PK + 5 secondary indexes | ✗ manual index boxes | ✓ native |
| `habitChecks: '[ownerEmail+habitId+date], [ownerEmail+date], [ownerEmail+habitId]'` | 3-column PK, two access paths | ✗ | ✓ |
| Notebook / template / habit → note relations by id | joins, referential queries | ✗ in-memory scans | ✓ |
| Trash purge `trashedAt < now - 30d` | indexed range delete | ✗ full scan | ✓ `DELETE … WHERE` |
| `visibleNotes()` — 6 orthogonal filters + 4 sorts | composable queries | ✗ | ✓ |
| Multi-account isolation | every read scoped by owner | convention only | ✓ enforced in every DAO method |
| `blobs` table (images/attachments) | binary storage | ✓ | ✓ (see below) |
| `prefs` key/value | trivial | ✓ | ✓ |

Hive would only win if the data were a flat key-value bag. It is not: the
schema is genuinely relational with compound keys, and the two features
decided in the feature audit ("mark done" filter, drag-reorder via `order`)
both want indexed, ordered queries.

**Storage layout**

- `AppDatabase` (Drift, `notes_personal.sqlite` in the app support dir) with
  tables `Notes`, `Notebooks`, `Templates`, `Habits`, `HabitChecks`,
  `Prefs`, `Attachments`. Schema `v1` = the union of Dexie's v1–v3; there is
  no reason to replay Dexie's migration history in a fresh install.
- **Attachment bytes go on disk, not in a BLOB column.** `Attachments`
  holds `(ownerEmail, id, noteId, name, mime, createdAt, relativePath)` and
  the bytes live under `<appSupport>/blobs/<ownerHash>/<id>` — keeps the DB
  small and lets `Image.file` stream without pulling bytes through SQLite.
  The `notes-blob:<id>` body URI scheme is preserved verbatim so note bodies
  and the export/import format stay compatible with existing backups.
- **Per-row writes replace the whole-bundle rewrite.** `useNotes` today
  debounces 400ms then calls `persistAccount()`, which `bulkPut`s *every*
  note and diff-deletes the rest on every settled change. In Drift each
  mutation writes only the affected rows inside a transaction. Same
  observable behavior, no data-loss window, no O(n) write amplification.
  **This is a deliberate deviation from the source's mechanism, not its
  behavior** — flagged for approval (§10 B).
- `Prefs` keeps the existing keys (`search:<email>`, `seeded:v5:<email>`)
  plus what `localStorage` holds today: theme, skin, layout, the
  onboarding-complete list, and the profile store. The **auth token is the
  one exception** — it moves to `flutter_secure_storage` (§5).
- **Seed content** (`lib/notes/seed.ts`, ~90 starter notes with generated SVG
  covers) ports as a Dart seed source behind the same `seeded:v5:<email>`
  pref, keeping the "renamed sample notes survive re-seed" rule.

**Open decision carried forward from the feature audit:** the mutation queue
(`lib/notes/queue.ts`) has no consumer. **Recommendation stands: drop it**,
along with the "N changes waiting" counter in the account panel. If you want
it kept as sync scaffolding, it becomes a `Mutations` table instead.

---

## 3. Navigation — go_router

`StatefulShellRoute.indexedStack` for the four dock tabs (preserves per-tab
scroll position, as the current React tree does), with full-screen overlays
as real routes so the Android back button works.

| Route | Screen (feature-audit #) | Notes |
|---|---|---|
| `/splash` | Session / onboarding check (#1) | redirect-only; not a visible stop on a warm start |
| `/auth` | Email + OTP (#2) | reached by guard when session is null |
| `/onboarding` | Name (#3) → skin picker (#4) | one route, two steps in a `PageView`; guarded on `hasFinishedOnboarding(email)` |
| `/notes` | Today board (#5) **or** notes grid (#6) | same branch — Today shows only when no filters are active, exactly as today |
| `/notes/search` | Search overlay (#10) | full-screen, opaque |
| `/notes/:id` | Note detail (#7) | notification deep-link target |
| `/notes/:id/edit` | Note editor (#8) | |
| `/notebooks` | Notebooks library (#11) | tab 2 |
| `/plan` | Plan / agenda (#12) with embedded habits board (#13) | tab 3; dot badge when overdue/due today |
| `/you` | Account / settings (#14) | tab 4 |
| `/privacy` | Privacy policy (#15) | pushed from `/you` |

- **Deliberately not routes** (transient UI with no back-stack identity):
  quick-capture sheet (#9), the dock Add-menu, save-as-template sheet,
  empty-trash confirm, note context menu, toasts (#17). These are
  `showModalBottomSheet` / overlay entries owned by the screen that opens
  them.
- **Deep links:** a reminder notification carries `noteId` → router
  `go('/notes/$id')`, replacing the `pendingOpen` ref + `watchReminderOpens`
  dance in `NotesApp.tsx`.
- **Guards** live in a single `redirect`: no session → `/auth`; session but
  not onboarded → `/onboarding`; else fall through — the same branch order
  as `NotesApp.tsx`.
- Full-screen note routes get a real enter transition (§10 C). Tab switches
  stay instant unless you say otherwise (§10 D).

---

## 4. Folder structure (feature-first)

```
lib/
  main.dart
  app.dart                       # ProviderScope + MaterialApp.router
  core/
    config/app_config.dart       # auth API origin (--dart-define), build flags
    db/                          # Drift database, tables, DAOs, converters
    router/app_router.dart
    theme/                       # tokens, paper_skins.dart, app_theme.dart,
                                 # extensions (PaperTokens, NoteSwatches,
                                 # AppSpacing, AppRadii, AppMotion)
    services/                    # auth_api, notifications, speech, haptics,
                                 # image_compressor, files, storage_stats
    widgets/                     # PaperStage, PaperGrain, WashiTape, Stickers,
                                 # PillButton, PaperIconButton, ToolChip,
                                 # PaperTextField, PaperSheet, EmptyState,
                                 # AppToast, PaytmTick
    utils/
  features/
    auth/         { data, domain, presentation }   # AuthScreen, OnboardingScreen
    notes/        { data, domain, presentation }   # grid, card, detail, editor,
                                                   # create sheet, search, today board
    notebooks/    { data, domain, presentation }
    plan/         { data, domain, presentation }
    habits/       { data, domain, presentation }
    account/      { data, domain, presentation }   # profile, settings, backup
  shell/
    app_shell.dart
    paper_dock.dart              # the notch/bump/FAB dock (CustomPainter)
test/
  domain/   # ports of notes.test.ts, profile.test.ts, onboarding.test.ts, auth.test.ts
  data/     # DAO tests incl. multi-account isolation
  widget/   # note CRUD, habit CRUD, streaks, filters, reorder, dock
```

Within a feature: `data/` (DAO + mappers), `domain/` (models + pure logic +
providers), `presentation/` (screens + widgets). Nothing under
`presentation/` imports Drift.

---

## 5. Services

| Service | Package | Replaces / notes |
|---|---|---|
| `auth_api_service` | `dio` | `lib/auth/client.ts` — `POST /api/auth/send-otp`, `POST /api/auth/verify-otp`, `GET /api/auth/session`, `POST /api/auth/logout`, `Authorization: Bearer`. **Explicit 15s connect/receive timeout** (the source sets none — gap noted in apps-script doc §5). Never calls Apps Script, never holds the shared secret. |
| token storage | `flutter_secure_storage` | `localStorage['notes-otp-token']` — a bearer token belongs in the keystore, not a plain pref. `peekAuthToken` (base64url payload + `exp`) ports as-is so the app opens offline. |
| `notification_service` | `flutter_local_notifications` + `timezone` | Capacitor `LocalNotifications`; exact-alarm + POST_NOTIFICATIONS permission on Android 13+, tap payload = note id, reschedule-all on launch (mirrors `resyncReminders`). |
| `speech_service` | `speech_to_text` | `lib/native/speech.ts` (browser `SpeechRecognition` has no native equivalent — a genuine substitution, with the same graceful "unavailable" path). |
| haptics | `flutter/services` `HapticFeedback` | `navigator.vibrate` — no package needed. |
| `image_compressor` | `flutter_image_compress` | canvas resize → 1280px, JPEG q0.72 — same parameters. |
| files / share | `file_picker`, `share_plus`, `path_provider` | attachment insert, `.md` and `.json` backup export, `.json` import. |
| storage stats | Drift `PRAGMA page_count` + blob dir size | `navigator.storage.estimate()`. |
| connectivity banner | `connectivity_plus` | `hooks/useOnline.ts`. |

**Config:** the API origin is a single
`String.fromEnvironment('AUTH_API_ORIGIN')` in `core/config/app_config.dart`,
supplied at build time via `--dart-define`. No `.env` file, no secret ever
compiled in. The devtunnel URL in `public/auth-origin.json` is **not**
ported — a real hosted origin is a prerequisite (§9.1).

---

## 6. Theming

`ThemeData` is generated, never hand-copied into widgets:

```
PaperSkin { classic, monsoon, festival } × Brightness { light, dark }
  → PaperPalette (paper, ink, muted, accent, cardShadow, grainOpacity)
  → ColorScheme  (explicit — NOT fromSeed; exact hexes from design-system §1)
  → ThemeData(colorScheme, textTheme, extensions: [...])
```

- **ThemeExtensions** carry what `ColorScheme` cannot express: `PaperTokens`
  (grain opacity, washi-tape tint, card shadow — which is `none` in classic
  light and must stay theme-driven), `NoteSwatches` (the 7 card colors plus
  the dark-mode `mix(card 62%, #1c1814)` rule), `AppSpacing`
  (4/8/12/16/20/24/32), `AppRadii` (pill/16/22/24/26/28/32), `AppMotion`
  (durations + `cubic-bezier(0.22,1,0.36,1)` as a `Cubic`), `AppIconSpec`
  (18px default size; the heavier-stroke treatment for active tabs).
- **`TextTheme`** is built from the rationalized scale in design-system §2
  (`display` → `displayLarge`, `headline` → `headlineMedium`, …), with
  `eyebrow` and `tabLabel` as named extension styles since Material has no
  slot for them. No literal font sizes in widgets.
- Dark-mode Android status bar uses **`#161410`**, not the source's
  mismatched `#121214` (design-system §1 flags this as a bug, not a choice).
- Theme mode, skin, and board layout live in `SettingsNotifier`, persisted in
  `Prefs` under the same three keys as `lib/theme.ts`.
- **Paper grain** is painted once as a full-screen overlay
  (`BlendMode.multiply` light / `overlay` dark), not per widget — matching
  `body::before`.
- Reduced motion: durations collapse via
  `MediaQuery.disableAnimationsOf(context)`.

**Font blocker:** the repo ships Satoshi as **`.woff2` only**
(`app/fonts/Satoshi-{400,500,700,900}.woff2`), which Flutter cannot load.
The `.otf`/`.ttf` files must come from Fontshare (same free licence) before
theming is real. Weight 900 is unused and won't be bundled.

---

## 7. Model mapping (TS → Dart)

Immutable `freezed` classes in `domain/`, Drift row classes in `data/`, with
explicit mappers — so the DB schema can change without touching the UI.

| TS | Dart | Notes |
|---|---|---|
| `Note.id: number` | `int` | timestamp-based ids preserved (`newId`) so backups round-trip |
| `dueAt: string \| null` (`YYYY-MM-DD`) | `String?` | **kept as ISO strings, not `DateTime`** — every comparison in `dates.ts`/`agenda.ts`/`habits.ts` is lexicographic on `YYYY-MM-DD`; converting a date-only field to `DateTime` invites timezone drift |
| `dueTime: string \| null` (`HH:mm`) | `String?` | same reason |
| `createdAt` / `updatedAt: number` | `int` (epoch ms) | direct |
| `labels: string[]`, `attachments: Attachment[]` | `List<String>`, `List<Attachment>` | JSON `TypeConverter` columns (Dexie stored them inline too) |
| `confirmed: bool` | `bool` | now actually reachable, via the "mark done" gesture |
| `order: int` | `int` | now actually reachable, via drag-reorder |
| `HabitCheck` | 3-column PK table | `(ownerEmail, habitId, date)` |
| `UserProfile` | `freezed` class stored as `Prefs` JSON | the sanitizers (`normalizeHandle`, `sanitizeWebsite`, `initialsFromName`) port as pure functions with their existing tests |

---

## 8. Testing

- **Pure-logic tests first** — direct ports of `lib/notes/notes.test.ts`
  (504 lines: filters, sort, `moveNote`/reorder, trash TTL, `toggleDone`,
  streaks, heatmap, agenda buckets), plus `profile.test.ts`,
  `onboarding.test.ts`, `auth.test.ts`. No Flutter binding needed, and
  they're the cheapest parity check available — **ported before their
  screens**, per the brief.
- **DAO tests** against an in-memory Drift database, including an explicit
  multi-account isolation test (account A must never read account B's rows).
- **Widget tests** for the core flows the brief names: note CRUD, habit CRUD
  + streak display, filter chips, drag-reorder, mark-done, and the dock (tab
  switch, FAB long-press → quick capture).
- `analysis_options.yaml` with **`very_good_analysis`** from the first commit.

---

## 9. Prerequisites / blockers (need you, not code)

1. **A real hosted origin for the Next.js `/api/auth/*` routes** (Vercel or
   similar) to replace the devtunnel in `public/auth-origin.json`. Without
   it, the Flutter auth screen can't be tested on a device.
2. **Satoshi `.otf`/`.ttf`** files (§6).
3. **Where the Flutter project lives.** Proposal: a `flutter/` directory in
   this repo — keeps the docs, the Apps Script, and the Next.js API that
   Flutter depends on together; the existing Capacitor `android/` folder is
   untouched. Say if you'd rather it be a separate repo.
4. **`applicationId`** — not invented; confirmed with you at Play-Store-prep
   time, per the brief.

---

## 10. Decisions to confirm before scaffolding

| # | Question | Recommendation |
|---|---|---|
| A | Drop the no-op mutation queue and the "N changes waiting" counter? | **Drop** |
| B | Per-row Drift writes instead of the whole-bundle debounced rewrite? | **Yes** (§2) |
| C | Give full-screen note detail/editor an enter transition? | **Yes** — the source's abrupt cut is an inconsistency, not a design choice |
| D | Cross-fade on tab switches? | **No** for now — keep the exact clone; it stays in `ux-suggestions.md` |
| E | Project location (§9.3) | `flutter/` inside this repo |
| F | Voice dictation via `speech_to_text` | **Yes** — no native equivalent of the browser API; behavior and the "unavailable" path match |

Everything else follows the exact-clone rule from the brief: no visual or
behavioral deviation beyond the two features already decided in the feature
audit ("mark done", drag-to-reorder) and the items listed above.
