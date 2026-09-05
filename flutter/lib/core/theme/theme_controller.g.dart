// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the active [PaperSkin].
///
/// **Scaffold-stage placeholder:** defaults to [PaperSkin.classic] every
/// launch. Theme *mode* (light/dark) already follows the system setting via
/// `MaterialApp.themeMode` in `app.dart`, matching the source's behavior.
/// Persisting the user's skin/theme/layout choice to the `Prefs` table
/// (mirroring `lib/theme.ts`'s three `localStorage` keys) is real Account
/// (#14) screen work and lands with that screen, not before — see
/// `docs/flutter-architecture.md` §6.

@ProviderFor(SkinController)
final skinControllerProvider = SkinControllerProvider._();

/// Holds the active [PaperSkin].
///
/// **Scaffold-stage placeholder:** defaults to [PaperSkin.classic] every
/// launch. Theme *mode* (light/dark) already follows the system setting via
/// `MaterialApp.themeMode` in `app.dart`, matching the source's behavior.
/// Persisting the user's skin/theme/layout choice to the `Prefs` table
/// (mirroring `lib/theme.ts`'s three `localStorage` keys) is real Account
/// (#14) screen work and lands with that screen, not before — see
/// `docs/flutter-architecture.md` §6.
final class SkinControllerProvider
    extends $NotifierProvider<SkinController, PaperSkin> {
  /// Holds the active [PaperSkin].
  ///
  /// **Scaffold-stage placeholder:** defaults to [PaperSkin.classic] every
  /// launch. Theme *mode* (light/dark) already follows the system setting via
  /// `MaterialApp.themeMode` in `app.dart`, matching the source's behavior.
  /// Persisting the user's skin/theme/layout choice to the `Prefs` table
  /// (mirroring `lib/theme.ts`'s three `localStorage` keys) is real Account
  /// (#14) screen work and lands with that screen, not before — see
  /// `docs/flutter-architecture.md` §6.
  SkinControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skinControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skinControllerHash();

  @$internal
  @override
  SkinController create() => SkinController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaperSkin value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaperSkin>(value),
    );
  }
}

String _$skinControllerHash() => r'163cc4457c5b572677b44117b27aed5f0ed2aedc';

/// Holds the active [PaperSkin].
///
/// **Scaffold-stage placeholder:** defaults to [PaperSkin.classic] every
/// launch. Theme *mode* (light/dark) already follows the system setting via
/// `MaterialApp.themeMode` in `app.dart`, matching the source's behavior.
/// Persisting the user's skin/theme/layout choice to the `Prefs` table
/// (mirroring `lib/theme.ts`'s three `localStorage` keys) is real Account
/// (#14) screen work and lands with that screen, not before — see
/// `docs/flutter-architecture.md` §6.

abstract class _$SkinController extends $Notifier<PaperSkin> {
  PaperSkin build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PaperSkin, PaperSkin>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaperSkin, PaperSkin>,
              PaperSkin,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
