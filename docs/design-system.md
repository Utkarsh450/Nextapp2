# Design System — Notes + Habit Tracker (Phase 2)

Extracted from `app/globals.css` (Tailwind v4, CSS-first config — there is no
`tailwind.config.js`; every token is a CSS custom property), `app/layout.tsx`,
and Tailwind-utility usage across every component. Goal: enough detail to
rebuild the exact visual identity in Flutter without seeing the original.

## 1. Color palette

Three "paper skins" (**Classic**, **Monsoon**, **Festival**), each with a
light and dark variant — 6 total palette combinations. Skin is set via
`document.documentElement.dataset.skin` (`classic` = no attribute, the
default); mode via a `.dark` class on `<html>`.

| Token (semantic role) | Classic light | Classic dark | Monsoon light | Monsoon dark | Festival light | Festival dark |
|---|---|---|---|---|---|---|
| `--paper` (background/surface) | `#f4e8dc` | `#161410` | `#e4eee8` | `#101816` | `#f6ead2` | `#1a140c` |
| `--ink` (text-primary) | `#2b261f` | `#efe8dc` | `#1a2c24` | `#e6f0ea` | `#3a2414` | `#f3e6c8` |
| `--muted` (text-secondary) | `#6b6158` | `#9a9288` | `#5d7268` | `#8aa396` | `#8a6a48` | `#b49a72` |
| `--accent` (success/primary-accent) | `#00b259` | `#3dcf7a` | `#2f8f6b` | `#4cba8c` | `#c8891a` | `#e0b14a` |
| `--shadow-card` (elevation) | `none` | `0 1px 0 rgba(255,255,255,.06) inset, 0 14px 36px rgba(0,0,0,.5)` | `0 1px 0 rgba(255,252,246,.72) inset, 0 10px 28px rgba(24,40,32,.1)` | `0 1px 0 rgba(255,255,255,.06) inset, 0 14px 36px rgba(0,0,0,.5)` | `0 1px 0 rgba(255,248,230,.8) inset, 0 10px 28px rgba(80,48,16,.1)` | `0 1px 0 rgba(255,255,255,.06) inset, 0 14px 36px rgba(0,0,0,.55)` |
| `--grain-opacity` (paper texture) | `0.14` | `0.11` | `0.14` (inherits mode) | `0.11` | `0.14` | `0.11` |

Static (skin-independent) tokens: `--radius-card: 28px`, `--ease-out:
cubic-bezier(0.22, 1, 0.36, 1)`, `--duration: 200ms`, `--background:
var(--paper)`, `--foreground: var(--ink)`.

**Note cards get their own 7-color palette**, independent of the paper skin
(`lib/notes/types.ts` `NOTE_COLORS`, reused as `NOTEBOOK_COVERS`):
```
#C5CA8A (olive)   #E7A3A3 (dusty pink)   #BEC3BC (sage grey)   #E89569 (terracotta)
#E8C44A (gold)    #D4C4E8 (lavender)     #A9D4C4 (mint)
```
A note/notebook's `color` field sets its card background directly (via a
per-card `--card` CSS variable); in dark mode the card color is mixed 62%
with `#1c1814` (`color-mix(in srgb, var(--card) 62%, #1c1814)`) rather than
using a separate dark swatch set.

**Danger/error text**: `#7a2418` (used for form errors and destructive-row
text) — not tokenized as a CSS variable, always this literal hex.

**Global paper-grain texture**: a fixed, full-screen SVG fractal-noise
overlay (`body::before`, z-index 80) sits over the *entire app* on every
skin — `mix-blend-mode: multiply` in light mode, `overlay` in dark, opacity
from `--grain-opacity`. This is not a per-skin asset; same noise texture
everywhere. **Recommend implementing as a repeating noise texture (PNG/SVG
asset) painted behind the whole app with a `BlendMode`, not per-widget.**

**⚠️ Known inconsistency (not a deliberate choice):** `app/layout.tsx`'s
`viewport.themeColor` sets the dark-mode Android status-bar color to
`#121214`, but the actual `.dark` paper background is `#161410` — these
don't match. Use `#161410` in Flutter, not `#121214`.

## 2. Typography

