import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/note_editor_screen.dart';

late ProviderContainer _lastContainer;

Widget _wrap(int noteId) {
  return UncontrolledProviderScope(
    container: _lastContainer = ProviderContainer(),
    child: MaterialApp.router(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      routerConfig: GoRouter(
        initialLocation: '/notes/$noteId/edit',
        routes: [
          GoRoute(
            path: '/notes/:id',
            builder: (context, state) => const SizedBox(),
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
      ),
    ),
  );
}

void main() {
  testWidgets('shows the note being edited', (tester) async {
    await tester.pumpWidget(_wrap(1));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Notes'), findsOneWidget);
  });

  testWidgets('editing the title saves through the controller', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(1));
    await tester.pumpAndSettle();

    await tester.enterText(find.text('Welcome to Notes'), 'Renamed note');
    await tester.pumpAndSettle();

    final notes = _lastContainer.read(notesControllerProvider);
    expect(notes.firstWhere((n) => n.id == 1).title, 'Renamed note');
  });

  testWidgets('the mark-done tick toggles confirmed', (tester) async {
    await tester.pumpWidget(_wrap(1));
    await tester.pumpAndSettle();

    final before = _lastContainer
        .read(notesControllerProvider)
        .firstWhere((n) => n.id == 1)
        .confirmed;

    await tester.tap(find.bySemanticsLabel('Mark as done'));
    await tester.pumpAndSettle();

    final after = _lastContainer
        .read(notesControllerProvider)
        .firstWhere((n) => n.id == 1)
        .confirmed;
    expect(after, !before);
  });

  testWidgets('closing the editor does not throw', (tester) async {
    await tester.pumpWidget(_wrap(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Close editor'));
    await tester.pumpAndSettle();
  });
}
