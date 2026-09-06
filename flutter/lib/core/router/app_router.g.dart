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
/// **Scaffold-stage placeholder:** `/you` and `/privacy` still render
/// [PlaceholderScreen] until their real screens are built.

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
/// **Scaffold-stage placeholder:** `/you` and `/privacy` still render
/// [PlaceholderScreen] until their real screens are built.

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
  /// **Scaffold-stage placeholder:** `/you` and `/privacy` still render
  /// [PlaceholderScreen] until their real screens are built.
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

String _$appRouterHash() => r'3db24b5ccd7f5ace957e3284891e761e04410b7a';
