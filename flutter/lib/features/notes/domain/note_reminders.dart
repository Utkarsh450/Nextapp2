/// Direct port of the reminder logic in `lib/notes/reminders.ts`.
///
/// Notification *scheduling* itself is out of scope for this build — these
/// functions only compute and validate the fields; wiring `remindAt` to an
/// actual OS notification is separate `notification_service` work per
/// `docs/flutter-architecture.md` §5, not done here.
library;

import 'package:notes_app/features/notes/domain/note_dates.dart';

const int allDayHour = 9;

/// One entry in the alert-lead-time picker.
class const AlertOption({
  required final int minutes,
  required final String label,
  required final String short,
});

const List<AlertOption> alertOptions = [
  AlertOption(minutes: -1, label: 'No alert', short: 'None'),
  AlertOption(minutes: 0, label: 'At time of event', short: 'At time'),
  AlertOption(minutes: 5, label: '5 minutes before', short: '5 min'),
  AlertOption(minutes: 10, label: '10 minutes before', short: '10 min'),
  AlertOption(minutes: 30, label: '30 minutes before', short: '30 min'),
  AlertOption(minutes: 60, label: '1 hour before', short: '1 hour'),
  AlertOption(minutes: 1440, label: '1 day before', short: '1 day'),
];

bool _isAlertMinutes(int value) => alertOptions.any((o) => o.minutes == value);

/// A note's due-date/alert set, always changed together — see
/// `Note.withReminder`.
class const ReminderFields({
  required final String? dueAt,
  required final String? dueTime,
  required final int alertMinutes,
  required final String? remindAt,
});

final RegExp _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

String? dateOnly(String? value) {
  if (value == null) return null;
  final candidate = value.length >= 10 ? value.substring(0, 10) : value;
  return _dateRe.hasMatch(candidate) ? candidate : null;
}

String? timeOnly(String? value) {
  if (value == null) return null;
  return _timeRe.hasMatch(value) ? value : null;
}

DateTime? _eventDate(String dueAt, String? dueTime) {
  final dateMatch = _dateRe.firstMatch(dueAt);
  if (dateMatch == null) return null;
  final parts = dueAt.split('-').map(int.parse).toList();
  final timeMatch = dueTime != null ? _timeRe.firstMatch(dueTime) : null;
  final hour = timeMatch != null
      ? int.parse(dueTime!.split(':')[0])
      : allDayHour;
  final minute = timeMatch != null ? int.parse(dueTime!.split(':')[1]) : 0;
  return DateTime(parts[0], parts[1], parts[2], hour, minute);
}

/// The moment a reminder should fire, or `null` if there's no valid due
/// date, no alert wanted (`alertMinutes < 0`), or the moment is not after
/// [now] (which defaults to the real current time — matching the source's
/// own default; `resolveReminderFields` below deliberately passes epoch 0
/// instead, so it computes `remindAt` unconditionally).
DateTime? reminderFireDate(
  String? dueAt,
  String? dueTime,
  int alertMinutes, [
  DateTime? now,
]) {
  final date = dateOnly(dueAt);
  if (date == null || alertMinutes < 0) return null;
  final event = _eventDate(date, timeOnly(dueTime));
  if (event == null) return null;
  final fire = event.subtract(Duration(minutes: alertMinutes));
  return fire.isAfter(now ?? DateTime.now()) ? fire : null;
}

/// Normalizes a raw `{dueAt, dueTime, alertMinutes}` edit into a consistent
/// [ReminderFields] set — matches `reminderFields()`. Clearing the date
/// (`dueAt: null`) resets everything; a date with no explicit alert
/// defaults to `0` (at time of event).
ReminderFields resolveReminderFields({
  String? dueAt,
  String? dueTime,
  int? alertMinutes,
}) {
  final resolvedDueAt = dateOnly(dueAt);
  if (resolvedDueAt == null) {
    return const ReminderFields(
      dueAt: null,
      dueTime: null,
      alertMinutes: -1,
      remindAt: null,
    );
  }
  final resolvedDueTime = timeOnly(dueTime);
  final resolvedAlert =
      alertMinutes != null && _isAlertMinutes(alertMinutes) ? alertMinutes : 0;
  // Matches the source passing a literal `0` here: this stores whatever
  // remindAt the fields resolve to, even if it's already in the past —
  // the "is it still upcoming" check belongs to the (not yet built)
  // notification-scheduling service, not to field normalization.
  final fire = reminderFireDate(
    resolvedDueAt,
    resolvedDueTime,
    resolvedAlert,
    DateTime.fromMillisecondsSinceEpoch(0),
  );
  return ReminderFields(
    dueAt: resolvedDueAt,
    dueTime: resolvedDueTime,
    alertMinutes: resolvedAlert,
    remindAt: fire?.toIso8601String(),
  );
}

String alertLabel(int alertMinutes) {
  return alertOptions
      .firstWhere(
        (o) => o.minutes == alertMinutes,
        orElse: () => alertOptions[1],
      )
      .label;
}

String? formatClock(String? dueTime) {
  final time = timeOnly(dueTime);
  if (time == null) return null;
  final parts = time.split(':');
  final hour = int.parse(parts[0]);
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final twelve = hour % 12 == 0 ? 12 : hour % 12;
  return '$twelve:${parts[1]} $suffix';
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The short due-date chip text, e.g. "Overdue · 3:00 PM" or "Jan 5" —
/// matches `formatDueChip`.
String? formatDueChip(String? dueAt, [String? dueTime, String? today]) {
  final date = dateOnly(dueAt);
  if (date == null) return null;
  final clock = formatClock(dueTime);
  final at = today ?? todayIso();
  if (today != null && date.compareTo(at) < 0) {
    return clock != null ? 'Overdue · $clock' : 'Overdue';
  }
  if (today != null && date == at) return clock ?? 'Due today';
  final parts = date.split('-').map(int.parse).toList();
  final pretty = '${_monthNames[parts[1] - 1]} ${parts[2]}';
  return clock != null ? '$pretty · $clock' : pretty;
}
