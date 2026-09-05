import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';

/// Port of `features/notes/ReminderFields.tsx` — due date, due time, and
/// alert-lead-time chips.
///
/// This only edits the fields; it does not schedule an OS notification —
/// see `note_reminders.dart`'s doc comment and
/// `docs/flutter-architecture.md` §5 (`notification_service` is separate,
/// not-yet-built work).
class const ReminderFieldsView({
  required final String? dueAt,
  required final String? dueTime,
  required final int alertMinutes,
  required final void Function(ReminderFields fields) onChange,
  super.key,
}) extends StatelessWidget {
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = dateOnly(dueAt) != null
        ? DateTime.parse(dueAt!)
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    onChange(
      resolveReminderFields(
        dueAt: iso,
        dueTime: dueTime,
        alertMinutes: alertMinutes < 0 ? 0 : alertMinutes,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    if (dueAt == null) return;
    final current = timeOnly(dueTime);
    final initial = current != null
        ? TimeOfDay(
            hour: int.parse(current.split(':')[0]),
            minute: int.parse(current.split(':')[1]),
          )
        : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final iso =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    onChange(
      resolveReminderFields(
        dueAt: dueAt,
        dueTime: iso,
        alertMinutes: dueTime == null && alertMinutes <= 0 ? 10 : alertMinutes,
      ),
    );
  }

  void _clearDate() {
    onChange(resolveReminderFields(alertMinutes: -1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final clock = formatClock(dueTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 14, color: muted),
            const SizedBox(width: 6),
            Text(
              'When to ping you',
              style: theme.textTheme.labelMedium?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(context),
                child: Text(dueAt ?? 'Date'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: dueAt == null ? null : () => _pickTime(context),
                child: Text(clock ?? 'Time'),
              ),
            ),
            if (dueAt != null)
              IconButton(
                tooltip: 'Clear date',
                onPressed: _clearDate,
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
        if (dueAt != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in alertOptions)
                ChoiceChip(
                  label: Text(option.short),
                  selected: alertMinutes == option.minutes,
                  onSelected: (_) => onChange(
                    resolveReminderFields(
                      dueAt: dueAt,
                      dueTime: dueTime,
                      alertMinutes: option.minutes,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _hintText(),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }

  String _hintText() {
    if (dueAt == null) return 'Add a date to get a reminder.';
    final allDayNote = dueTime == null
        ? ' · all-day events alert at 9:00 AM'
        : '';
    return '${alertLabel(alertMinutes)}$allDayNote.';
  }
}
