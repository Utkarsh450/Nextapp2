// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Route table — mapped 1:1 to the screens enumerated in
/// `docs/feature-audit.md` §1, per `docs/flutter-architecture.md` §3.
///
/// The `/auth` → `/onboarding` → shell redirect guard mirrors the branch
/// order in `NotesApp.tsx` (renders `AuthScreen` when there's no session,
/// `OnboardingScreen` when there's a session but onboarding isn't done).
/// One deliberate simplification:
/// the source also has a `loading` branch while its session check makes a
/// network round-trip — there's no backend here to await (session state is
/// synchronous in-memory Riverpod state, per the "no backend/DB for now"
/// instruction), so that branch has nothing to wait for and is skipped.
///
/// Every route now renders its real screen — the last two
/// (`/you`, `/privacy`) landed together with the Account/Settings and
/// Privacy policy screens (feature-audit #14, #15).

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Route table — mapped 1:1 to the screens enumerated in
/// `docs/feature-audit.md` §1, per `docs/flutter-architecture.md` §3.
///
/// The `/auth` → `/onboarding` → shell redirect guard mirrors the branch
/// order in `NotesApp.tsx` (renders `AuthScreen` when there's no session,
/// `OnboardingScreen` when there's a session but onboarding isn't done).
/// One deliberate simplification:
/// the source also has a `loading` branch while its session check makes a
/// network round-trip — there's no backend here to await (session state is
/// synchronous in-memory Riverpod state, per the "no backend/DB for now"
/// instruction), so that branch has nothing to wait for and is skipped.
///
/// Every route now renders its real screen — the last two
/// (`/you`, `/privacy`) landed together with the Account/Settings and
/// Privacy policy screens (feature-audit #14, #15).

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Route table — mapped 1:1 to the screens enumerated in
  /// `docs/feature-audit.md` §1, per `docs/flutter-architecture.md` §3.
  ///
  /// The `/auth` → `/onboarding` → shell redirect guard mirrors the branch
  /// order in `NotesApp.tsx` (renders `AuthScreen` when there's no session,
  /// `OnboardingScreen` when there's a session but onboarding isn't done).
  /// One deliberate simplification:
  /// the source also has a `loading` branch while its session check makes a
  /// network round-trip — there's no backend here to await (session state is
  /// synchronous in-memory Riverpod state, per the "no backend/DB for now"
  /// instruction), so that branch has nothing to wait for and is skipped.
  ///
  /// Every route now renders its real screen — the last two
  /// (`/you`, `/privacy`) landed together with the Account/Settings and
  /// Privacy policy screens (feature-audit #14, #15).
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'0899671c0e9d06b21da40c3ef8ec35b0ef97ec61';
