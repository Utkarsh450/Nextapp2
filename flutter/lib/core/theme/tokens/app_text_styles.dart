import 'package:flutter/material.dart';

/// Named styles from `docs/design-system.md` §2 that have no slot in
/// Flutter's 11-style [TextTheme] — the uppercase/tracked "eyebrow" label
/// and the bottom-dock tab label get their own extension instead of
/// overloading an unrelated Material slot.
///
/// Everything else in the reverse-engineered type scale (display, headline,
/// title, subtitle, cardTitle, body, bodyCompact, label, button) maps onto
/// a standard [TextTheme] slot — see `app_text_theme.dart` for that mapping
/// and the rationale for each choice.
class const AppTextStyles({
  /// 0.7rem (~11.2px) / 500 / 0.15em tracking / uppercase.
  /// Section eyebrow labels (SEARCH, RECENT, etc.).
  required final TextStyle eyebrow,
}) extends ThemeExtension<AppTextStyles> {
  @override
  AppTextStyles copyWith({TextStyle? eyebrow}) =>
      AppTextStyles(eyebrow: eyebrow ?? this.eyebrow);

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t) ?? eyebrow,
    );
  }
}
