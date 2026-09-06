import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/habits/domain/habits_controller.dart';
import 'package:notes_app/features/habits/presentation/habits_board.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(
        skin: PaperSkin.classic,
        brightness: Brightness.light,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('shows suggested habits when the list is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const HabitsBoard()));
    await tester.pumpAndSettle();

    expect(find.text('The paper is still blank'), findsOneWidget);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });

  testWidgets('tapping a suggestion adds it to the list', (tester) async {
    await tester.pumpWidget(_wrap(const HabitsBoard()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();

    // Adding a habit doesn't check off a day, so the "still blank" status
    // is legitimately unchanged (matches the source: that line reflects
    // check-ins, not habit count) — instead, the whole suggestions row
    // (shown only while there are zero habits) should be gone now.
    expect(find.text('Move'), findsNothing);
    expect(find.text('Read'), findsNothing);
  });

  testWidgets('adding a habit through the composer works', (tester) async {
    late final ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: buildAppTheme(
                skin: PaperSkin.classic,
                brightness: Brightness.light,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(child: HabitsBoard()),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a habit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Meditate');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      container.read(habitsControllerProvider).map((h) => h.name),
      contains('Meditate'),
    );
  });
}
