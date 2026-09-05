import 'package:flutter/material.dart';

/// The 4px-based spacing scale reverse-engineered in
/// `docs/design-system.md` §3. Every layout gap/padding in the app should
/// reference one of these named steps instead of a literal number.
@immutable
class const AppSpacing({
  /// 4px — icon-label micro rows.
  final double xs = 4,

  /// 8px — chip rows, form row gaps.
  final double sm = 8,

  /// 12px — icon+text rows, dashboard grid gaps.
  final double md = 12,

  /// 16px — universal board/list horizontal padding; most common step.
  final double lg = 16,

  /// 20px — card/detail interior padding, quick-capture sheet padding.
  final double xl = 20,

  /// 24px — section spacing.
  final double xxl = 24,

  /// 32px — hero panel spacing (auth/onboarding).
  final double xxxl = 32,
}) extends ThemeExtension<AppSpacing> {
  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: _lerpD(xs, other.xs, t),
      sm: _lerpD(sm, other.sm, t),
      md: _lerpD(md, other.md, t),
      lg: _lerpD(lg, other.lg, t),
      xl: _lerpD(xl, other.xl, t),
      xxl: _lerpD(xxl, other.xxl, t),
      xxxl: _lerpD(xxxl, other.xxxl, t),
    );
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;
}
