// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_alerts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Simplified stand-in for `lib/native/notifications.ts`'s
/// `calendarAlertsAvailable`/`enableCalendarAlerts` — the source schedules
/// *calendar* events (Android's Calendar Provider) for timed notes; this
/// requests plain OS notification permission instead (`flutter_local_
/// notifications`, already a dependency, previously unwired). Actually
/// scheduling a local notification per note's `remindAt` is real reminder-
/// delivery work of its own and isn't part of this pass — this only
/// covers the Account screen's "Phone alerts" permission toggle.

@ProviderFor(PhoneAlertsController)
final phoneAlertsControllerProvider = PhoneAlertsControllerProvider._();

/// Simplified stand-in for `lib/native/notifications.ts`'s
/// `calendarAlertsAvailable`/`enableCalendarAlerts` — the source schedules
/// *calendar* events (Android's Calendar Provider) for timed notes; this
/// requests plain OS notification permission instead (`flutter_local_
/// notifications`, already a dependency, previously unwired). Actually
/// scheduling a local notification per note's `remindAt` is real reminder-
/// delivery work of its own and isn't part of this pass — this only
/// covers the Account screen's "Phone alerts" permission toggle.
final class PhoneAlertsControllerProvider
    extends $NotifierProvider<PhoneAlertsController, bool> {
  /// Simplified stand-in for `lib/native/notifications.ts`'s
  /// `calendarAlertsAvailable`/`enableCalendarAlerts` — the source schedules
  /// *calendar* events (Android's Calendar Provider) for timed notes; this
  /// requests plain OS notification permission instead (`flutter_local_
  /// notifications`, already a dependency, previously unwired). Actually
  /// scheduling a local notification per note's `remindAt` is real reminder-
  /// delivery work of its own and isn't part of this pass — this only
  /// covers the Account screen's "Phone alerts" permission toggle.
  PhoneAlertsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneAlertsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneAlertsControllerHash();

  @$internal
  @override
  PhoneAlertsController create() => PhoneAlertsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$phoneAlertsControllerHash() =>
    r'82e3a11c2ff4d01a0f65c5a88e23b199d7857253';

/// Simplified stand-in for `lib/native/notifications.ts`'s
/// `calendarAlertsAvailable`/`enableCalendarAlerts` — the source schedules
/// *calendar* events (Android's Calendar Provider) for timed notes; this
/// requests plain OS notification permission instead (`flutter_local_
/// notifications`, already a dependency, previously unwired). Actually
/// scheduling a local notification per note's `remindAt` is real reminder-
/// delivery work of its own and isn't part of this pass — this only
/// covers the Account screen's "Phone alerts" permission toggle.

abstract class _$PhoneAlertsController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
