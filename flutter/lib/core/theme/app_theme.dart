import 'package:flutter/material.dart';

import 'package:notes_app/core/theme/app_text_theme.dart';
import 'package:notes_app/core/theme/paper_palette.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/tokens/app_motion.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/core/theme/tokens/paper_tokens.dart';

/// Builds the full [ThemeData] for one skin × brightness combination.
///
/// This is the single place the design system (`docs/design-system.md`)
/// becomes Flutter theme data — screens must read colors/type/spacing off
/// `Theme.of(context)` and its extensions, never hardcode a literal.
ThemeData buildAppTheme({
  required PaperSkin skin,
  required Brightness brightness,
}) {
  final palette = paperPaletteFor(skin, brightness);
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: palette.shellFill,
          onPrimary: Colors.white,
          secondary: palette.accent,
          onSecondary: Colors.white,
          surface: palette.paper,
          onSurface: palette.ink,
          error: PaperPalette.danger,
          onError: Colors.white,
        )
      : ColorScheme.light(
          primary: palette.shellFill,
          secondary: palette.accent,
          onSecondary: Colors.white,
          surface: palette.paper,
          onSurface: palette.ink,
          error: PaperPalette.danger,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.paper,
    canvasColor: palette.paper,
    textTheme: buildAppTextTheme(palette.ink),
    dividerColor: palette.muted.withValues(alpha: 0.2),
    splashFactory: InkRipple.splashFactory,
    extensions: [
      const AppSpacing(),
      const AppRadii(),
      const AppMotion(),
      NoteSwatches(isDark: isDark),
      buildAppTextStyles(palette.ink),
      PaperTokens(
        grainOpacity: palette.grainOpacity,
        cardShadow: palette.cardShadow,
        // Exact washi-tape hex wasn't captured during Phase 2 extraction
        // (the source describes it as "semi-transparent yellow + white
        // highlight streak" without a literal). Approximated here; revisit
        // against the real SVG when the Tape sticker widget is built.
        washiTapeColor: const Color(0xB3E8C44A),
        washiTapeHighlight: Colors.white.withValues(alpha: 0.55),
      ),
    ],
  );
}
