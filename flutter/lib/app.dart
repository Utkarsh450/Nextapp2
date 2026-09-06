import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/router/app_router.dart';
import 'package:notes_app/core/services/notification_service.dart';
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
///
/// Also owns the one live [NotificationService.onNoteTap] hookup — tapping
/// a reminder notification calls `go('/notes/$id')` on this same
/// [appRouterProvider] instance, matching `docs/flutter-architecture.md`
/// §3's "a reminder notification carries `noteId` → router
/// `go('/notes/$id')`, replacing the `pendingOpen` ref + `watchReminderOpens`
/// dance in `NotesApp.tsx`."
class const NotesApp({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends ConsumerState<NotesApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNoteTap = _openNote;
    // A tap that launched the app cold arrives before this `onNoteTap` is
    // set — flush it once the router this callback needs is guaranteed to
    // exist (after the first frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.flushPendingTap();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.onNoteTap = null;
    super.dispose();
  }

  void _openNote(int noteId) {
    ref.read(appRouterProvider).go('/notes/$noteId');
  }

  @override
  Widget build(BuildContext context) {
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
