import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/create_sheet.dart';

Widget _wrap(void Function(ProviderContainer) onContainer) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        onContainer(ProviderScope.containerOf(context));
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
                builder: (context, state) => Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showCreateSheet(context),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/notes/:id',
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Editor'))),
                  ),
                ],
                builder: (context, state) => const SizedBox(),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('Save note creates a note with the typed title and body', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap((c) => container = c));
    // `notesControllerProvider` is autoDispose and nothing on this bare
    // test screen watches it — keep it alive so the created note survives
    // navigating to the (also non-watching) editor stub for the assertion.
    final keepAlive = container.listen(notesControllerProvider, (_, _) {});
    addTearDown(keepAlive.close);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Title'),
      'Grocery run',
    );
    await tester.enterText(find.byType(TextField).last, 'Milk, eggs, bread');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(find.text('Editor'), findsOneWidget);
    final notes = container.read(notesControllerProvider);
    expect(
      notes.any(
        (n) => n.title == 'Grocery run' && n.body == 'Milk, eggs, bread',
      ),
      isTrue,
    );
  });

  testWidgets(
    'picking a template chip discards typed text and uses the template',
    (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(_wrap((c) => container = c));
      final keepAlive = container.listen(notesControllerProvider, (_, _) {});
      addTearDown(keepAlive.close);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Scratch title',
      );
      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();

      expect(find.text('Editor'), findsOneWidget);
      final notes = container.read(notesControllerProvider);
      expect(notes.any((n) => n.title == 'Scratch title'), isFalse);
      expect(notes.any((n) => n.title == 'Meeting notes'), isTrue);
    },
  );

  testWidgets('the close button dismisses the sheet without creating a note', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap((c) => container = c));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final countBefore = container.read(notesControllerProvider).length;

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('QUICK CAPTURE'), findsNothing);
    expect(container.read(notesControllerProvider).length, countBefore);
  });
}
