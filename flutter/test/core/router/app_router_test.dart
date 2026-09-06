import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/router/app_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';

/// Exercises the real `appRouterProvider` end to end — the redirect guard
/// (`_RouterRefreshNotifier` + the `redirect` callback in app_router.dart)
/// is the one piece of this feature that unit tests on the individual
/// screens/controllers can't cover on their own.
void main() {
  testWidgets('a fresh session is redirected to /auth', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: buildAppTheme(
              skin: PaperSkin.classic,
              brightness: Brightness.light,
            ),
            routerConfig: ref.watch(appRouterProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your notebook'), findsOneWidget);
  });

  testWidgets(
    'signing in without onboarding redirects to /onboarding, then /notes '
    'once onboarding finishes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: buildAppTheme(
                skin: PaperSkin.classic,
                brightness: Brightness.light,
              ),
              routerConfig: ref.watch(appRouterProvider),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notifier = container.read(sessionControllerProvider.notifier);
      final outcome = notifier.sendOtp('ada@example.com');
      notifier.verifyOtp('ada@example.com', outcome.code!);
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);

      container
          .read(onboardingControllerProvider.notifier)
          .markDone('ada@example.com');
      await tester.pumpAndSettle();

      expect(find.text('Notes'), findsWidgets);
    },
  );

  testWidgets('logging out sends an already-onboarded session back to /auth', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: buildAppTheme(
              skin: PaperSkin.classic,
              brightness: Brightness.light,
            ),
            routerConfig: ref.watch(appRouterProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final notifier = container.read(sessionControllerProvider.notifier);
    final outcome = notifier.sendOtp('ada@example.com');
    notifier.verifyOtp('ada@example.com', outcome.code!);
    container
        .read(onboardingControllerProvider.notifier)
        .markDone('ada@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Notes'), findsWidgets);

    notifier.logout();
    await tester.pumpAndSettle();

    expect(find.text('Your notebook'), findsOneWidget);
  });
}
