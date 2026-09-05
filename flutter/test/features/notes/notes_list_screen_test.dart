import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
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
    ),
  );
}

void main() {
  testWidgets('renders the seeded notes without throwing', (tester) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Welcome to Notes'), findsOneWidget);
  });

  testWidgets('tapping the Archive chip narrows the list', (tester) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Notes'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Notes'), findsNothing);
    expect(find.text('Old draft'), findsOneWidget);
  });

  testWidgets('tapping a note card navigates to its detail route', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const NotesListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Welcome to Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsNothing);
  });
}
