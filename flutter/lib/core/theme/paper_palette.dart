import 'package:flutter/material.dart';

import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/utils/hex_color.dart';

/// One resolved skin × brightness color combination, transcribed verbatim
/// from `docs/design-system.md` §1 (which was itself extracted from
/// `app/globals.css`'s CSS custom properties). Every hex value here must
/// trace back to that table — don't hand-tune for taste.
@immutable
class const PaperPalette({
  /// `--paper` — background/surface.
  required final Color paper,

  /// `--ink` — text-primary.
  required final Color ink,

  /// `--muted` — text-secondary.
  required final Color muted,

  /// `--accent` — success/primary-accent.
  required final Color accent,

  /// `--shadow-card`, converted from the CSS `box-shadow` value's outer
  /// component (the inset highlight isn't representable via [BoxShadow];
  /// see `PaperTokens.cardShadow` doc comment). Empty in classic light.
  required final List<BoxShadow> cardShadow,

  /// `--grain-opacity`.
  required final double grainOpacity,

  /// Fixed near-black fill used for the primary CTA pill and the bottom
  /// dock bar (`#1a1814` light / `#0e0c0a` dark) — **skin-independent**,
  /// per `docs/design-system.md` §7 ("Navigation — bottom dock").
  required final Color shellFill,
}) {
  /// `#7a2418` — form errors and destructive-row text. Not tokenized as a
  /// CSS variable in the source (always this literal), so it's a static
  /// constant here too rather than per-skin.
  static final Color danger = colorFromHex('#7a2418');
}

const _noShadow = <BoxShadow>[];

final Color _shellLight = colorFromHex('#1a1814');
final Color _shellDark = colorFromHex('#0e0c0a');

List<BoxShadow> _shadow(Color color, double opacity, double dy, double blur) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      offset: Offset(0, dy),
      blurRadius: blur,
    ),
  ];
}

final Map<(PaperSkin, Brightness), PaperPalette> _palettes = {
  (PaperSkin.classic, Brightness.light): PaperPalette(
    paper: colorFromHex('#f4e8dc'),
    ink: colorFromHex('#2b261f'),
    muted: colorFromHex('#6b6158'),
    accent: colorFromHex('#00b259'),
    cardShadow: _noShadow,
    grainOpacity: 0.14,
    shellFill: _shellLight,
  ),
  (PaperSkin.classic, Brightness.dark): PaperPalette(
    paper: colorFromHex('#161410'),
    ink: colorFromHex('#efe8dc'),
    muted: colorFromHex('#9a9288'),
    accent: colorFromHex('#3dcf7a'),
    cardShadow: _shadow(const Color(0xFF000000), 0.5, 14, 36),
    grainOpacity: 0.11,
    shellFill: _shellDark,
  ),
  (PaperSkin.monsoon, Brightness.light): PaperPalette(
    paper: colorFromHex('#e4eee8'),
    ink: colorFromHex('#1a2c24'),
    muted: colorFromHex('#5d7268'),
    accent: colorFromHex('#2f8f6b'),
    cardShadow: _shadow(colorFromHex('#182820'), 0.1, 10, 28),
    grainOpacity: 0.14,
    shellFill: _shellLight,
  ),
  (PaperSkin.monsoon, Brightness.dark): PaperPalette(
    paper: colorFromHex('#101816'),
    ink: colorFromHex('#e6f0ea'),
    muted: colorFromHex('#8aa396'),
    accent: colorFromHex('#4cba8c'),
    cardShadow: _shadow(const Color(0xFF000000), 0.5, 14, 36),
    grainOpacity: 0.11,
    shellFill: _shellDark,
  ),
  (PaperSkin.festival, Brightness.light): PaperPalette(
    paper: colorFromHex('#f6ead2'),
    ink: colorFromHex('#3a2414'),
    muted: colorFromHex('#8a6a48'),
    accent: colorFromHex('#c8891a'),
    cardShadow: _shadow(colorFromHex('#503010'), 0.1, 10, 28),
    grainOpacity: 0.14,
    shellFill: _shellLight,
  ),
  (PaperSkin.festival, Brightness.dark): PaperPalette(
    paper: colorFromHex('#1a140c'),
    ink: colorFromHex('#f3e6c8'),
    muted: colorFromHex('#b49a72'),
    accent: colorFromHex('#e0b14a'),
    cardShadow: _shadow(const Color(0xFF000000), 0.55, 14, 36),
    grainOpacity: 0.11,
    shellFill: _shellDark,
  ),
};

/// Looks up the resolved palette for a skin × brightness combination.
PaperPalette paperPaletteFor(PaperSkin skin, Brightness brightness) {
  final palette = _palettes[(skin, brightness)];
  assert(palette != null, 'Missing palette for $skin / $brightness');
  return palette!;
}
