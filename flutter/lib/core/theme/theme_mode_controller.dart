import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_controller.g.dart';

/// Holds the active light/dark mode — matches `useTheme` in
/// `hooks/useSession.ts`. **Correction, found while wiring the real
/// toggle for the Account screen:** the source defaults to light and only
/// switches via this explicit in-app toggle — it does *not* read the OS's
/// dark-mode preference at all (`readTheme` falls back to `'light'`, never
/// `PlatformDispatcher.platformBrightness`). `app.dart` previously left
/// [ThemeMode] unset (defaulting to [ThemeMode.system]) under a doc
/// comment claiming that matched the source; it didn't — this controller
/// and `app.dart`'s use of it are the actual fix.
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
