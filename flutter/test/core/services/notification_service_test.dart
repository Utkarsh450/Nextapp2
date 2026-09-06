import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/services/notification_service.dart';

void main() {
  // No platform-channel plugin is registered in a plain (non-widget)
  // `test()` environment — the same situation `notes_controller_test.dart`
  // exercises on every note mutation. This is a real, expected environment
  // for this app's own test suite, not a misconfiguration: reminder
  // delivery is a best-effort side channel, so a missing plugin should be
  // swallowed rather than thrown (previously a `LateInitializationError`
  // here failed every notes-controller unit test).
  test('scheduleNoteReminder completes without throwing when no plugin is '
      'registered', () async {
    await expectLater(
      NotificationService.instance.scheduleNoteReminder(
        noteId: 1,
        title: 'Test',
        body: 'Body',
        at: DateTime.now().add(const Duration(days: 1)),
      ),
      completes,
    );
  });

  test('cancelNoteReminder completes without throwing when no plugin is '
      'registered', () async {
    await expectLater(
      NotificationService.instance.cancelNoteReminder(1),
      completes,
    );
  });

  test(
    'scheduleNoteReminder is a no-op for a moment that is not in the future',
    () async {
      await expectLater(
        NotificationService.instance.scheduleNoteReminder(
          noteId: 1,
          title: 'Test',
          body: 'Body',
          at: DateTime.now().subtract(const Duration(days: 1)),
        ),
        completes,
      );
    },
  );
}
