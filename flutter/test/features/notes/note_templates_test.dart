import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_templates.dart';

void main() {
  group('applyTemplate', () {
    test('non-daily templates keep their fixed title', () {
      final meeting = applyTemplate(TemplateKey.meeting);
      expect(meeting.title, 'Meeting notes');
      final idea = applyTemplate(TemplateKey.idea);
      expect(idea.title, 'New idea');
    });

    test("the daily template's title folds in today's date", () {
      final now = DateTime(2024, 3, 7);
      final daily = applyTemplate(TemplateKey.daily, now);
      expect(daily.title, 'Daily log · 2024-03-07');
    });
  });

  group('findDailyNote', () {
    Note note({required int id, required String title, int? trashedAt}) => Note(
      id: id,
      ownerEmail: 'you@notes.dev',
      createdAt: 0,
      updatedAt: 0,
      color: '#C5CA8A',
      title: title,
      trashedAt: trashedAt,
    );

    test("finds a live note titled with today's daily-log title", () {
      final now = DateTime(2024, 3, 7);
      final notes = [note(id: 1, title: 'Daily log · 2024-03-07')];
      expect(findDailyNote(notes, now)?.id, 1);
    });

    test('ignores a trashed note with a matching title', () {
      final now = DateTime(2024, 3, 7);
      final notes = [
        note(id: 1, title: 'Daily log · 2024-03-07', trashedAt: 5),
      ];
      expect(findDailyNote(notes, now), isNull);
    });

    test('returns null when no note matches', () {
      final now = DateTime(2024, 3, 7);
      expect(findDailyNote(const [], now), isNull);
    });
  });
}
