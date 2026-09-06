import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';

void main() {
  group('reminderFireDate', () {
    test('fires alertMinutes before an event with a time', () {
      final fire = reminderFireDate(
        '2026-09-10',
        '15:00',
        30,
        DateTime(2026, 9),
      );
      expect(fire, DateTime(2026, 9, 10, 14, 30));
    });

    test('uses allDayHour (9am) when there is no due time', () {
      final fire = reminderFireDate('2026-09-10', null, 0, DateTime(2026, 9));
      expect(fire, DateTime(2026, 9, 10, 9));
    });

    test('returns null when alertMinutes is negative (no alert wanted)', () {
      expect(
        reminderFireDate('2026-09-10', '15:00', -1, DateTime(2026, 9)),
        isNull,
      );
    });

    test('returns null for a moment that is not after now', () {
      expect(
        reminderFireDate('2026-09-10', '15:00', 0, DateTime(2026, 9, 11)),
        isNull,
      );
    });

    test('returns null for an invalid date', () {
      expect(
        reminderFireDate('not-a-date', '15:00', 0, DateTime(2026, 9)),
        isNull,
      );
    });
  });

  group('resolveReminderFields', () {
    test('clearing the date resets everything', () {
      final fields = resolveReminderFields();
      expect(fields.dueAt, isNull);
      expect(fields.dueTime, isNull);
      expect(fields.alertMinutes, -1);
      expect(fields.remindAt, isNull);
    });

    test('a date with no explicit alert defaults to 0 (at time of event)', () {
      final fields = resolveReminderFields(dueAt: '2026-09-10');
      expect(fields.alertMinutes, 0);
    });

    test('an invalid alertMinutes value falls back to 0', () {
      final fields = resolveReminderFields(
        dueAt: '2026-09-10',
        alertMinutes: 7,
      );
      expect(fields.alertMinutes, 0);
    });

    test('computes remindAt even when it is already in the past', () {
      final fields = resolveReminderFields(
        dueAt: '2000-01-01',
        dueTime: '09:00',
        alertMinutes: 0,
      );
      expect(fields.remindAt, '2000-01-01T09:00:00.000');
    });
  });

  group('formatDueChip', () {
    test('renders a bare date as "Mon D"', () {
      expect(formatDueChip('2026-09-10'), 'Sep 10');
    });

    test('appends the clock time when given', () {
      expect(formatDueChip('2026-09-10', '15:00'), 'Sep 10 · 3:00 PM');
    });

    test('returns null for no date', () {
      expect(formatDueChip(null), isNull);
    });
  });

  group('reminderBody', () {
    test('joins the due chip and a preview snippet', () {
      final body = reminderBody(
        'Renew passport',
        '2026-09-10',
        '15:00',
        'Bring the old one and two photos.',
      );
      expect(body, 'Sep 10 · 3:00 PM · Bring the old one and two photos.');
    });

    test('falls back to the title when there is no preview text', () {
      final body = reminderBody('Renew passport', '2026-09-10', null, '   ');
      expect(body, 'Sep 10 · Renew passport');
    });

    test(
      'falls back to a generic line when there is neither preview nor title',
      () {
        final body = reminderBody('', '2026-09-10', null, '');
        expect(body, 'Sep 10 · You have a note due.');
      },
    );

    test('omits the due chip entirely when there is no due date', () {
      final body = reminderBody('Renew passport', null, null, 'A note.');
      expect(body, 'A note.');
    });

    test('truncates a long preview to 80 characters', () {
      final long = 'x' * 100;
      final body = reminderBody('Title', null, null, long);
      expect(body, 'x' * 80);
    });
  });
}
