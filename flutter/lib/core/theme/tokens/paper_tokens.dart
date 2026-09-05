import 'package:flutter/material.dart';

/// Tokens that neither [ColorScheme] nor Material's built-in elevation model
/// has a slot for, per `docs/design-system.md` §1 and §5.
@immutable
class const PaperTokens({
  /// Opacity of the full-screen paper-grain texture overlay
  /// (`body::before` in the source): 0.14 light / 0.11 dark, every skin.
  required final double grainOpacity,

  /// The general "elevated surface" shadow for note cards, toasts, the
  /// reminder banner, and the quick-capture sheet. **Empty in classic
  /// light mode** — a deliberate flat "paper cutout" look; do not default
  /// to always-on elevation.
  ///
  /// The source's shadows also carry a 1px inset highlight
  /// (`0 1px 0 rgba(...) inset`) that [BoxShadow] cannot express; that
  /// highlight is a candidate for a thin top border on the card widget
  /// itself once note cards are actually built, not reproduced here.
  required final List<BoxShadow> cardShadow,

  /// Semi-transparent yellow fill for the "washi tape" brand motif.
  required final Color washiTapeColor,

  /// White highlight streak layered over [washiTapeColor].
  required final Color washiTapeHighlight,
}) extends ThemeExtension<PaperTokens> {
  @override
  PaperTokens copyWith({
    double? grainOpacity,
    List<BoxShadow>? cardShadow,
    Color? washiTapeColor,
    Color? washiTapeHighlight,
  }) {
    return PaperTokens(
      grainOpacity: grainOpacity ?? this.grainOpacity,
      cardShadow: cardShadow ?? this.cardShadow,
      washiTapeColor: washiTapeColor ?? this.washiTapeColor,
      washiTapeHighlight: washiTapeHighlight ?? this.washiTapeHighlight,
    );
  }

  @override
  PaperTokens lerp(ThemeExtension<PaperTokens>? other, double t) {
    if (other is! PaperTokens) return this;
    return PaperTokens(
      grainOpacity:
          grainOpacity + (other.grainOpacity - grainOpacity) * t,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      washiTapeColor:
          Color.lerp(washiTapeColor, other.washiTapeColor, t) ??
              washiTapeColor,
      washiTapeHighlight:
          Color.lerp(washiTapeHighlight, other.washiTapeHighlight, t) ??
              washiTapeHighlight,
    );
  }
}
