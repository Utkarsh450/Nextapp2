/// Direct port of `lib/notes/habits.ts` — the heatmap/streak math behind
/// the habit tracker.
library;

import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/habits/domain/habit.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart' show slugify;

const int heatmapWeeksCount = 18;

/// The three starter chips shown when a fresh account has no habits yet —
/// matches `SUGGESTED_HABITS`.
class const SuggestedHabit({
  required final String name,
  required final String color,
});

const List<SuggestedHabit> suggestedHabits = [
  SuggestedHabit(name: 'Write', color: '#C5CA8A'),
  SuggestedHabit(name: 'Move', color: '#E7A3A3'),
  SuggestedHabit(name: 'Read', color: '#D4C4E8'),
];

/// One cell in the heatmap grid.
class const HeatDay({
  required final String date,
  required final int count,
  required final int level,
  required final bool future,
});

bool _isPaperColor(String color) => NoteSwatches.paletteHex.contains(color);

/// Matches `createHabit` — falls back to a deterministic palette color
/// (keyed by [now]) when [color] isn't one of the 7 presets.
Habit createHabit(
  String ownerEmail,
  String name, {
  String? color,
  int? now,
}) {
  final at = now ?? DateTime.now().millisecondsSinceEpoch;
  final resolvedColor = color != null && _isPaperColor(color)
      ? color
      : NoteSwatches.paletteHex[at % NoteSwatches.paletteHex.length];
  return Habit(
    id: 'hab-${slugify(name)}-$at',
    ownerEmail: ownerEmail.trim().toLowerCase(),
    name: name.trim().isEmpty ? 'Habit' : name.trim(),
    color: resolvedColor,
    createdAt: at,
  );
}

/// Monday=0 … Sunday=6 — matches `mondayIndex`.
int mondayIndex(String iso) {
  final parts = iso.split('-').map(int.parse).toList();
  // Mon=1..Sun=7
  final weekday = DateTime(parts[0], parts[1], parts[2]).weekday;
  return (weekday + 6) % 7;
}

String weekEndSunday(String iso) => shiftIso(iso, 6 - mondayIndex(iso));

/// [weekCount] columns of 7 ISO dates each, ending on the Sunday of
/// [today]'s week — matches `heatmapWeeks`.
List<List<String>> heatmapWeeks(
  String today, [
  int weekCount = heatmapWeeksCount,
]) {
  final last = weekEndSunday(today);
  final first = shiftIso(last, -(weekCount * 7 - 1));
  return List.generate(
    weekCount,
    (week) => List.generate(7, (day) => shiftIso(first, week * 7 + day)),
  );
}

int heatLevel(int count, int max) {
  if (count <= 0 || max <= 0) return 0;
  if (max == 1) return 3;
  final t = count / max;
  if (t <= 0.25) return 1;
  if (t <= 0.5) return 2;
  if (t <= 0.75) return 3;
  return 4;
}

Map<String, int> countsByDate(List<HabitCheck> checks, [String? habitId]) {
  final map = <String, int>{};
  for (final check in checks) {
    if (habitId != null && check.habitId != habitId) continue;
    map[check.date] = (map[check.date] ?? 0) + 1;
  }
  return map;
}

List<String> datesWithChecks(List<HabitCheck> checks, [String? habitId]) {
  final dates = <String>{};
  for (final check in checks) {
    if (habitId != null && check.habitId != habitId) continue;
    dates.add(check.date);
  }
  return dates.toList()..sort();
}

int currentStreak(List<String> dates, String today) {
  final set = dates.toSet();
  var cursor = set.contains(today) ? today : shiftIso(today, -1);
  if (!set.contains(cursor)) return 0;
  var streak = 0;
  while (set.contains(cursor)) {
    streak += 1;
    cursor = shiftIso(cursor, -1);
  }
  return streak;
}

int bestStreak(List<String> dates) {
  final sorted = dates.toSet().toList()..sort();
  if (sorted.isEmpty) return 0;
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    if (shiftIso(sorted[i - 1], 1) == sorted[i]) {
      run += 1;
    } else {
      run = 1;
    }
    if (run > best) best = run;
  }
  return best;
}

bool hasCheck(List<HabitCheck> checks, String habitId, String date) =>
    checks.any((c) => c.habitId == habitId && c.date == date);

class const ToggleHabitCheckResult({
  required final List<HabitCheck> checks,
  required final bool added,
});

ToggleHabitCheckResult toggleHabitCheck(
  List<HabitCheck> checks,
  String ownerEmail,
  String habitId,
  String date,
) {
  final email = ownerEmail.trim().toLowerCase();
  if (hasCheck(checks, habitId, date)) {
    return ToggleHabitCheckResult(
      checks: checks
          .where((c) => !(c.habitId == habitId && c.date == date))
          .toList(),
      added: false,
    );
  }
  return ToggleHabitCheckResult(
    checks: [
      ...checks,
      HabitCheck(ownerEmail: email, habitId: habitId, date: date),
    ],
    added: true,
  );
}

List<List<HeatDay>> buildHeatmap(
  List<HabitCheck> checks,
  String today, {
  String? habitId,
  int weekCount = heatmapWeeksCount,
}) {
  final counts = countsByDate(checks, habitId);
  final max = counts.values.fold(0, (a, b) => a > b ? a : b);
  return heatmapWeeks(today, weekCount)
      .map(
        (week) => week.map((date) {
          final count = counts[date] ?? 0;
          return HeatDay(
            date: date,
            count: count,
            level: heatLevel(count, max),
            future: date.compareTo(today) > 0,
          );
        }).toList(),
      )
      .toList();
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// One label per week column (abbreviated month, shown once per month) —
/// matches `heatmapMonthLabels`.
List<String> heatmapMonthLabels(List<List<String>> weeks) {
  var last = '';
  return List.generate(weeks.length, (index) {
    final first = weeks[index][0];
    final parts = first.split('-').map(int.parse).toList();
    final label = _monthNames[parts[1] - 1];
    final marked = index == 0 || weeks[index].any((iso) => iso.endsWith('-01'));
    if (!marked || label == last) return '';
    last = label;
    return label;
  });
}

List<String> lastSevenDays(String today) =>
    List.generate(7, (index) => shiftIso(today, index - 6));

/// Matches `heatFill`, operating on an already-resolved [accent] [Color]
/// rather than a hex string — by the time this runs, dark-mode swatch
/// resolution (`NoteSwatches.resolveHex`) has already happened once in the
/// widget tree, so there's no reason to round-trip back through hex here.
Color heatFill(int level, Color accent) {
  const ink = Color(0xFF2B261F);
  if (level <= 0) return const Color(0x1A2B261F); // rgba(43,38,31,0.10)
  if (level == 1) return Color.lerp(Colors.white, accent, 0.72)!;
  if (level == 2) return accent;
  if (level == 3) return Color.lerp(ink, accent, 0.62)!;
  return ink;
}
