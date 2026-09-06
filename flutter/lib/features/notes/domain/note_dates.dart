/// Direct port of `lib/notes/dates.ts`. Dates stay as `YYYY-MM-DD` strings
/// throughout — see `docs/flutter-architecture.md` §7.
library;

String todayIso([DateTime? now]) {
  final at = now ?? DateTime.now();
  final month = at.month.toString().padLeft(2, '0');
  final day = at.day.toString().padLeft(2, '0');
  return '${at.year}-$month-$day';
}

/// `"3:45 PM, Tuesday"` — matches `formatNoteTimestamp`.
String formatNoteTimestamp(int createdAtMs) {
  final at = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  final period = at.hour < 12 ? 'AM' : 'PM';
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final weekday = weekdays[at.weekday - 1];
  return '$hour12:$minute $period, $weekday';
}

bool isDueToday(String? dueAt, [String? today]) =>
    dueAt != null && dueAt == (today ?? todayIso());

bool isOverdue(String? dueAt, [String? today]) {
  if (dueAt == null) return false;
  final t = today ?? todayIso();
  return dueAt.compareTo(t) < 0;
}

/// Adds [days] (negative to subtract) to an ISO date string. Actually from
/// `lib/notes/agenda.ts` (`shiftISO`), not `dates.ts` — kept here since
/// it's a small, generic date utility and `agenda.ts` itself isn't ported
/// (the agenda/Plan feature, audit #12, is out of scope for the habit
/// tracker build — see `habits_board.dart`'s doc comment).
String shiftIso(String iso, int days) {
  final parts = iso.split('-').map(int.parse).toList();
  final shifted = DateTime(parts[0], parts[1], parts[2] + days);
  return todayIso(shifted);
}
