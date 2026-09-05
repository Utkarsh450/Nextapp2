# UX Suggestions — Running List (Phase 2)

Logged during design-system extraction. These are opinions to review and
approve/reject later — **none of these are implemented**, and none should
block or alter the exact-clone work. Each entry: what's off, why, suggested fix.

For a genuine functional bug found in the source app (not a design opinion),
see `docs/feature-audit.md` §"Correctness bug" — `NoteCard.tsx`'s context
menu currently throws on every click due to an out-of-scope `setMenu`
reference. That's tracked separately since it needs a decision regardless of
design taste.

---

1. **Inconsistent screen-transition depth.** Bottom sheets (quick capture,
   Add-menu) and the search overlay all get a deliberate slide/fade-in, but
   the full-screen note detail/editor overlays and the four main tab
   switches (Notes/Books/Plan/You) render with **zero transition** — an
   abrupt cut that feels inconsistent against an otherwise carefully
   choreographed motion language.
   *Fix:* give full-screen note overlays a consistent enter animation
   (reuse the sheet-up or a scale/fade), and give tab switches at least a
   short cross-fade.

2. **No focus ring on almost all text inputs.** Only the 6 OTP boxes get a
   visible `focus:ring`; every other text input (email, name, notebook
   rename, label draft, tag, note title, editor body) relies solely on the
   native caret. Less critical on touch, but a real gap for
   keyboard/accessibility and general polish.
   *Fix:* add a consistent focus ring across all text inputs.

3. **No pressed-state feedback on primary CTA pill buttons** (Send code /
   Continue / Start writing / Save / Done), while `IconButton` and the FAB
   both define an explicit `active:scale-95`/`scale(.92)`. This makes
   tactile feedback inconsistent between button types.
   *Fix:* apply the same press-scale affordance to primary/secondary buttons.

4. **No loading spinner/skeleton** — just static "Opening notes…" text on
   the plain paper background. On a slow first read (cold IndexedDB, cold
   start) there's no sense of progress or liveness.
   *Fix:* a subtle pulsing dot or the app's own accent-colored ring (the
   `TodayBoard` circular-progress motif would be on-brand) rather than
   static text.

5. **`themeColor` meta mismatch.** `app/layout.tsx`'s dark-mode
   `viewport.themeColor` is `#121214`, but the real `.dark` paper background
   is `#161410` — the Android status bar tint won't match the app's actual
   background.
   *Fix:* use `#161410`.

6. **Possibly dead CSS: `.pin-fold`.** Defines a folded-corner "dog-ear"
   decoration in `globals.css`, but no component was found applying the
   class anywhere in `features/**`/`components/ui/**`. If genuinely unused,
   it's confusing leftover for anyone reverse-engineering the design system
   (a rebuild might mistakenly assume every card has a corner fold).
   *Fix:* confirm it's unused, then simply don't port it (no action needed
   beyond not replicating a fold that was never shipped).

7. **Color-only filter-chip selection state.** Selected color swatches in
   the filter bar only change via a thin `2px` ink outline — no shape/icon
   change, no `aria-pressed`. Some pastel swatches (e.g. the yellow
   `#E8C44A`) have fairly low contrast against the paper background, making
   the outline hard to see for colorblind or low-vision users.
   *Fix:* pair the selected state with a persistent check-glyph or a
   stronger/higher-contrast outline.

8. **Tap targets below 44px in a few spots.** Color-swatch buttons
   throughout (28–32px) are noticeably smaller than the 44–48px targets used
   elsewhere, despite being a frequent, precise action (color picking) on a
   touch phone screen.
   *Fix:* enlarge to at least 40–44px, or add generous hit-padding around
   the visual swatch in Flutter.

9. **Ad-hoc, unsystematic type scale.** Dozens of one-off rem values with no
   defined ramp (this isn't user-facing, but worth noting for the record —
   already handled by collapsing into a named scale in `docs/design-system.md`
   rather than replicating every literal value).
