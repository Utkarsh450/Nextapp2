import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/router/app_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';
import 'package:notes_app/core/theme/theme_mode_controller.dart';

/// Root widget: wires the router and the light/dark [ThemeData] pair for
/// the active [PaperSkin] into [MaterialApp.router].
///
/// Theme *mode* is an explicit in-app toggle (Account screen's "Day
/// paper"/"Night ink" row), matching the source's own `useTheme` — see
/// `theme_mode_controller.dart`'s doc comment for why this isn't
/// [ThemeMode.system].
class const NotesApp({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final skin = ref.watch(skinControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(skin: skin, brightness: Brightness.light),
      darkTheme: buildAppTheme(skin: skin, brightness: Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
