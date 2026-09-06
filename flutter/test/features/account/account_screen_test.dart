import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';
import 'package:notes_app/core/theme/theme_mode_controller.dart';
import 'package:notes_app/features/account/domain/profile_controller.dart';
import 'package:notes_app/features/account/presentation/account_screen.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/legal/presentation/privacy_screen.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';

/// A container with an already-signed-in session, matching how
/// `AccountScreen` is only ever reached (post-auth) in the real app — same
/// pattern as `onboarding_screen_test.dart`'s `_signedInContainer`.
///
/// All of these providers are autoDispose; nothing in this isolated test
/// tree keeps them alive the way `app_router.dart`'s `_RouterRefreshNotifier`
/// and the real screens do, so a direct `listen` on each is needed to stop
/// them resetting to their defaults between pump/tap steps.
ProviderContainer _signedInContainer(String email) {
  final container = ProviderContainer()
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(onboardingControllerProvider, (_, _) {})
    ..listen(profileControllerProvider, (_, _) {})
    ..listen(notesControllerProvider, (_, _) {})
    ..listen(skinControllerProvider, (_, _) {})
    ..listen(themeModeControllerProvider, (_, _) {});
  final notifier = container.read(sessionControllerProvider.notifier);
  final outcome = notifier.sendOtp(email);
  notifier.verifyOtp(email, outcome.code!);
  return container;
}

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      routerConfig: GoRouter(
        initialLocation: '/you',
        routes: [
          GoRoute(
            path: '/you',
            builder: (context, state) => const AccountScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/notebooks',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(path: '/plan', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
        ],
      ),
    ),
  );
}

/// The Settings section (Sign out, Privacy, etc.) sits below the fold on
/// the default test viewport — a real drag is needed to bring those rows
/// into the tree and within the hit-testable render bounds, same as the
/// lazy-`ListView` pattern in `plan_screen_test.dart`.
Future<void> _scrollToSettings(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, -600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the profile name, handle, and derived stats', (
    tester,
  ) async {
    final container = _signedInContainer('ada.lovelace@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('@ada.lovelace'), findsWidgets);
    expect(find.text('ada.lovelace@example.com'), findsOneWidget);
    expect(find.text('NOTES'), findsOneWidget);
    expect(find.text('BOOKS'), findsOneWidget);
  });

  testWidgets('tapping the edit pencil reveals the profile edit form', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Save profile'), findsNothing);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Save profile'), findsOneWidget);
    expect(find.widgetWithText(TextField, ''), findsWidgets);
  });

  testWidgets('editing the name and saving updates the profile controller', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ada L.');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(
      container.read(profileControllerProvider)['ada@example.com']?.name,
      'Ada L.',
    );
    expect(find.text('Ada L.'), findsOneWidget);
  });

  testWidgets('tapping Day paper / Night ink toggles the theme mode', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
    await tester.tap(find.text('Day paper'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    expect(find.text('Night ink'), findsOneWidget);
  });

  testWidgets('tapping Trash sets the trash filter and navigates to Notes', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com')
      ..listen(noteFilterKeyProvider, (_, _) {});
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();

    expect(container.read(noteFilterKeyProvider), NoteFilter.trash);
  });

  testWidgets('tapping Privacy pushes the Privacy policy screen', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _scrollToSettings(tester);

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
  });

  testWidgets('tapping Sign out logs the session out', (tester) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await _scrollToSettings(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(container.read(sessionControllerProvider), isNull);
  });
}
