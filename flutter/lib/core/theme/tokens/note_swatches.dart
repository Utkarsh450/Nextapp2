import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/utils/hex_color.dart';

/// The 7-color note/notebook palette from `docs/design-system.md` §1
/// (`lib/notes/types.ts` `NOTE_COLORS`, reused as `NOTEBOOK_COVERS`).
///
/// This palette is independent of the active [PaperSkin] — a note's `color`
/// field always resolves through here, never through the paper palette.
class const NoteSwatches({required final bool isDark})
    extends ThemeExtension<NoteSwatches> {
  /// The 7 preset hex values, in source order — this is the form a
  /// `Note.color`/`Notebook.color` field is actually stored and compared
  /// as (`lib/notes/types.ts` `NOTE_COLORS`). Prefer [colors] for painting;
  /// use this when you need the raw stored value, e.g. `labelTint`'s
  /// deterministic hashing.
  static const List<String> paletteHex = [
    '#C5CA8A', // olive
    '#E7A3A3', // dusty pink
    '#BEC3BC', // sage grey
    '#E89569', // terracotta
    '#E8C44A', // gold
    '#D4C4E8', // lavender
    '#A9D4C4', // mint
  ];

  static final List<Color> _base = paletteHex.map(colorFromHex).toList();

  static final Color _darkMixTarget = colorFromHex('#1c1814');

  /// All 7 preset colors, already adjusted for the current brightness.
  List<Color> get colors => _base.map(resolve).toList(growable: false);

  /// Resolves a stored note/notebook `color` hex for display, applying the
  /// dark-mode 62%/38% mix with `#1c1814` the source does via
  /// `color-mix(in srgb, var(--card) 62%, #1c1814)` — approximated here as
  /// a linear ARGB lerp, which is visually equivalent for flat colors.
  Color resolve(Color stored) {
    if (!isDark) return stored;
    return Color.lerp(stored, _darkMixTarget, 0.38) ?? stored;
  }

  /// Resolves a stored hex string directly.
  Color resolveHex(String hex) => resolve(colorFromHex(hex));

  @override
  NoteSwatches copyWith({bool? isDark}) =>
      NoteSwatches(isDark: isDark ?? this.isDark);

  @override
  NoteSwatches lerp(ThemeExtension<NoteSwatches>? other, double t) {
    if (other is! NoteSwatches) return this;
    return t < 0.5 ? this : other;
  }
}
