import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_alerts_controller.g.dart';

/// Simplified stand-in for `lib/native/notifications.ts`'s
/// `calendarAlertsAvailable`/`enableCalendarAlerts` — the source schedules
/// *calendar* events (Android's Calendar Provider) for timed notes; this
/// requests plain OS notification permission instead (`flutter_local_
/// notifications`, already a dependency, previously unwired). Actually
/// scheduling a local notification per note's `remindAt` is real reminder-
/// delivery work of its own and isn't part of this pass — this only
/// covers the Account screen's "Phone alerts" permission toggle.
@riverpod
class PhoneAlertsController extends _$PhoneAlertsController {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  @override
  bool build() => false;

  Future<bool> requestEnable() async {
    if (!_initialized) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _initialized = true;
    }
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    state = granted ?? false;
    return state;
  }
}
