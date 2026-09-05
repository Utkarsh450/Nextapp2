import 'package:notes_app/core/theme/tokens/note_swatches.dart';

/// The editor's quick-add label chips — matches `LABEL_PRESETS`.
const List<String> labelPresets = [
  'Work',
  'Personal',
  'Ideas',
  'Tasks',
  'Home',
  'Today',
];

/// Deterministic color hashing per label — matches `labelTint` in
/// `lib/notes/labels.ts`, reusing the same 7-swatch palette as note cards.
String labelTint(String label) {
  final sum = label.runes.fold<int>(0, (acc, ch) => acc + ch);
  const palette = NoteSwatches.paletteHex;
  return palette[sum % palette.length];
}
