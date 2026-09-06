import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';
import 'package:notes_app/features/account/domain/profile_controller.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/auth/presentation/onboarding_screen.dart';

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      home: const OnboardingScreen(),
    ),
  );
}

/// A container with an already-signed-in session — `OnboardingScreen`
/// reads `sessionControllerProvider` (non-nullably) for the current email,
/// matching how it's only ever reached (post-auth) in the real app.
///
/// `sessionControllerProvider` is autoDispose; in the real app,
/// `app_router.dart`'s `_RouterRefreshNotifier` keeps it alive for the
/// whole app lifetime via `ref.listen`. `OnboardingScreen` itself never
/// watches it (only one-off `ref.read`s), so without an equivalent
/// keep-alive here, the session could be silently reset to `null` between
/// this test's own separate pump/tap steps.
ProviderContainer _signedInContainer(String email) {
  // Same autoDispose reasoning for all three: nothing in this isolated
  // test tree watches them the way the real app incidentally does.
  final container = ProviderContainer()
    ..listen(sessionControllerProvider, (_, _) {})
    ..listen(onboardingControllerProvider, (_, _) {})
    ..listen(profileControllerProvider, (_, _) {});
  final notifier = container.read(sessionControllerProvider.notifier);
  final outcome = notifier.sendOtp(email);
  notifier.verifyOtp(email, outcome.code!);
  return container;
}

void main() {
  testWidgets('starts on the name step, prefilled from the email', (
    tester,
  ) async {
    final container = _signedInContainer('ada.lovelace@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('Continue moves to the skin step', (tester) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Pick your paper'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Monsoon'), findsOneWidget);
    expect(find.text('Festival'), findsOneWidget);
  });

  testWidgets('picking a skin updates SkinController', (tester) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monsoon'));
    await tester.pumpAndSettle();

    expect(container.read(skinControllerProvider), PaperSkin.monsoon);
  });

  testWidgets('Start writing saves the name and marks onboarding done', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ada L.');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start writing'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(onboardingControllerProvider.notifier)
          .isDone('ada@example.com'),
      isTrue,
    );
    expect(
      container
          .read(profileControllerProvider.notifier)
          .profileFor('ada@example.com')
          .name,
      'Ada L.',
    );
  });

  testWidgets('Skip for now on the name step finishes without a typed name', (
    tester,
  ) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(
      container
          .read(onboardingControllerProvider.notifier)
          .isDone('ada@example.com'),
      isTrue,
    );
  });

  testWidgets('Back on the skin step returns to the name step', (tester) async {
    final container = _signedInContainer('ada@example.com');
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
  });
}
