import 'package:notes_app/core/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_alerts_controller.g.dart';

/// Matches `lib/native/notifications.ts`'s `calendarAlertsAvailable`/
/// `enableCalendarAlerts` — the source schedules *calendar* events
/// (Android's Calendar Provider) for timed notes; this requests plain OS
/// notification + exact-alarm permission instead
/// (`core/services/notification_service.dart`), which is what
/// `notes_controller.dart` actually schedules reminders against. Delegates
/// to the shared [NotificationService] instance rather than holding its own
/// plugin/initialization.
@riverpod
class PhoneAlertsController extends _$PhoneAlertsController {
  @override
  bool build() => false;

  Future<bool> requestEnable() async {
    final granted = await NotificationService.instance.requestPermission();
    state = granted;
    return state;
  }
}
