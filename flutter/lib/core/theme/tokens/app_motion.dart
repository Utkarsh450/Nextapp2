import 'package:flutter/material.dart';

/// Motion tokens from `docs/design-system.md` §8.
///
/// The source app hand-rolls every animation in CSS with one recurring
/// easing curve (`cubic-bezier(0.22, 1, 0.36, 1)`) and a small set of
/// durations. This extension is the single place those live in Flutter.
@immutable
class const AppMotion({
  /// The app-wide ease-out curve, `cubic-bezier(0.22, 1, 0.36, 1)`.
  final Curve easeOut = const Cubic(0.22, 1, 0.36, 1),

  /// Icon-button / FAB / primary-CTA press scale-down.
  final Duration press = const Duration(milliseconds: 190),

  /// Generic surface mount (toast, empty state, search overlay, account
  /// panel): fade + 8px slide up.
  final Duration surfaceEnter = const Duration(milliseconds: 200),

  /// Note card mount: fade + 8px slide up, staggered by [cardStagger].
  final Duration cardEnter = const Duration(milliseconds: 220),

  /// Bottom sheet slide-up (quick capture, save-as-template).
  final Duration sheetEnter = const Duration(milliseconds: 260),

  /// Add-menu sheet slide.
  final Duration addMenuSheet = const Duration(milliseconds: 280),

  /// Add-menu backdrop fade.
  final Duration addMenuBackdrop = const Duration(milliseconds: 220),

  /// Per-row stagger delay inside the Add-menu.
  final Duration rowStagger = const Duration(milliseconds: 32),

  /// Per-card stagger delay in the notes grid (capped at 8 items / 240ms).
  final Duration cardStagger = const Duration(milliseconds: 30),

  /// One full bob cycle of a decorative sticker's idle float.
  final Duration stickerFloat = const Duration(milliseconds: 5600),

  /// Hold duration before a long-press gesture fires (note card, dock
  /// write button, template chip — all 480–550ms in source; 500ms here).
  final Duration longPress = const Duration(milliseconds: 500),
}) extends ThemeExtension<AppMotion> {
  @override
  AppMotion copyWith({
    Curve? easeOut,
    Duration? press,
    Duration? surfaceEnter,
    Duration? cardEnter,
    Duration? sheetEnter,
    Duration? addMenuSheet,
    Duration? addMenuBackdrop,
    Duration? rowStagger,
    Duration? cardStagger,
    Duration? stickerFloat,
    Duration? longPress,
  }) {
    return AppMotion(
      easeOut: easeOut ?? this.easeOut,
      press: press ?? this.press,
      surfaceEnter: surfaceEnter ?? this.surfaceEnter,
      cardEnter: cardEnter ?? this.cardEnter,
      sheetEnter: sheetEnter ?? this.sheetEnter,
      addMenuSheet: addMenuSheet ?? this.addMenuSheet,
      addMenuBackdrop: addMenuBackdrop ?? this.addMenuBackdrop,
      rowStagger: rowStagger ?? this.rowStagger,
      cardStagger: cardStagger ?? this.cardStagger,
      stickerFloat: stickerFloat ?? this.stickerFloat,
      longPress: longPress ?? this.longPress,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    // Durations/curves don't benefit from interpolation mid-theme-switch;
    // snap at the midpoint like the rest of the app's discrete tokens.
    if (other is! AppMotion) return this;
    return t < 0.5 ? this : other;
  }
}
