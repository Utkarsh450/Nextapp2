/// The three "paper skins" from `docs/design-system.md` §1.
///
/// Mirrors `lib/theme.ts`'s `PaperSkin` union
/// (`document.documentElement.dataset.skin`) in the source app.
enum PaperSkin {
  classic,
  monsoon,
  festival;

  /// Persisted pref value, matching the source's `data-skin` attribute
  /// values (`classic` is the implicit default / absent attribute there).
  String get prefValue => switch (this) {
        PaperSkin.classic => 'classic',
        PaperSkin.monsoon => 'monsoon',
        PaperSkin.festival => 'festival',
      };

  static PaperSkin fromPrefValue(String? value) => switch (value) {
        'monsoon' => PaperSkin.monsoon,
        'festival' => PaperSkin.festival,
        _ => PaperSkin.classic,
      };

  String get label => switch (this) {
        PaperSkin.classic => 'Classic',
        PaperSkin.monsoon => 'Monsoon',
        PaperSkin.festival => 'Festival',
      };
}
