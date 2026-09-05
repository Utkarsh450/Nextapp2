import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/app.dart';

void main() {
  testWidgets('app boots to the notes shell without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: NotesApp()));
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsWidgets);
  });
}
