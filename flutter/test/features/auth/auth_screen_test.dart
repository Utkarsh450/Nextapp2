import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/auth/presentation/auth_screen.dart';

Widget _wrap([void Function(ProviderContainer)? onContainer]) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        onContainer?.call(ProviderScope.containerOf(context));
        return MaterialApp(
          theme: buildAppTheme(
            skin: PaperSkin.classic,
            brightness: Brightness.light,
          ),
          home: const AuthScreen(),
        );
      },
    ),
  );
}

/// Pulls the generated code back out of the on-screen hint bubble
/// (`Text.rich`, the only rich-text `Text` on this screen) rather than
/// re-deriving it — this is what a user would actually read off the
/// screen to type back in.
String _shownCode(WidgetTester tester) {
  final richText = tester
      .widgetList<Text>(find.byType(Text))
      .firstWhere((t) => t.textSpan != null)
      .textSpan!;
  return RegExp(r'\d{6}$').firstMatch(richText.toPlainText())!.group(0)!;
}

void main() {
  testWidgets('shows the email form first', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Your notebook'), findsOneWidget);
    expect(find.text('Send me a code'), findsOneWidget);
    expect(find.text('Enter the code'), findsNothing);
  });

  testWidgets('sending a code switches to the OTP step and shows the code', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ada@example.com');
    await tester.tap(find.text('Send me a code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.textContaining('here is your code'), findsOneWidget);
  });

  testWidgets('the wrong code shows an error and does not sign in', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap((c) => container = c));
    await tester.pumpAndSettle();
    // `sessionControllerProvider` is autoDispose; in the real app,
    // app_router.dart's `_RouterRefreshNotifier` keeps it alive for the
    // whole app lifetime via `ref.listen`. Nothing here does that, so the
    // pending code from `sendOtp` could otherwise be gone (silently
    // resetting to "no record" / "Code expired") by the time this test's
    // separate `verifyOtp` tap runs a few frames later.
    final keepAlive = container.listen(sessionControllerProvider, (_, _) {});
    addTearDown(keepAlive.close);

    await tester.enterText(find.byType(TextField), 'ada@example.com');
    await tester.tap(find.text('Send me a code'));
    await tester.pumpAndSettle();

    final correct = _shownCode(tester);
    final wrong = correct == '000001' ? '000002' : '000001';
    await tester.enterText(find.byType(TextField).first, wrong);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my board'));
    await tester.pumpAndSettle();

    expect(find.text('That code is incorrect'), findsOneWidget);
    expect(container.read(sessionControllerProvider), isNull);
  });

  testWidgets('the correct code signs the user in', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap((c) => container = c));
    await tester.pumpAndSettle();
    // Keep the autoDispose session provider alive across this test in
    // isolation — there's nothing else here watching it the way the real
    // app's router redirect does.
    final keepAlive = container.listen(sessionControllerProvider, (_, _) {});
    addTearDown(keepAlive.close);

    await tester.enterText(find.byType(TextField), 'ada@example.com');
    await tester.tap(find.text('Send me a code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, _shownCode(tester));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open my board'));
    await tester.pumpAndSettle();

    expect(container.read(sessionControllerProvider)?.email, 'ada@example.com');
  });
}
