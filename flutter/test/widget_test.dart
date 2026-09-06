import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/app.dart';

void main() {
  testWidgets('a fresh app boots straight to the auth screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NotesApp()));
    await tester.pumpAndSettle();

    // No session yet — app_router.dart's redirect guard sends a cold
    // start to /auth first, matching the source's own
    // `if (!session) return <AuthScreen/>` branch order in NotesApp.tsx.
    expect(find.text('Your notebook'), findsOneWidget);
    expect(find.text('Notes'), findsNothing);
  });
}
