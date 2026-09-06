import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/plan/presentation/plan_screen.dart';

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp.router(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const PlanScreen()),
          GoRoute(
            path: '/notes/:id',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      ),
    ),
  );
}

/// The habit tracker above the agenda section is tall enough that, on the
/// default test viewport, the agenda sits beyond `ListView`'s lazy build
/// cache extent — a real drag is needed to bring it into the tree at all,
/// not just into view.
Future<void> _scrollToAgenda(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable), const Offset(0, -800));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the seeded due-today notes under Due today', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _scrollToAgenda(tester);

    // Sample notes "Sprint planning notes" and "Renew passport" are both
    // seeded with today's due date — "Due today" appears both as the
    // section label and as each row's own due-chip subtitle.
    expect(find.text('What’s next'), findsOneWidget);
    expect(find.text('Due today'), findsWidgets);
    expect(find.text('Sprint planning notes'), findsOneWidget);
    expect(find.text('Renew passport'), findsOneWidget);
    expect(find.text('Clear for now'), findsNothing);
  });

  testWidgets('shows "Clear for now" when nothing is waiting', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(
              theme: buildAppTheme(
                skin: PaperSkin.classic,
                brightness: Brightness.light,
              ),
              routerConfig: GoRouter(
                initialLocation: '/',
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const PlanScreen(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    // Clear every seeded note's due date and checklist before the first
    // frame settles, so the agenda genuinely starts empty.
    final notifier = container.read(notesControllerProvider.notifier);
    for (final note in container.read(notesControllerProvider)) {
      notifier.moveToTrash(note.id);
    }
    await tester.pumpAndSettle();
    await _scrollToAgenda(tester);

    expect(find.text('Clear for now'), findsOneWidget);
  });

  testWidgets('tapping an agenda row opens that note', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _scrollToAgenda(tester);

    await tester.tap(find.text('Sprint planning notes'));
    await tester.pumpAndSettle();

    expect(find.text('Plan'), findsNothing);
  });
}