**Font**: Satoshi (self-hosted via `next/font/local`, 4 static weight files:
400/500/700/900, `display: swap`), fallback `Arial, Helvetica, sans-serif`.
Weight **900 is loaded but never used anywhere** in the app — treat as
unused/reserved, don't build a "display 900" style unless you want one.
Monospace (`Geist_Mono`) is used exactly once, for the dev-only OTP terminal
hint text — not part of the real design system.

**Weight-to-role mapping observed in practice** (no explicit design tokens —
inferred from usage): headings/titles/card-titles/stat numbers → **bold
(700)**; buttons, chips, tab labels, secondary emphasis → **medium/semibold
(500–600)**; body text → **regular (400)**, unweighted.

**Reverse-engineered type scale.** The source app has no defined type scale
— every component picks its own arbitrary Tailwind `text-[…]rem` value, so
dozens of one-off sizes exist (0.65 / 0.68 / 0.72 / 0.78 / 0.92 / 1.02 / 1.05
/ 1.08 / 1.15 / 1.2 / 1.25 / 1.35 / 1.55 / 1.7 / 1.85 / 2 / 2.55 / 2.85 rem).
Rather than replicate every literal value (which would bake in
inconsistency), collapse into a real named scale for Flutter's `TextTheme`,
preserving the two intentional "hero" outliers:

| Style name | Size | Weight | Line-height | Letter-spacing | Used for |
|---|---|---|---|---|---|
| `display` | 2.85rem (~45.6px) / 2.55rem (~40.8px) responsive-by-context | 700 | 0.92 | -0.05em | Auth/Onboarding hero headline only (two sizes, context-dependent — Auth uses the larger, Onboarding the smaller) |
| `headlineLarge` | 2rem (32px) | 700 | 1.05 | -0.045em | Full-screen note title (detail/editor) |
| `headline` | 1.85rem (~29.6px) | 700 | 1.05 | -0.04em | Section headings: Today, Plan, Notebooks page titles |
| `title` | 1.55–1.7rem (~25–27px) | 700 | 1.05 | -0.04em | App header title, Account name heading |
| `subtitle` | 1.15–1.35rem (~18–21.6px) | 700 | default | -0.03em | Dashboard tile headings, card section subheads |
| `cardTitle` | 1.05rem (~16.8px) | 700 | snug | -0.02em | Note-card title, notebook title, add-menu item label |
| `body` | 1.02–1.08rem (~16.3–17.3px) | 400 | 1.55–1.7 (relaxed) | normal | Editor body, note detail body, auth/onboarding subcopy |
| `bodyCompact` | 0.92rem (~14.7px) | 400 | 1.55 | normal | Note-card prose preview |
| `label` | 0.78rem (~12.5px) | 500 | default | normal | Field labels, timestamps, hints — the single most-repeated caption size |
| `eyebrow` | 0.65–0.72rem (~10.4–11.5px) | 500 | default | 0.12–0.18em, uppercase | Section eyebrow labels (SEARCH, RECENT, etc.) |
| `button` | 1rem (Tailwind `text-base`) or 0.875rem (`text-sm`) | 600–700 | default | normal | Pill CTA buttons |
| `tabLabel` | 0.68rem (~10.9px) | 500 | default | normal | Bottom dock tab labels |

## 3. Spacing scale

No custom spacing tokens exist — the app uses Tailwind's default 4px-based
scale via arbitrary/standard utilities. In practice, a small set of values
account for nearly all spacing:

- **Base unit: 4px** (Tailwind default).
- Common steps in use: `0.5rem` (8px), `0.75rem` (12px), `1rem` (16px),
  `1.25rem` (20px) — these four cover the large majority of gaps/padding.
- Card/sheet internal padding: `1.15rem` (~18.4px, note cards), `1rem`/`1.25rem`
  (16/20px, most other cards, dashboard tiles, sheets).
- Page horizontal padding: `1rem` (16px) universally for board/list screens;
  `1.25rem` (20px) for card/detail interiors and quick-capture sheet.
- Gaps: `0.5rem` (chip rows, form rows) and `0.75rem` (icon+text rows,
  dashboard grids) dominate; `0.375rem` for icon-label micro rows.
- **Control heights (tap targets):** 44px (`min-h-11`, icon buttons/secondary
  buttons — the accessible minimum), 48px (`min-h-12`, most pill
  inputs/buttons), 56px (`min-h-14`, primary CTA inputs/buttons on Auth/Onboarding).
