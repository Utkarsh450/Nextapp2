import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Real reminder delivery — schedules/cancels an exact local notification
/// per note, matching `lib/native/notifications.ts`'s `scheduleNoteReminder`/
/// `cancelNoteReminder` (Capacitor `LocalNotifications` there,
/// `flutter_local_notifications` + `timezone` here, per
/// `docs/flutter-architecture.md` §5's `notification_service` entry).
///
/// One shared plugin instance/initialization: `phone_alerts_controller.dart`
/// (the Account screen's "Phone alerts" permission row) and
/// `notes_controller.dart` (schedule-on-save, cancel-on-trash/delete,
/// resync-on-launch — mirroring `hooks/useNotes.ts`'s `queueReminder`/
/// `resyncReminders`) both go through this instead of each holding their
/// own.
class NotificationService {
  // Non-final mutable fields below (`_initialized`, `_pendingNoteId`,
  // `onNoteTap`), so this can't use the primary-constructor `class const`
  // shorthand, which implies `const`.
  // ignore: unnecessary_type_name_in_constructor
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'note-reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription =
      'Calendar-style alerts for notes with a date and time';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _unavailable = false;
  int? _pendingNoteId;

  /// Set once the app's router is mounted (see `app.dart`); a tap that
  /// arrives before that — a cold start via a notification — is buffered
  /// in [_pendingNoteId] and delivered the moment this is assigned via
  /// [flushPendingTap].
  void Function(int noteId)? onNoteTap;

  /// Returns whether the plugin is usable. `notes_controller.dart` calls
  /// into this on every note mutation, including from a plain (non-widget)
  /// `test()` unit test where no platform-channel plugin is registered at
  /// all — that's a real, expected environment for this app's own test
  /// suite, not a misconfiguration, so a failure here is cached and
  /// swallowed rather than thrown: reminder delivery is a best-effort side
  /// channel that should never be able to break note create/edit/trash.
  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    if (_unavailable) return false;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } on Object {
      // Falls back to whatever `timezone` defaults its local location to
      // (UTC) — a lookup hiccup here shouldn't take down scheduling
      // entirely, just risk an off-by-timezone-offset fire time.
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      _initialized = true;
      return true;
    } on Object {
      _unavailable = true;
      return false;
    }
  }

  void _handleResponse(NotificationResponse response) {
    final id = int.tryParse(response.payload ?? '');
    if (id == null) return;
    final callback = onNoteTap;
    if (callback != null) {
      callback(id);
    } else {
      _pendingNoteId = id;
    }
  }

  /// Delivers a tap that arrived before [onNoteTap] was set.
  void flushPendingTap() {
    final pending = _pendingNoteId;
    if (pending == null) return;
    _pendingNoteId = null;
    onNoteTap?.call(pending);
  }

  /// Matches `enableCalendarAlerts` — notification permission plus (Android
  /// 12+) the separate exact-alarm permission, which opens a system
  /// Settings screen rather than an in-app dialog when it's not yet
  /// granted.
  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == false) {
      await android?.requestExactAlarmsPermission();
    }
    return granted ?? false;
  }

  /// Matches `nativeId` — notification ids must fit a 32-bit int, but note
  /// ids here are millisecond timestamps.
  static int _nativeId(int noteId) {
    final value = noteId.abs() % 2147483647;
    return value == 0 ? 1 : value;
  }

  /// Matches `scheduleNoteReminder` — a no-op for a past/invalid moment.
  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    if (!await _ensureInitialized()) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    final scheduled = tz.TZDateTime.from(at, tz.local);
    final resolvedTitle = title.isEmpty ? 'Note reminder' : title;
    try {
      await _plugin.zonedSchedule(
        id: _nativeId(noteId),
        title: resolvedTitle,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '$noteId',
      );
    } on PlatformException {
      // Exact-alarm permission can still be missing/revoked on some OEMs
      // even after `requestExactAlarmsPermission()` — fall back to an
      // inexact trigger rather than silently dropping the reminder.
      await _plugin.zonedSchedule(
        id: _nativeId(noteId),
        title: resolvedTitle,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$noteId',
      );
    }
  }

  /// Matches `cancelNoteReminder`.
  Future<void> cancelNoteReminder(int noteId) async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: _nativeId(noteId));
  }
}
