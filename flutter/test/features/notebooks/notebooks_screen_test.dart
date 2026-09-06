import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notebooks/presentation/notebooks_screen.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';

Widget _wrap([void Function(ProviderContainer)? onContainer]) {
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
            initialLocation: '/notebooks',
            routes: [
              GoRoute(
                path: '/notebooks',
                builder: (context, state) => const NotebooksScreen(),
              ),
              // The real screen (rather than a stub) so the providers
              // `onOpen` sets stay alive after navigation — they're
              // autoDispose, and nothing else would be watching them once
              // NotebooksScreen itself is torn down.
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesListScreen(),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('shows the seeded notebooks with live note counts', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('3 notes'), findsOneWidget);
    expect(find.text('1 note'), findsOneWidget);
    expect(find.text('2 notes'), findsOneWidget);
    expect(find.text('New notebook'), findsOneWidget);
  });

  testWidgets('composing a new notebook adds it to the grid', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New notebook'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Travel');
    await tester.tap(find.text('Make notebook'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('0 notes'), findsOneWidget);
  });

  testWidgets('the pencil button renames a notebook in place', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Rename Work'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Job');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Job'), findsOneWidget);
    expect(find.text('Work'), findsNothing);
  });

  testWidgets('tapping a notebook filters the Notes tab by it', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap((c) => container = c));
    await tester.pumpAndSettle();

    // Both providers are autoDispose; NotebooksScreen unmounting on
    // navigation can otherwise drop them to zero listeners before this
    // assertion runs, resetting them back to their defaults. A direct
    // `listen` keeps them alive for the rest of the test, same as any
    // real screen watching them would.
    final keepNotebookAlive = container.listen(
      noteNotebookFilterProvider,
      (_, _) {},
    );
    final keepFilterAlive = container.listen(noteFilterKeyProvider, (_, _) {});
    addTearDown(keepNotebookAlive.close);
    addTearDown(keepFilterAlive.close);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(container.read(noteNotebookFilterProvider), 'home');
    expect(container.read(noteFilterKeyProvider), NoteFilter.all);
  });
}
