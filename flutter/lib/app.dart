import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/router/app_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';

/// Root widget: wires the router and the light/dark [ThemeData] pair for
/// the active [PaperSkin] into [MaterialApp.router].
///
/// Theme *mode* follows the OS setting (`ThemeMode.system` is
/// [MaterialApp]'s own default, left unset here), matching the source
/// app's `.dark` class toggle behavior; only the *skin* is an explicit
/// in-app choice (see `theme_controller.dart`).
class const NotesApp({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final skin = ref.watch(skinControllerProvider);

    return MaterialApp.router(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(skin: skin, brightness: Brightness.light),
      darkTheme: buildAppTheme(skin: skin, brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}
