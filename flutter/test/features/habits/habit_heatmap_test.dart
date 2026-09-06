import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/habits/domain/habit.dart';
import 'package:notes_app/features/habits/domain/habit_heatmap.dart';

HabitCheck _check(String habitId, String date) =>
    HabitCheck(ownerEmail: 'you@notes.dev', habitId: habitId, date: date);

void main() {
  group('currentStreak', () {
    test('counts consecutive days ending today', () {
      final dates = ['2024-01-01', '2024-01-02', '2024-01-03'];
      expect(currentStreak(dates, '2024-01-03'), 3);
    });

    test('still counts a streak that ended yesterday', () {
      final dates = ['2024-01-01', '2024-01-02'];
      expect(currentStreak(dates, '2024-01-03'), 2);
    });

    test('is broken by a gap', () {
      final dates = ['2024-01-01', '2024-01-03'];
      expect(currentStreak(dates, '2024-01-03'), 1);
    });

    test('is zero with no check-ins', () {
      expect(currentStreak(const [], '2024-01-03'), 0);
    });
  });

  group('bestStreak', () {
    test('finds the longest run even if it is not the most recent', () {
      final dates = [
        '2024-01-01',
        '2024-01-02',
        '2024-01-03',
        '2024-01-10',
      ];
      expect(bestStreak(dates), 3);
    });

    test('is zero for an empty list', () {
      expect(bestStreak(const []), 0);
    });
  });

  group('heatLevel', () {
    test('is 0 for no activity', () {
      expect(heatLevel(0, 5), 0);
    });

    test('is 3 when max is 1 and count is positive', () {
      expect(heatLevel(1, 1), 3);
    });

    test('buckets proportionally otherwise', () {
      expect(heatLevel(1, 4), 1); // 0.25
      expect(heatLevel(2, 4), 2); // 0.5
      expect(heatLevel(3, 4), 3); // 0.75
      expect(heatLevel(4, 4), 4); // 1.0
    });
  });

  group('buildHeatmap', () {
    test("has 18 weeks of 7 days, ending on the Sunday of today's week", () {
      final grid = buildHeatmap(const [], '2024-01-10'); // a Wednesday
      expect(grid.length, heatmapWeeksCount);
      for (final week in grid) {
        expect(week.length, 7);
      }
      expect(grid.last.last.date, '2024-01-14'); // that week's Sunday
    });

    test('marks dates after today as future', () {
      final grid = buildHeatmap(const [], '2024-01-10');
      final lastWeek = grid.last;
      final future = lastWeek.where((d) => d.date.compareTo('2024-01-10') > 0);
      expect(future.every((d) => d.future), isTrue);
      final notFuture = lastWeek.where(
        (d) => d.date.compareTo('2024-01-10') <= 0,
      );
      expect(notFuture.every((d) => !d.future), isTrue);
    });

    test('filters counts by habitId when given', () {
      final checks = [
        _check('a', '2024-01-10'),
        _check('b', '2024-01-10'),
      ];
      final grid = buildHeatmap(checks, '2024-01-10', habitId: 'a');
      final today = grid.last.firstWhere((d) => d.date == '2024-01-10');
      expect(today.count, 1);
    });
  });

  group('toggleHabitCheck', () {
    test('adds a check when none exists', () {
      final result = toggleHabitCheck(
        const [],
        'You@Notes.dev',
        'a',
        '2024-01-10',
      );
      expect(result.added, isTrue);
      expect(result.checks, hasLength(1));
      expect(result.checks.first.ownerEmail, 'you@notes.dev');
    });

    test('removes an existing check', () {
      final existing = [_check('a', '2024-01-10')];
      final result = toggleHabitCheck(
        existing,
        'you@notes.dev',
        'a',
        '2024-01-10',
      );
      expect(result.added, isFalse);
      expect(result.checks, isEmpty);
    });
  });

  group('createHabit', () {
    test('falls back to "Habit" for a blank name', () {
      expect(createHabit('you@notes.dev', '   ').name, 'Habit');
    });

    test('keeps an explicit preset color', () {
      final habit = createHabit(
        'you@notes.dev',
        'Read',
        color: '#E7A3A3',
        now: 123,
      );
      expect(habit.color, '#E7A3A3');
      expect(habit.id, 'hab-read-123');
    });
  });
}
