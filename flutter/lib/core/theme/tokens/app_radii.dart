import 'package:flutter/material.dart';

/// The border-radius scale from `docs/design-system.md` §4.
///
/// `pill` is expressed as a very large radius rather than
/// [BorderRadius.circular] with `double.infinity`, since Flutter clamps
/// pill shapes correctly off of the shorter side either way — using a
/// concrete large value keeps [lerp] well-defined during theme animation.
@immutable
class const AppRadii({
  /// Buttons, chips, dock bar, most text inputs.
  final double pill = 999,

  /// 16px — OTP boxes, compact popovers/menus, search-hit rows.
  final double compact = 16,

  /// 22px — reminder-due banner, attachment thumbnails.
  final double banner = 22,

  /// 24px — onboarding skin-swatch buttons, link-note popover.
  final double swatch = 24,

  /// 26px — notebook cards, dashboard notebook tiles.
  final double notebook = 26,

  /// 28px — the dominant "card" radius: note cards, sheets, habit panel.
  final double card = 28,

  /// 32px — reserved exclusively for the auth/onboarding hero panels.
  final double hero = 32,
}) extends ThemeExtension<AppRadii> {
  BorderRadius get pillRadius => BorderRadius.circular(pill);
  BorderRadius get compactRadius => BorderRadius.circular(compact);
  BorderRadius get bannerRadius => BorderRadius.circular(banner);
  BorderRadius get swatchRadius => BorderRadius.circular(swatch);
  BorderRadius get notebookRadius => BorderRadius.circular(notebook);
  BorderRadius get cardRadius => BorderRadius.circular(card);
  BorderRadius get heroRadius => BorderRadius.circular(hero);

  @override
  AppRadii copyWith({
    double? pill,
    double? compact,
    double? banner,
    double? swatch,
    double? notebook,
    double? card,
    double? hero,
  }) {
    return AppRadii(
      pill: pill ?? this.pill,
      compact: compact ?? this.compact,
      banner: banner ?? this.banner,
      swatch: swatch ?? this.swatch,
      notebook: notebook ?? this.notebook,
      card: card ?? this.card,
      hero: hero ?? this.hero,
    );
  }

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      pill: _lerpD(pill, other.pill, t),
      compact: _lerpD(compact, other.compact, t),
      banner: _lerpD(banner, other.banner, t),
      swatch: _lerpD(swatch, other.swatch, t),
      notebook: _lerpD(notebook, other.notebook, t),
      card: _lerpD(card, other.card, t),
      hero: _lerpD(hero, other.hero, t),
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}
