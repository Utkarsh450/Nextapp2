import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notebooks/domain/notebook.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dashboard.dart';

Note _note({
  required int id,
  String body = '',
  bool pinned = false,
  bool confirmed = false,
  bool archived = false,
  int? trashedAt,
  String? dueAt,
  String notebookId = 'inbox',
  int updatedAt = 0,
}) => Note(
  id: id,
  ownerEmail: 'you@notes.dev',
  createdAt: 0,
  updatedAt: updatedAt,
  color: '#C5CA8A',
  body: body,
  pinned: pinned,
  confirmed: confirmed,
  archived: archived,
  trashedAt: trashedAt,
  dueAt: dueAt,
  notebookId: notebookId,
);

void main() {
  group('greetingForHour', () {
    test('morning, afternoon, evening buckets', () {
      expect(greetingForHour(8), 'Good morning');
      expect(greetingForHour(15), 'Good afternoon');
      expect(greetingForHour(21), 'Good evening');
    });
  });

  group('sparkPath', () {
    test('is empty for no values', () {
      expect(sparkPath(const []), '');
    });

    test('starts with M and traces the rest with L', () {
      final path = sparkPath([0, 2, 1]);
      expect(path, startsWith('M'));
      expect(path.split(' ').where((s) => s.startsWith('L')), hasLength(2));
    });
  });

  group('noteDashboard', () {
    test('archived/trashed notes are excluded from every aggregate', () {
      final notes = [
        _note(id: 1, confirmed: true),
        _note(id: 2, archived: true),
        _note(id: 3, trashedAt: 5),
      ];
      final dash = noteDashboard(notes, const [], today: '2024-01-10');
      expect(dash.live, 1);
      expect(dash.done, 1);
      expect(dash.open, 0);
    });

    test('percent uses task completion when tasks exist', () {
      final notes = [_note(id: 1, body: '- [x] a\n- [ ] b')];
      final dash = noteDashboard(notes, const [], today: '2024-01-10');
      expect(dash.tasksTotal, 2);
      expect(dash.tasksDone, 1);
      expect(dash.percent, 50);
    });

    test('percent falls back to done/live ratio with no tasks', () {
      final notes = [_note(id: 1, confirmed: true), _note(id: 2)];
      final dash = noteDashboard(notes, const [], today: '2024-01-10');
      expect(dash.percent, 50);
    });

    test('due includes overdue and due-today notes', () {
      final notes = [
        _note(id: 1, dueAt: '2024-01-09'),
        _note(id: 2, dueAt: '2024-01-10'),
        _note(id: 3, dueAt: '2024-01-11'),
      ];
      final dash = noteDashboard(notes, const [], today: '2024-01-10');
      expect(dash.due.map((n) => n.id), containsAll([1, 2]));
      expect(dash.due.map((n) => n.id), isNot(contains(3)));
    });

    test('featured prefers pinned, then due, then a checklist note', () {
      final due = _note(id: 1, dueAt: '2024-01-10');
      final pinned = _note(id: 2, pinned: true);
      final dash = noteDashboard(
        [due, pinned],
        const [],
        today: '2024-01-10',
      );
      expect(dash.featured?.id, 2);
    });

    test('notebook tiles carry live note counts by notebookId', () {
      final notes = [
        _note(id: 1, notebookId: 'work'),
        _note(id: 2, notebookId: 'work'),
        _note(id: 3, notebookId: 'home', archived: true),
      ];
      final notebooks = [
        const Notebook(
          id: 'work',
          ownerEmail: 'you@notes.dev',
          name: 'Work',
          color: '#C5CA8A',
          createdAt: 0,
        ),
        const Notebook(
          id: 'home',
          ownerEmail: 'you@notes.dev',
          name: 'Home',
          color: '#A9D4C4',
          createdAt: 0,
        ),
      ];
      final dash = noteDashboard(notes, notebooks, today: '2024-01-10');
      expect(dash.notebooks.firstWhere((t) => t.id == 'work').count, 2);
      expect(dash.notebooks.firstWhere((t) => t.id == 'home').count, 0);
    });
  });
}
