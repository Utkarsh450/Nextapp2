import 'package:flutter/material.dart';

import 'package:notes_app/core/theme/tokens/app_text_styles.dart';

/// Font family from `docs/design-system.md` §2. The source self-hosts
/// Satoshi only as `.woff2` (`app/fonts/Satoshi-*.woff2`), which Flutter
/// can't load directly — `assets/fonts/Satoshi-*.ttf` are the same files
/// decompressed to a container Flutter can (`fonttools ttLib.woff2
/// decompress`), registered in `pubspec.yaml`'s `fonts:` block.
const String _fontFamily = 'Satoshi';

/// `Arial, Helvetica, sans-serif` — the source's own fallback stack.
const List<String> _fontFallback = ['Arial', 'Helvetica', 'sans-serif'];

/// Builds the app's [TextTheme] from the rationalized scale in
/// `docs/design-system.md` §2, for the given [ink] (text-primary) color.
///
/// Mapping from the design doc's named styles onto Flutter's 11-slot
/// [TextTheme] (chosen so Material widgets that read a slot implicitly —
/// [NavigationBar] labels, button text — land on the right named style
/// without per-widget overrides):
///
/// | Design doc    | TextTheme slot   |
/// |----------------|------------------|
/// | display (auth) | displayLarge     |
/// | display (onboarding) | displayMedium |
/// | headlineLarge   | headlineLarge    |
/// | headline        | headlineMedium   |
/// | title           | headlineSmall    |
/// | subtitle        | titleLarge       |
/// | cardTitle       | titleMedium      |
/// | body            | bodyLarge        |
/// | bodyCompact     | bodyMedium       |
/// | button          | labelLarge       |
/// | label           | labelMedium      |
/// | tabLabel        | labelSmall       |
///
/// `displaySmall`, `titleSmall`, and `bodySmall` have no direct source-app
/// equivalent and are left at Flutter's base defaults.
TextTheme buildAppTextTheme(Color ink) {
  TextStyle style({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacingEm,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      color: ink,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacingEm == null ? null : letterSpacingEm * size,
    );
  }

  return TextTheme(
    displayLarge: style(
      size: 45.6,
      weight: FontWeight.w700,
      height: 0.92,
      letterSpacingEm: -0.05,
    ),
    displayMedium: style(
      size: 40.8,
      weight: FontWeight.w700,
      height: 0.92,
      letterSpacingEm: -0.05,
    ),
    headlineLarge: style(
      size: 32,
      weight: FontWeight.w700,
      height: 1.05,
      letterSpacingEm: -0.045,
    ),
    headlineMedium: style(
      size: 29.6,
      weight: FontWeight.w700,
      height: 1.05,
      letterSpacingEm: -0.04,
    ),
    headlineSmall: style(
      size: 26.4,
      weight: FontWeight.w700,
      height: 1.05,
      letterSpacingEm: -0.04,
    ),
    titleLarge: style(
      size: 20,
      weight: FontWeight.w700,
      letterSpacingEm: -0.03,
    ),
    titleMedium: style(
      size: 16.8,
      weight: FontWeight.w700,
      height: 1.3,
      letterSpacingEm: -0.02,
    ),
    bodyLarge: style(size: 16.8, weight: FontWeight.w400, height: 1.6),
    bodyMedium: style(size: 14.7, weight: FontWeight.w400, height: 1.55),
    labelLarge: style(size: 16, weight: FontWeight.w700),
    labelMedium: style(size: 12.5, weight: FontWeight.w500),
    labelSmall: style(size: 10.9, weight: FontWeight.w500),
  );
}

/// Builds the [AppTextStyles] extension (styles with no [TextTheme] slot).
AppTextStyles buildAppTextStyles(Color ink) {
  return AppTextStyles(
    eyebrow: TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      color: ink,
      fontSize: 11.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 11.2 * 0.15,
    ),
  );
}
