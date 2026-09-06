/// Direct port of `lib/notes/dashboard.ts` — the Today dashboard's math
/// (greeting copy, sparkline path, and the aggregate `NoteDashboard`
/// summary a note list boils down to).
library;

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:notes_app/features/notebooks/domain/notebook.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

class const WeekPoint({required final String day, required final int count});

/// One dashboard notebook tile — matches the inline shape `noteDashboard`
/// builds from `Notebook` + a live note count.
class const NotebookTile({
  required final String id,
  required final String name,
  required final String color,
  required final int count,
});

class const NoteDashboard({
  required final int live,
  required final int open,
  required final int done,
  required final List<Note> due,
  required final int tasksTotal,
  required final int tasksDone,
  required final int percent,
  required final List<WeekPoint> week,
  required final Note? featured,
  required final List<NotebookTile> notebooks,
});

List<Note> _liveNotes(List<Note> notes) =>
    notes.where((n) => n.trashedAt == null && !n.archived).toList();

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// An SVG path `d` string tracing [values] as a polyline in a
/// [width]x[height] box — matches `sparkPath`. Kept as a string (rather
/// than raw points) so this stays a literal, testable port; the widget
/// that paints it re-derives points from this same string.
String sparkPath(List<int> values, {double width = 88, double height = 32}) {
  if (values.isEmpty) return '';
  final max = values.fold(1, (a, b) => a > b ? a : b);
  final last = math.max(values.length - 1, 1);
  final segments = <String>[];
  for (var index = 0; index < values.length; index++) {
    final x = (index / last) * width;
    final y = height - 3 - (values[index] / max) * (height - 6);
    final prefix = index == 0 ? 'M' : 'L';
    segments.add('$prefix${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)}');
  }
  return segments.join(' ');
}

/// Matches `noteDashboard`. [now] defaults to the current time; pass it
/// explicitly in tests for a deterministic 7-day sparkline window.
NoteDashboard noteDashboard(
  List<Note> notes,
  List<Notebook> notebooks, {
  String? today,
  int? now,
}) {
  final at = today ?? todayIso();
  final nowMs = now ?? DateTime.now().millisecondsSinceEpoch;
  final live = _liveNotes(notes);

  var tasksTotal = 0;
  var tasksDone = 0;
  for (final note in live) {
    final progress = checklistProgress(note.body);
    tasksTotal += progress.total;
    tasksDone += progress.done;
  }

  final due = live
      .where((n) => isDueToday(n.dueAt, at) || isOverdue(n.dueAt, at))
      .toList();
  final done = live.where((n) => n.confirmed).length;
  final open = live.length - done;
  final percent = tasksTotal > 0
      ? ((tasksDone / tasksTotal) * 100).round()
      : live.isNotEmpty
      ? ((done / live.length) * 100).round()
      : 0;

  const dayMs = 24 * 60 * 60 * 1000;
  final week = List.generate(7, (index) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      nowMs - (6 - index) * dayMs,
    );
    final day = todayIso(date);
    final count = live
        .where(
          (n) =>
              todayIso(DateTime.fromMillisecondsSinceEpoch(n.updatedAt)) == day,
        )
        .length;
    return WeekPoint(day: day, count: count);
  });

  final featured =
      live.firstWhereOrNull((n) => n.pinned) ??
      due.firstOrNull ??
      live.firstWhereOrNull((n) => checklistProgress(n.body).total > 0) ??
      live.firstOrNull;

  final counts = <String, int>{};
  for (final note in live) {
    counts[note.notebookId] = (counts[note.notebookId] ?? 0) + 1;
  }

  return NoteDashboard(
    live: live.length,
    open: open,
    done: done,
    due: due,
    tasksTotal: tasksTotal,
    tasksDone: tasksDone,
    percent: percent,
    week: week,
    featured: featured,
    notebooks: [
      for (final book in notebooks)
        NotebookTile(
          id: book.id,
          name: book.name,
          color: book.color,
          count: counts[book.id] ?? 0,
        ),
    ],
  );
}
