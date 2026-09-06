import 'package:notes_app/features/habits/domain/habit.dart';
import 'package:notes_app/features/habits/domain/habit_heatmap.dart'
    as heatmap;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habits_controller.g.dart';

/// Holds the habit list. **In-memory only**, per the "no backend/DB for
/// now" instruction — and, unlike `NotesController`, starts genuinely
/// empty rather than from placeholder demo data: the source has no habit
/// equivalent of `lib/notes/seed.ts`, so an empty list *is* what a fresh
/// account looks like (the suggested-habit chips exist for exactly this
/// state — see `habits_board.dart`).
@riverpod
class HabitsController extends _$HabitsController {
  static const _ownerEmail = 'you@notes.dev';

  @override
  List<Habit> build() => const [];

  /// `addHabit` — matches `hooks/useHabits.ts`.
  Habit addHabit(String name, {String? color}) {
    final habit = heatmap.createHabit(_ownerEmail, name, color: color);
    state = [...state, habit];
    return habit;
  }

  /// `removeHabit` — also drops every check-in for [id], matching the
  /// source's `removeHabit` (which clears both `habits` and `checks`
  /// state together).
  void removeHabit(String id) {
    state = [
      for (final habit in state) if (habit.id != id) habit,
    ];
    ref.read(habitChecksControllerProvider.notifier).removeForHabit(id);
  }
}

/// Holds every habit check-in. Split from [HabitsController] the same way
/// the source splits `habits`/`checks` in `useHabits.ts`.
@riverpod
class HabitChecksController extends _$HabitChecksController {
  static const _ownerEmail = 'you@notes.dev';

  @override
  List<HabitCheck> build() => const [];

  /// `toggleCheck`. The `date > today` guard lives in the widget (matching
  /// the source: `HabitsBoard.tsx`'s own `toggle()` wrapper checks it, not
  /// the hook), so this stays a direct, unconditional toggle.
  void toggleCheck(String habitId, String date) {
    final result = heatmap.toggleHabitCheck(
      state,
      _ownerEmail,
      habitId,
      date,
    );
    state = result.checks;
  }

  /// Called by [HabitsController.removeHabit] to keep the two lists
  /// consistent — not part of the source's public `useHabits` API (there
  /// it's inlined in `removeHabit`), but the split needs a seam somewhere.
  void removeForHabit(String habitId) {
    state = [
      for (final check in state) if (check.habitId != habitId) check,
    ];
  }
}
