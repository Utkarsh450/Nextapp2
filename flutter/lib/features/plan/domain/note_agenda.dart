/// Direct port of `lib/notes/agenda.ts` — the Plan screen's "What's next"
/// buckets (feature-audit #12).
library;

import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

List<Note> _liveNotes(List<Note> notes) =>
    notes.where((n) => n.trashedAt == null && !n.archived).toList();

int _byDue(Note a, Note b) {
  final date = (a.dueAt ?? '').compareTo(b.dueAt ?? '');
  if (date != 0) return date;
  return (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99');
}

class const NoteAgenda({
  required final List<Note> overdue,
  required final List<Note> dueToday,
  required final List<Note> soon,
  required final List<Note> lists,
  required final int waiting,
});

/// Matches `noteAgenda`. `soon` is a 7-day lookahead (exclusive of today,
/// inclusive of the 7th day out); `lists` is any open checklist with no
/// due date at all (a due-dated checklist belongs to one of the other
/// three buckets instead).
NoteAgenda noteAgenda(List<Note> notes, [String? today]) {
  final at = today ?? todayIso();
  final items = _liveNotes(notes);
  final horizon = shiftIso(at, 7);

  final overdue = items.where((n) => isOverdue(n.dueAt, at)).toList()
    ..sort(_byDue);
  final dueToday = items.where((n) => isDueToday(n.dueAt, at)).toList()
    ..sort(_byDue);
  final soon =
      items
          .where(
            (n) =>
                n.dueAt != null &&
                n.dueAt!.compareTo(at) > 0 &&
                n.dueAt!.compareTo(horizon) <= 0,
          )
          .toList()
        ..sort(_byDue);
  final lists = items.where((n) {
    final progress = checklistProgress(n.body);
    return progress.total > 0 &&
        progress.done < progress.total &&
        n.dueAt == null;
  }).toList();

  return NoteAgenda(
    overdue: overdue,
    dueToday: dueToday,
    soon: soon,
    lists: lists,
    waiting: overdue.length + dueToday.length + soon.length + lists.length,
  );
}
