// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Direct port of `lib/onboarding.ts` — which emails have finished the
/// onboarding flow. **In-memory only**, matching every other controller in
/// this build: the source persists this to `localStorage`, so (like
/// session state) it resets on every app restart here instead of a Drift
/// table — there's no equivalent of "already onboarded" surviving a real
/// app restart yet.

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

/// Direct port of `lib/onboarding.ts` — which emails have finished the
/// onboarding flow. **In-memory only**, matching every other controller in
/// this build: the source persists this to `localStorage`, so (like
/// session state) it resets on every app restart here instead of a Drift
/// table — there's no equivalent of "already onboarded" surviving a real
/// app restart yet.
final class OnboardingControllerProvider
    extends $NotifierProvider<OnboardingController, Set<String>> {
  /// Direct port of `lib/onboarding.ts` — which emails have finished the
  /// onboarding flow. **In-memory only**, matching every other controller in
  /// this build: the source persists this to `localStorage`, so (like
  /// session state) it resets on every app restart here instead of a Drift
  /// table — there's no equivalent of "already onboarded" surviving a real
  /// app restart yet.
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'c775613123d1a2ec236b787c377043a99973b10b';

/// Direct port of `lib/onboarding.ts` — which emails have finished the
/// onboarding flow. **In-memory only**, matching every other controller in
/// this build: the source persists this to `localStorage`, so (like
/// session state) it resets on every app restart here instead of a Drift
/// table — there's no equivalent of "already onboarded" surviving a real
/// app restart yet.

abstract class _$OnboardingController extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
