// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the active light/dark mode — matches `useTheme` in
/// `hooks/useSession.ts`. **Correction, found while wiring the real
/// toggle for the Account screen:** the source defaults to light and only
/// switches via this explicit in-app toggle — it does *not* read the OS's
/// dark-mode preference at all (`readTheme` falls back to `'light'`, never
/// `PlatformDispatcher.platformBrightness`). `app.dart` previously left
/// [ThemeMode] unset (defaulting to [ThemeMode.system]) under a doc
/// comment claiming that matched the source; it didn't — this controller
/// and `app.dart`'s use of it are the actual fix.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// Holds the active light/dark mode — matches `useTheme` in
/// `hooks/useSession.ts`. **Correction, found while wiring the real
/// toggle for the Account screen:** the source defaults to light and only
/// switches via this explicit in-app toggle — it does *not* read the OS's
/// dark-mode preference at all (`readTheme` falls back to `'light'`, never
/// `PlatformDispatcher.platformBrightness`). `app.dart` previously left
/// [ThemeMode] unset (defaulting to [ThemeMode.system]) under a doc
/// comment claiming that matched the source; it didn't — this controller
/// and `app.dart`'s use of it are the actual fix.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// Holds the active light/dark mode — matches `useTheme` in
  /// `hooks/useSession.ts`. **Correction, found while wiring the real
  /// toggle for the Account screen:** the source defaults to light and only
  /// switches via this explicit in-app toggle — it does *not* read the OS's
  /// dark-mode preference at all (`readTheme` falls back to `'light'`, never
  /// `PlatformDispatcher.platformBrightness`). `app.dart` previously left
  /// [ThemeMode] unset (defaulting to [ThemeMode.system]) under a doc
  /// comment claiming that matched the source; it didn't — this controller
  /// and `app.dart`'s use of it are the actual fix.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'd1044aef4a36c006b295aa4d3be0457df2795453';

/// Holds the active light/dark mode — matches `useTheme` in
/// `hooks/useSession.ts`. **Correction, found while wiring the real
/// toggle for the Account screen:** the source defaults to light and only
/// switches via this explicit in-app toggle — it does *not* read the OS's
/// dark-mode preference at all (`readTheme` falls back to `'light'`, never
/// `PlatformDispatcher.platformBrightness`). `app.dart` previously left
/// [ThemeMode] unset (defaulting to [ThemeMode.system]) under a doc
/// comment claiming that matched the source; it didn't — this controller
/// and `app.dart`'s use of it are the actual fix.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
