import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/legal/presentation/privacy_screen.dart';

Widget _wrap() {
  return MaterialApp.router(
    theme: buildAppTheme(skin: PaperSkin.classic, brightness: Brightness.light),
    routerConfig: GoRouter(
      initialLocation: '/privacy',
      routes: [
        GoRoute(
          path: '/privacy',
          builder: (context, state) => const PrivacyScreen(),
          routes: [
            GoRoute(
              path: 'inner',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('shows the headline and last-updated date', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Last updated 2 September 2026'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Back to Notes'), findsOneWidget);
  });
}
