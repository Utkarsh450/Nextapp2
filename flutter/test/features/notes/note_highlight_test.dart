import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note_highlight.dart';

void main() {
  test('an empty query returns the whole text unmatched', () {
    final segments = highlightSegments('Grocery run', '');
    expect(segments, hasLength(1));
    expect(segments.first.text, 'Grocery run');
    expect(segments.first.match, isFalse);
  });

  test('splits around a case-insensitive match', () {
    final segments = highlightSegments('Grocery run', 'ROCE');
    expect(segments.map((s) => s.text).toList(), ['G', 'roce', 'ry run']);
    expect(segments.map((s) => s.match).toList(), [false, true, false]);
  });

  test('marks every occurrence of the query', () {
    final segments = highlightSegments('ba na na', 'na');
    expect(segments.map((s) => s.text).toList(), ['ba ', 'na', ' ', 'na']);
    expect(segments.map((s) => s.match).toList(), [false, true, false, true]);
  });

  test('escapes regex-special characters in the query', () {
    final segments = highlightSegments('a (b) c', '(b)');
    expect(segments.map((s) => s.text).toList(), ['a ', '(b)', ' c']);
    expect(segments.map((s) => s.match).toList(), [false, true, false]);
  });
}