- Bottom safe-area padding is always `max(<base>, env(safe-area-inset-bottom))`.

**Recommend for Flutter:** a spacing scale of `4 / 8 / 12 / 16 / 20 / 24 / 32`
(logical pixels) mapped to named tokens (`xs/sm/md/lg/xl/xxl/xxxl`), which
covers everything observed above without introducing new magic numbers.

## 4. Border radius scale

| Radius | Px (approx, 1rem=16px) | Used for |
|---|---|---|
| Pill (`rounded-full`) | — | All buttons, chips, dock bar, most text inputs |
| 16px (`rounded-2xl`) | 16px | OTP boxes, compact popovers/menus, search-hit rows |
| 22px | 22px | Reminder-due banner, attachment thumbnails |
| 24px | 24px | Onboarding skin-swatch buttons, link-note popover |
| 26px | 26px | Notebook cards, dashboard notebook tiles |
| **28px = `--radius-card`** | 28px | Note cards, bottom sheets, habit board panel, agenda cards — the dominant "card" radius |
| 32px | 32px | Auth/Onboarding hero form panel only — reserved for the two biggest cards in the app |

Clear implicit hierarchy: **pill** for interactive controls → **16–26px**
for compact surfaces → **28px** as the standard card/sheet radius → **32px**
reserved exclusively for the two auth/onboarding hero panels. Use this
5-step scale as Flutter's `BorderRadius` tokens.

## 5. Shadows / elevation

| Token/value | Used for |
|---|---|
| `--shadow-card` (per-skin, see §1 table; **`none` in classic light**) | Note cards, toasts, reminder banner, quick-capture sheet — the general "elevated surface" shadow |
| `0 10px 24px rgba(26,24,20,0.28)` | Standalone FAB (orphaned component, not ported — see feature audit) |
| `0 4px 12px rgba(0,178,89,0.45)` | Success-tick circle glow (accent-colored) |
| `0 10px 28px rgba(48,36,24,0.14)` | Note-card context-menu popover |
| `drop-shadow(0 18px 36px rgba(26,24,20,.32))` | Add-menu sheet wrapper |
| `drop-shadow(0 8px 10px rgba(43,38,31,.1))` light / `rgba(0,0,0,.28)` dark | Every decorative sticker |

**Important, deliberate detail:** in **classic light mode, cards have no
shadow at all** (`--shadow-card: none`) — a flat "paper cutout" look.
Monsoon/Festival/dark variants do add a real elevation shadow. Don't
default to always-on card elevation in Flutter — make it theme-driven.

## 6. Iconography

