import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

void main() {
  group('cardSurface', () {
    test('splits out tasks, bullets, and the rest as prose', () {
      final surface = cardSurface(
        'Intro line\n- [ ] one\n- [x] two\n- bullet a\n- bullet b\nOutro line',
      );

      expect(surface.shownTasks, hasLength(2));
      expect(surface.shownTasks[0].text, 'one');
      expect(surface.shownTasks[1].checked, isTrue);
      expect(surface.shownBullets, hasLength(2));
      expect(surface.prose, contains('Intro line'));
      expect(surface.prose, contains('Outro line'));
    });

    test('caps shown tasks and bullets at 6 each', () {
      final tasks = List.generate(9, (i) => '- [ ] task $i').join('\n');
      final surface = cardSurface(tasks);
      expect(surface.shownTasks, hasLength(6));
    });

    test('returns the same NoteCardSurface instance for repeated identical '
        'calls (memoized, so re-rendering an unchanged note card does not '
        're-parse its body)', () {
      const body = 'Same note body\n- [ ] a task';
      final first = cardSurface(body);
      final second = cardSurface(body);
      expect(identical(first, second), isTrue);
    });

    test('does not collide two different (body, fallbackPreview) pairs that '
        'would concatenate to the same string', () {
      final a = cardSurface('foo', 'bar baz');
      final b = cardSurface('foo bar', 'baz');
      expect(identical(a, b), isFalse);
    });

    test('falls back to fallbackPreview when the body is empty', () {
      final surface = cardSurface('', 'A short preview');
      expect(surface.prose, 'A short preview');
    });
  });
}
