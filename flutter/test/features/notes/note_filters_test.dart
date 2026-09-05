import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';

Note _note({
  required int id,
  bool pinned = false,
  bool archived = false,
  bool confirmed = false,
  int? trashedAt,
  String? dueAt,
  String color = '#C5CA8A',
  List<String> labels = const [],
  int order = 0,
  int createdAt = 0,
}) {
  return Note(
    id: id,
    ownerEmail: 'you@notes.dev',
    createdAt: createdAt,
    updatedAt: createdAt,
    color: color,
    pinned: pinned,
    archived: archived,
    confirmed: confirmed,
    trashedAt: trashedAt,
    dueAt: dueAt,
    labels: labels,
    order: order,
  );
}

void main() {
  group('visibleNotes', () {
    test('all filter excludes archived and trashed notes', () {
      final notes = [
        _note(id: 1),
        _note(id: 2, archived: true),
        _note(id: 3, trashedAt: 100),
      ];
      final shown = visibleNotes(notes: notes);
      expect(shown.map((n) => n.id), [1]);
    });

    test('trash filter shows only trashed notes', () {
      final notes = [_note(id: 1), _note(id: 2, trashedAt: 100)];
      final shown = visibleNotes(notes: notes, filterKey: NoteFilter.trash);
      expect(shown.map((n) => n.id), [2]);
    });

    test('open/done filters split on confirmed', () {
      final notes = [
        _note(id: 1),
        _note(id: 2, confirmed: true),
      ];
      expect(
        visibleNotes(notes: notes, filterKey: NoteFilter.open).map((n) => n.id),
        [1],
      );
      expect(
        visibleNotes(notes: notes, filterKey: NoteFilter.done).map((n) => n.id),
        [2],
      );
    });

    test('due filter matches today or overdue, not future', () {
      final notes = [
        _note(id: 1, dueAt: '2024-01-01'),
        _note(id: 2, dueAt: '2024-01-02'),
        _note(id: 3, dueAt: '2024-01-03'),
      ];
      final shown = visibleNotes(
        notes: notes,
        filterKey: NoteFilter.due,
        today: '2024-01-02',
      );
      expect(shown.map((n) => n.id).toSet(), {1, 2});
    });

    test('pinned notes sort first regardless of sort key, except in trash', () {
      final notes = [
        _note(id: 1),
        _note(id: 2, order: 1, pinned: true),
      ];
      expect(visibleNotes(notes: notes).first.id, 2);

      final trashed = [
        _note(id: 3, trashedAt: 1, pinned: true, order: 5),
        _note(id: 4, trashedAt: 1),
      ];
      final shownTrash = visibleNotes(
        notes: trashed,
        filterKey: NoteFilter.trash,
      );
      // Pin is ignored in trash — falls back to `order` for the newest sort.
      expect(shownTrash.first.id, 4);
    });

    test('color and label filters narrow the result', () {
      final notes = [
        _note(id: 1, labels: const ['Work']),
        _note(id: 2, color: '#E7A3A3', labels: const ['Home']),
      ];
      expect(
        visibleNotes(notes: notes, color: '#E7A3A3').map((n) => n.id),
        [2],
      );
      expect(
        visibleNotes(notes: notes, label: 'Work').map((n) => n.id),
        [1],
      );
    });
  });

  group('moveNote', () {
    test('reorders and rewrites the order field', () {
      final notes = [_note(id: 1), _note(id: 2), _note(id: 3)];
      final moved = moveNote(notes, 1, 3);
      expect(moved.map((n) => n.id), [2, 3, 1]);
      expect(moved.map((n) => n.order), [0, 1, 2]);
    });

    test('is a no-op for unknown ids', () {
      final notes = [_note(id: 1), _note(id: 2)];
      expect(moveNote(notes, 99, 1), same(notes));
    });
  });

  group('trashNote / restoreFromTrash', () {
    test('trashing unpins and stamps trashedAt', () {
      final note = _note(id: 1, pinned: true);
      final trashed = trashNote(note, 500);
      expect(trashed.trashedAt, 500);
      expect(trashed.pinned, isFalse);
      expect(trashed.updatedAt, 500);
    });

    test('restoring clears trashedAt without reviving pinned state', () {
      final note = _note(id: 1, trashedAt: 500);
      final restored = restoreFromTrash(note, 900);
      expect(restored.trashedAt, isNull);
      expect(restored.updatedAt, 900);
    });
  });
}
