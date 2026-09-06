import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/note_detail_screen.dart';
import 'package:notes_app/features/notes/presentation/note_editor_screen.dart';

late ProviderContainer _container;
late GoRouter _router;

/// A real "home" root (rather than starting directly on the detail route)
/// so `context.pop()` inside `NoteDetailScreen` — used by Close/Delete/
/// Delete-forever, exactly as it would be reached by pushing from the
/// notes list in the real app — has somewhere to go back to.
Widget _wrap() {
  _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Home'))),
      ),
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) =>
            NoteDetailScreen(noteId: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => NoteEditorScreen(
              noteId: int.parse(state.pathParameters['id']!),
            ),
          ),
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

Future<void> _openNote(WidgetTester tester, int id) async {
  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
  unawaited(_router.push('/notes/$id'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the note title, due chip, tag, and labels', (
    tester,
  ) async {
    await _openNote(tester, 3); // "Sprint planning notes"

    expect(find.text('Sprint planning notes'), findsOneWidget);
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
    // "Work" appears twice: the notebook-name header and the label chip.
    expect(find.text('Work'), findsNWidgets(2));
  });

  testWidgets('shows the empty-body placeholder when there is no body', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // `notesControllerProvider` is autoDispose; nothing watches it while
    // still on the Home stand-in, so a bare `.createBlank()` here could
    // get reset before NoteDetailScreen ever mounts to watch it itself.
    // A direct `listen` keeps it alive across that gap.
    final keepAlive = _container.listen(notesControllerProvider, (_, _) {});
    addTearDown(keepAlive.close);
    final blank = _container
        .read(notesControllerProvider.notifier)
        .createBlank();
    unawaited(_router.push('/notes/${blank.id}'));
    await tester.pumpAndSettle();

    expect(find.text('This note is still empty.'), findsOneWidget);
  });

  testWidgets('tapping Edit navigates to the note editor', (tester) async {
    await _openNote(tester, 1);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close editor'), findsOneWidget);
  });

  testWidgets('Delete moves the note to trash and closes', (tester) async {
    await _openNote(tester, 1);
    // Deleting also pops back to Home, which drops the last watcher of
    // this autoDispose provider — keep it alive so the mutation survives
    // long enough for this assertion to observe it.
    final keepAlive = _container.listen(notesControllerProvider, (_, _) {});
    addTearDown(keepAlive.close);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final note = _container
        .read(notesControllerProvider)
        .firstWhere((n) => n.id == 1);
    expect(note.trashedAt, isNotNull);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a trashed note shows Restore and Delete forever', (
    tester,
  ) async {
    await _openNote(tester, 8); // "Deleted scratch note", pre-trashed

    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Delete forever'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    final note = _container
        .read(notesControllerProvider)
        .firstWhere((n) => n.id == 8);
    expect(note.trashedAt, isNull);
  });
}
