import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/domain/search_history_controller.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';
import 'package:notes_app/features/notes/presentation/search_overlay_screen.dart';

late ProviderContainer _container;
late GoRouter _router;

/// Uses the real `NotesListScreen` as the `/notes` destination (rather
/// than a stub) so the shared filter/search providers stay alive across
/// navigation the same way they do in the real app.
Widget _wrap() {
  _router = GoRouter(
    initialLocation: '/notes',
    routes: [
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchOverlayScreen(),
          ),
          GoRoute(path: ':id', builder: (context, state) => const SizedBox()),
        ],
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: _container = ProviderContainer(),
    child: MaterialApp.router(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      routerConfig: _router,
    ),
  );
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  unawaited(_router.push('/notes/search'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing shows matching notes under Matches', (tester) async {
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'Piranesi');
    await tester.pumpAndSettle();

    expect(find.text('MATCHES'), findsOneWidget);
    expect(find.text('Book recs from Priya'), findsOneWidget);
  });

  testWidgets('typing with no matches shows the empty message', (tester) async {
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'zzzznothingzzzz');
    await tester.pumpAndSettle();

    expect(find.text('No notes match that search.'), findsOneWidget);
  });

  testWidgets('typing live-filters the shared search query provider', (
    tester,
  ) async {
    await _openSearch(tester);

    await tester.enterText(find.byType(TextField), 'Piranesi');
    await tester.pumpAndSettle();

    expect(_container.read(noteSearchQueryProvider), 'Piranesi');
  });

  testWidgets('picking a color sets the color filter and closes search', (
    tester,
  ) async {
    await _openSearch(tester);

    final color = NoteSwatches.paletteHex.first;
    await tester.tap(find.byKey(ValueKey('search-color-$color')));
    await tester.pumpAndSettle();

    expect(_container.read(noteColorFilterProvider), color);
    expect(_container.read(noteFilterKeyProvider), NoteFilter.all);
    expect(find.text('MATCHES'), findsNothing); // back on the notes list
  });

  testWidgets('picking a label sets the label filter and closes search', (
    tester,
  ) async {
    await _openSearch(tester);

    await tester.tap(find.text('Ideas'));
    await tester.pumpAndSettle();

    expect(_container.read(noteLabelFilterProvider), 'Ideas');
  });

  testWidgets('submitting a query remembers it as a recent', (tester) async {
    await _openSearch(tester);
    // Submitting pops the search screen, dropping its own watch on this
    // autoDispose provider — keep it alive so the write survives long
    // enough for this assertion.
    final keepAlive = _container.listen(
      searchHistoryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);

    await tester.enterText(find.byType(TextField), 'daily');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_container.read(searchHistoryControllerProvider), ['daily']);
  });

  testWidgets('tapping a recent re-applies it and closes search', (
    tester,
  ) async {
    await _openSearch(tester);
    // `searchHistoryControllerProvider` is autoDispose and only
    // `SearchOverlayScreen` itself watches it; popping search below (to
    // re-push it and pick up the seeded history) drops that watch, so
    // without this the 'groceries' entry could be gone by the time the
    // screen remounts.
    final keepAlive = _container.listen(
      searchHistoryControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    _container
        .read(searchHistoryControllerProvider.notifier)
        .remember('groceries');
    // Re-open on a fresh push so the Recent section reflects the seeded
    // history (the widget read its initial value once, in initState).
    _router.pop();
    await tester.pumpAndSettle();
    unawaited(_router.push('/notes/search'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('groceries'));
    await tester.pumpAndSettle();

    expect(_container.read(noteSearchQueryProvider), 'groceries');
  });
}
