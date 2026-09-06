import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/router/app_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';

/// Exercises the real custom dock (`shell/app_dock.dart`) through the full
/// `appRouterProvider` — the same "sign in, finish onboarding, land on the
/// shell" pattern as `app_router_test.dart`, since the dock only exists
/// wrapped around a real `StatefulNavigationShell`.
Future<ProviderContainer> _signedInShell(WidgetTester tester) async {
  final container = ProviderContainer();
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
  return container;
}

void main() {
  testWidgets('tapping a dock tab switches branches', (tester) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);

    await tester.tap(find.text('Books'));
    await tester.pumpAndSettle();
    expect(find.text('New notebook'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    // The habit tracker sits above the agenda in a lazy `ListView`, same
    // as `plan_screen_test.dart`'s `_scrollToAgenda` — a real drag is
    // needed to bring "What's next" into the tree at all.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('What’s next'), findsOneWidget);
  });

  testWidgets('the Plan tab shows a due-today dot, matching the seeded notes', (
    tester,
  ) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);

    // sampleNotes() always seeds a couple of due-today notes, so the dot
    // is on by default; trashing them clears it.
    final ids = container
        .read(notesControllerProvider)
        .where((n) => n.dueAt != null)
        .map((n) => n.id)
        .toList();
    expect(find.byKey(const Key('plan-alert-dot')), findsOneWidget);

    ids.forEach(container.read(notesControllerProvider.notifier).moveToTrash);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-alert-dot')), findsNothing);
  });

  testWidgets('tapping + opens the Add menu with all seven actions', (
    tester,
  ) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add...'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(find.text('Daily log'), findsOneWidget);
    expect(find.text('Idea'), findsOneWidget);
    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
    expect(find.text('Quick capture'), findsOneWidget);
  });

  testWidgets('tapping the backdrop closes the Add menu', (tester) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Add...'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Add...'), findsNothing);
  });

  testWidgets('picking Note creates a blank note and opens its editor', (
    tester,
  ) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);
    final countBefore = container.read(notesControllerProvider).length;

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close editor'), findsOneWidget);
    expect(container.read(notesControllerProvider).length, countBefore + 1);
  });

  testWidgets('picking Reminder creates a note due today', (tester) async {
    final container = await _signedInShell(tester);
    addTearDown(container.dispose);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reminder'));
    await tester.pumpAndSettle();

    final created = container
        .read(notesControllerProvider)
        .reduce((a, b) => a.createdAt > b.createdAt ? a : b);
    expect(created.dueAt, isNotNull);
  });

  testWidgets(
    'long-pressing + opens Quick capture directly, bypassing the Add menu',
    (tester) async {
      final container = await _signedInShell(tester);
      addTearDown(container.dispose);

      await tester.longPress(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('QUICK CAPTURE'), findsOneWidget);
      expect(find.text('Add...'), findsNothing);
    },
  );
}
