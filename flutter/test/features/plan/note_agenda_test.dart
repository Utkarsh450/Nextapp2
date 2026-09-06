import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/plan/domain/note_agenda.dart';

Note _note({
  required int id,
  String body = '',
  String? dueAt,
  String? dueTime,
  int? trashedAt,
  bool archived = false,
}) => Note(
  id: id,
  ownerEmail: 'you@notes.dev',
  createdAt: 0,
  updatedAt: 0,
  color: '#C5CA8A',
  body: body,
  dueAt: dueAt,
  dueTime: dueTime,
  trashedAt: trashedAt,
  archived: archived,
);

void main() {
  const today = '2024-01-10';

  test('buckets overdue, due-today, and within-a-week notes separately', () {
    final agenda = noteAgenda([
      _note(id: 1, dueAt: '2024-01-05'), // overdue
      _note(id: 2, dueAt: today), // due today
      _note(id: 3, dueAt: '2024-01-15'), // within 7 days
      _note(id: 4, dueAt: '2024-01-20'), // beyond the 7-day horizon
    ], today);

    expect(agenda.overdue.map((n) => n.id), [1]);
    expect(agenda.dueToday.map((n) => n.id), [2]);
    expect(agenda.soon.map((n) => n.id), [3]);
    expect(agenda.waiting, 3);
  });

  test('the 7-day horizon is inclusive of day 7', () {
    final agenda = noteAgenda([
      _note(id: 1, dueAt: '2024-01-17'), // exactly 7 days out
    ], today);
    expect(agenda.soon.map((n) => n.id), [1]);
  });

  test('sorts within a bucket by due date then due time', () {
    final agenda = noteAgenda([
      _note(id: 1, dueAt: today, dueTime: '14:00'),
      _note(id: 2, dueAt: today, dueTime: '09:00'),
      _note(id: 3, dueAt: today),
    ], today);
    expect(agenda.dueToday.map((n) => n.id), [2, 1, 3]);
  });

  test('open checklists with no due date land in lists, not soon/overdue', () {
    final agenda = noteAgenda([_note(id: 1, body: '- [ ] a\n- [x] b')], today);
    expect(agenda.lists.map((n) => n.id), [1]);
    expect(agenda.overdue, isEmpty);
  });

  test('a fully-checked list does not count as open', () {
    final agenda = noteAgenda([_note(id: 1, body: '- [x] a\n- [x] b')], today);
    expect(agenda.lists, isEmpty);
  });

  test('a checklist with a due date is not double-counted as a list', () {
    final agenda = noteAgenda([
      _note(id: 1, body: '- [ ] a', dueAt: today),
    ], today);
    expect(agenda.dueToday.map((n) => n.id), [1]);
    expect(agenda.lists, isEmpty);
  });

  test('archived and trashed notes never appear', () {
    final agenda = noteAgenda([
      _note(id: 1, dueAt: '2024-01-05', archived: true),
      _note(id: 2, dueAt: '2024-01-05', trashedAt: 1),
    ], today);
    expect(agenda.overdue, isEmpty);
    expect(agenda.waiting, 0);
  });
}
