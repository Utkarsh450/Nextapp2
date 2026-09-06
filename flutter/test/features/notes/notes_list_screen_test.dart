import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';

Widget _wrap(Widget child, [void Function(ProviderContainer)? onContainer]) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        onContainer?.call(ProviderScope.containerOf(context));
        return MaterialApp.router(
          theme: buildAppTheme(
            skin: PaperSkin.classic,
            brightness: Brightness.light,
          ),
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(path: '/', builder: (context, state) => child),
              GoRoute(
                path: '/notes/:id',
                builder: (context, state) => const SizedBox(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders the Today dashboard above the notes list', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    // The default filter (`all`, no notebook/label/color) shows the Today
    // dashboard first — see `showTodayDashboardProvider` — so the seeded
    // notes are further down the same scroll view, not on first paint.
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Your progress'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Welcome to Notes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Welcome to Notes'), findsOneWidget);
  });

  testWidgets('tapping the Archive chip narrows the list', (tester) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Archive'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    // Filtering away from `all` hides Today, so the archived note is now
    // right at the top of the scroll view.
    expect(find.text('Welcome to Notes'), findsNothing);
    expect(find.text('Old draft'), findsOneWidget);
  });

  testWidgets('tapping a note card navigates to its detail route', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Welcome to Notes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Welcome to Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsNothing);
  });

  testWidgets('tapping a Today notebook tile filters the list by it', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      _wrap(const NotesListScreen(), (c) => container = c),
    );
    await tester.pumpAndSettle();

    // "Work" sits inside the Today dashboard's single SliverToBoxAdapter,
    // which (unlike the lazily-built notes grid below it) is built in
    // full up front — `scrollUntilVisible` sees it immediately and skips
    // dragging, leaving it off-screen. A direct drag brings it into the
    // viewport for real before tapping.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    // A tag chip reading "work" on a couple of seeded notes collides with
    // `find.text('Work')` once the grid below scrolls into the cache
    // extent, so target the tile by its stable key instead.
    await tester.tap(find.byKey(const ValueKey('notebook-tile-work')));
    await tester.pumpAndSettle();

    expect(container.read(noteNotebookFilterProvider), 'work');
    // Notebook tiles also clear back to the `all` filter, matching
    // `onNotebook` in the source's `TodayBoard.tsx`.
    expect(container.read(noteFilterKeyProvider), NoteFilter.all);
    expect(find.text('Sprint planning notes'), findsOneWidget);
    expect(find.text('Renew passport'), findsNothing);
  });

  testWidgets("tapping Today's log opens today's daily-log note", (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      _wrap(const NotesListScreen(), (c) => container = c),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Today's log"));
    await tester.pumpAndSettle();

    // Navigated away from the notes list into the (stubbed) editor route.
    expect(find.text('Notes'), findsNothing);
    expect(
      container.read(notesControllerProvider).any((n) => n.tag == 'Daily'),
      isTrue,
    );
  });

  testWidgets('tapping the Today "Due today" chip switches the filter', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      _wrap(const NotesListScreen(), (c) => container = c),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Due today'));
    await tester.pumpAndSettle();

    expect(container.read(noteFilterKeyProvider), NoteFilter.due);
  });
}
