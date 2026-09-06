import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/theme/app_theme.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/features/notes/presentation/today_dashboard.dart';

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
  testWidgets('shows the greeting and progress card from seeded notes', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TodayDashboard()));
    await tester.pumpAndSettle();

    expect(find.textContaining('there'), findsOneWidget);
    expect(find.text('Your progress'), findsOneWidget);
    // Two seeded notes (`Sprint planning notes`, `Renew passport`) are due
    // today, so the "Due with you" card should show.
    expect(find.text('Due with you'), findsOneWidget);
  });

  // Tapping the notebook tiles / metric chips changes filter state that
  // lives on providers `NotesListScreen` watches to gate the dashboard
  // itself (`showTodayDashboardProvider`) — those interactions are
  // covered end-to-end in `notes_list_screen_test.dart`, where that
  // parent screen keeps the providers alive. In isolation here, nothing
  // watches them, so Riverpod's autoDispose would reset the state right
  // back before an assertion could observe it.
}