Library: **Lucide** (`lucide-react` in the source; use `lucide_icons` or
hand-port the ~35-icon subset as an `IconData` set in Flutter — full list
below is exactly what's needed, no more).

**Full icon inventory used:** ArrowUpRight, Archive, Bell, Bookmark,
BookMarked, CalendarDays, Check, CheckCircle2, ChevronDown, ChevronRight,
Clock, Columns2, Copy, Download, Eye, FileJson, ImagePlus, Info,
LayoutGrid, Lightbulb, Link2, ListChecks, Mic, Moon, Notebook, NotebookPen,
Paperclip, Pencil, Pin, Plus, RotateCcw, Search, Shield, Sun, SunMedium,
Trash2, UserRound, UsersRound, X.

**Sizing convention:** 13–16px for inline/caption icons, **18px** as the
dominant "row icon" size (settings rows, tool chips), 20–22px for bottom-nav
tabs and the dock plus-button, 26px for the one-off standalone FAB (not ported).

**Stroke-width convention:** default `1.7`–`1.8`; bumped to `2.2`–`2.3` for
**active/emphasized** states — e.g. the bottom-dock tab icon literally gets
a heavier stroke when its tab is active (not just a color change). Replicate
this in Flutter's icon theme rather than relying on color alone.

## 7. Component patterns

### Buttons
- **Primary CTA pill**: full-width, `min-height 48–56px`, `rounded-full`,
  solid dark fill (`#1a1814`), white bold/semibold text, `disabled:
  opacity 0.5`. **No pressed-state animation in the source** — recommend
  adding a `scale(0.96)`-on-press affordance in Flutter for better tactile
  feedback (this is a real gap, tracked in `docs/ux-suggestions.md`).
- **Icon button**: 44×44px circle, `hover: bg-black/5` (light) /
  `white/10` (dark), `active: scale(0.95)`, 200ms ease-out transition — the
  one button variant with a fully specified interaction triad; use this as
  the reference for all pressed-states in Flutter, including primary buttons.
- **Secondary/ghost (text-only)**: no background, `text-sm font-medium`,
  ink color at 65% opacity. No pressed feedback in source (same gap as above).
- **Tool chip (toggle pill)**: inactive = translucent white background;
  active = solid dark fill + white text. Binary on/off via full background
  swap.
- **Danger (destructive) row/button**: text colored `#7a2418`, otherwise
  same pill/row treatment as a normal item — no distinct background.

### Inputs
- **Text fields** (email, name, tag, rename, label): pill-shaped,
  `min-height 44–56px`, `rounded-full`, translucent white background
  (`white/70–80`), placeholder at ~40% ink opacity, **no visible focus ring
  in the source** (gap, see ux-suggestions).
- **OTP boxes**: the one exception — 6 individual 56×44px rounded-2xl boxes,
  `ring-1 ring-black/5` default, `focus: ring-2 ring-ink`. Auto-advance on
  type/backspace; paste splits across boxes.
- **Textareas** (note body, quick capture): fully transparent, no
  border/background — blend into the surrounding card/sheet ("paper" feel).
- **Select** (notebook picker): same pill treatment as text inputs; native
  platform picker chrome for the dropdown itself in the original (Flutter
  should use its own native-feeling picker, e.g. a bottom sheet list).

### Cards
- **Note card**: background = note's own color (7-swatch palette, §1), 28px
  radius, ~18.4px padding, **no rotation/tilt**, **no shadow in classic
  light mode**. Entrance: fade + 8px slide up, 220ms, staggered by
  `index × 30ms` (capped at 8 items / 240ms max).
- **Notebook cards / dashboard tiles**: DO get alternating rotation for a
  "scattered photos" effect — repeating every 4 items:
  index%4==1 → `-1.4deg`, index%4==2 → `+1.1deg`, others → `0deg`.
- **"Washi tape" signature motif**: nearly every primary colored panel
  (auth form, onboarding form, notebook composer, habit board, featured
  dashboard card, note detail/editor header) gets one strip of decorative
  tape near its top edge, fixed at `-11deg` tilt. **This is a strong,
  consistent brand signature — replicate exactly**, e.g. as a small
  positioned image/custom-painted widget reused across those specific screens.

### Bottom sheets / modals
- **Standard sheet** (quick capture, save-as-template): `rgba(0,0,0,0.25)`
  flat backdrop (no blur, no fade on the backdrop itself), content slides up
  260ms (translateY 18%→0, ease-out), `rounded-top-28px` full-bleed on
  phone width.
- **Add-action menu** (from the dock's + button): the sheet is **visually
  connected to the dock's FAB via a radial mask/notch cutout** — a distinct
  and important detail, not a generic sheet. Backdrop dims via a 220ms
  fade (`rgba(26,24,20,0.42)`); the + icon itself rotates 45° into an X;
  each menu row fades/slides in staggered by `32ms × index`.
- **Search overlay**: full-screen, opaque (same paper background, no
  backdrop dimming needed), fades up in 200ms.
- **Note detail / editor**: full-screen overlays — **currently no
  enter/exit transition at all** in the source (instant mount/unmount).
  Recommend giving these a consistent transition in Flutter (reuse the
  sheet-up or a scale/fade) rather than replicating the abrupt cut — logged
  in ux-suggestions as an inconsistency, not a deliberate choice.

### Navigation — bottom dock (the app's most distinctive UI element)
A single pill-shaped dark bar (`#1a1814` light / `#0e0c0a` dark, height
~67px) holds 4 tabs (Notes, Books | Plan, You) split left/right around an
empty center slot (~72.8px wide). A separate circular "bump" (same dark
color, ~67px diameter) sits lifted above the bar's top edge by ~9.9px,
containing the actual white circular **+** button (~49.6px diameter) —
together this reads as one continuous dock with the FAB growing out of its
center notch. Below the whole dock, a small dark pill (134×5px) mimics an
iOS home-indicator bar (purely decorative).

- Tab item: 48px min-height, `rounded-2xl`, `0.68rem` label; **active** =
  white text + heavier icon stroke (2.3 vs 1.7); **inactive** = 55%-opacity
  white text. The Plan tab gets a small pink 8px dot badge when agenda items
  are overdue/due today.
- The + button flips to pink (`#e7a3a3`) and rotates 45° when the Add menu
  is open.
- Long-press (480ms) or right-click/secondary-tap on the + jumps straight
  into quick-capture, bypassing the Add menu.

**Build this in Flutter as one custom-painted/composited bottom-bar widget**
(a `Stack` with a `CustomPainter` or clipped shapes for the bar+bump+notch),
not a stock `BottomNavigationBar` — the notch/bump geometry is too specific
to approximate with standard widgets alone.

### Loading & empty states
- **Loading**: plain static centered text ("Opening notes…"), **no
  spinner/skeleton at all**. Recommend adding a subtle progress indicator in
  Flutter (see ux-suggestions) rather than replicating a state with no
  liveness feedback — but keep the calm, minimal tone (no full-screen
  spinner overlay).
- **Empty state**: centered column, one large emoji glyph (🗑️ trash, ⏰
  due, ✎ default) at ~48px, muted title text, optional primary pill CTA.
  Simple — no illustration/SVG needed for parity, just emoji + text + button.

### Decorative stickers
Hand-drawn inline SVGs, no gradients anywhere (multi-tone ones just layer
2–3 flat shapes): Star, Spark, Flower (2-tone), Heart, Sun (2-tone), Moon,
Smile (3-tone), Blob, Squiggle (stroke-only, used as an underline accent),
Tape ("washi tape", semi-transparent yellow + white highlight streak),
Clover (2-tone). Sizes 24–70px, rotation range **±20°** (specific per
instance via a `tilt` parameter), each with a continuous idle float
animation (see §8) staggered so multiple stickers on one screen don't move
in sync. **Recreate as a small set of custom-painted widgets or bundled SVG
assets** — precise path shapes aren't critical to get pixel-identical, but
the silhouette, flat-color-only look, tilt range, and floating motion are
core to the brand and should be replicated faithfully.

## 8. Motion

| Trigger | Behavior | Duration/easing |
|---|---|---|
| Note card mounts | Fade + 8px slide up, staggered `index×30ms` (max 8) | 220ms, app ease-out `cubic-bezier(0.22,1,0.36,1)` |
| Generic surface mounts (toast, empty state, search overlay, account panel) | Fade + 8px slide up | 200ms, ease-out |
| Bottom sheet opens | Slide up `translateY(18%→0)` | 260ms, ease-out |
| Add-menu opens | Backdrop fade 220ms + sheet slide 280ms + rows stagger 32ms/row + + icon rotates 45° | mixed, ease-out |
| Task checked complete | Filled circle pops in (scale 0→1.12→0.96→1) + two staggered expanding ripple rings (2nd delayed 180ms) + checkmark stroke draws in, **plus a haptic tick fired the same moment** | circle 500ms, ripple 1.1s, check 350ms (starts 280ms in) |
| Sticker idle | Continuous gentle vertical bob (±5px) | 5.6s loop, ease-in-out, infinite, per-sticker delay offset |
| Icon-button / FAB press | Scale down to 0.92–0.95 | 180–200ms, ease-out |
| Long-press (note card, dock write button, template chip) | 480–550ms hold timer → opens context menu / quick-capture / delete | n/a (timer-based, not eased) |
| Tab switch, note detail/editor open | **No transition — instant swap** in the source | — (recommend adding one in Flutter, see ux-suggestions) |
| Reduced-motion preference | All animations/transitions collapse to ~0 | Respect `MediaQuery.disableAnimations` equivalent in Flutter |

**No animation library was used in the source** (confirmed zero
framer-motion/react-spring/dnd-kit/etc. in `package.json`) — everything is
hand-rolled CSS keyframes. In Flutter, implement these with the standard
`AnimationController`/`Tween`/implicit-animation widgets; nothing here
requires a heavyweight animation package.

## 9. Cross-reference

See `docs/feature-audit.md` for screen/feature status and
`docs/ux-suggestions.md` for the running list of design issues observed
during this extraction (do not fix without separate approval, per the
porting brief).
