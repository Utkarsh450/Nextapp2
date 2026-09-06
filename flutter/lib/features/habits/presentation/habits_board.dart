import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/habits/domain/habit.dart';
import 'package:notes_app/features/habits/domain/habit_heatmap.dart' as heatmap;
import 'package:notes_app/features/habits/domain/habits_controller.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';

const List<String> _weekdayLabels = ['M', '', 'W', '', 'F', '', ''];

/// Port of `features/notes/HabitsBoard.tsx` — a GitHub-style 18-week
/// heatmap, current/best streak, add/remove habits, and tap-to-toggle
/// check-ins.
///
/// **Not ported:** the `CardTape` washi-tape decoration the source wraps
/// this panel in — `components/ui/PaperStickers.tsx` isn't built yet (it's
/// its own small chunk of decorative work, not specific to the habit
/// tracker). Layout and behavior otherwise match exactly.
class const HabitsBoard({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<HabitsBoard> createState() => _HabitsBoardState();
}

class _HabitsBoardState extends ConsumerState<HabitsBoard> {
  String? _selectedHabitId;
  bool _editing = false;
  bool _composing = false;
  final _draftController = TextEditingController();

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  void _addHabit(String name, {String? color}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final habits = ref.read(habitsControllerProvider);
    ref
        .read(habitsControllerProvider.notifier)
        .addHabit(
          trimmed,
          color:
              color ??
              NoteSwatches.paletteHex[habits.length %
                  NoteSwatches.paletteHex.length],
        );
    _draftController.clear();
    setState(() => _composing = false);
    unawaited(HapticFeedback.selectionClick());
  }

  void _toggle(String habitId, String date, String today) {
    if (date.compareTo(today) > 0) return;
    ref.read(habitChecksControllerProvider.notifier).toggleCheck(habitId, date);
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final radii = theme.extension<AppRadii>()!;
    final ink = theme.colorScheme.onSurface;

    final habits = ref.watch(habitsControllerProvider);
    final checks = ref.watch(habitChecksControllerProvider);
    final today = todayIso();

    final habit = habits.where((h) => h.id == _selectedHabitId).firstOrNull;
    final accentHex = habit?.color ?? NoteSwatches.paletteHex[0];
    final swatches = theme.extension<NoteSwatches>()!;
    final accent = swatches.resolveHex(accentHex);

    final grid = heatmap.buildHeatmap(checks, today, habitId: habit?.id);
    final months = heatmap.heatmapMonthLabels(
      grid.map((week) => week.map((day) => day.date).toList()).toList(),
    );
    final dates = heatmap.datesWithChecks(checks, habit?.id);
    final streak = heatmap.currentStreak(dates, today);
    final best = heatmap.bestStreak(dates);
    final days = dates.length;
    final recent = heatmap.lastSevenDays(today);
    final suggestions = heatmap.suggestedHabits
        .where(
          (s) => !habits.any(
            (h) => h.name.toLowerCase() == s.name.toLowerCase(),
          ),
        )
        .toList();

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: radii.cardRadius,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit?.name ?? 'Habits',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: ink.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      days > 0
                          ? '$days day${days == 1 ? '' : 's'} on paper'
                          : 'The paper is still blank',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: ink,
                        fontSize: 18.4,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      days > 0
                          ? '$streak now · best $best'
                          : 'Check a habit. Squares fill like a quiet garden.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (habits.isNotEmpty)
                _EditToggle(
                  editing: _editing,
                  onTap: () => setState(() => _editing = !_editing),
                ),
            ],
          ),
          SizedBox(height: spacing.lg),
          _Heatmap(
            grid: grid,
            months: months,
            today: today,
            accent: accent,
            onTapDay: habit == null
                ? null
                : (date) => _toggle(habit.id, date, today),
          ),
          SizedBox(height: spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  habit != null
                      ? 'Tap a square to mark a day'
                      : 'Tap a habit to paint this grid',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ink.withValues(alpha: 0.55),
                    fontSize: 10.9,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Less',
                    style: TextStyle(
                      fontSize: 10.9,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  ),
                  for (var level = 0; level <= 4; level++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: heatmap.heatFill(level, accent),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 10.9,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          for (final item in habits)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: _HabitRow(
                habit: item,
                done: heatmap.hasCheck(checks, item.id, today),
                selected: _selectedHabitId == item.id,
                editing: _editing,
                recentDates: recent,
                checks: checks,
                accent: swatches.resolveHex(item.color),
                onToggleToday: () => _toggle(item.id, today, today),
                onSelect: () => setState(
                  () => _selectedHabitId = _selectedHabitId == item.id
                      ? null
                      : item.id,
                ),
                onRemove: () {
                  if (_selectedHabitId == item.id) {
                    setState(() => _selectedHabitId = null);
                  }
                  ref
                      .read(habitsControllerProvider.notifier)
                      .removeHabit(item.id);
                },
              ),
            ),
          if (_composing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _draftController,
                    autofocus: true,
                    onSubmitted: _addHabit,
                    decoration: const InputDecoration(
                      hintText: 'Write, stretch, read…',
                    ),
                  ),
                ),
                SizedBox(width: spacing.sm),
                IconButton.filled(
                  onPressed: () => _addHabit(_draftController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _composing = true),
                style: FilledButton.styleFrom(
                  backgroundColor: swatches.resolveHex('#C5CA8A'),
                  foregroundColor: const Color(0xFF2B261F),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add a habit'),
              ),
            ),
          if (habits.isEmpty && suggestions.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final item in suggestions)
                  ActionChip(
                    label: Text(item.name),
                    backgroundColor: swatches.resolveHex(item.color),
                    onPressed: () => _addHabit(item.name, color: item.color),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class const _EditToggle({
  required final bool editing,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            editing ? 'Done' : 'Edit',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class const _Heatmap({
  required final List<List<heatmap.HeatDay>> grid,
  required final List<String> months,
  required final String today,
  required final Color accent,
  required final void Function(String date)? onTapDay,
}) extends StatelessWidget {
  static const _weekdayColumnWidth = 14.0;
  static const _weekdayGap = 6.0;
  static const _cellGap = 3.0;
  static const _monthLabelHeight = 14.0;

  @override
  Widget build(BuildContext context) {
    // Every height here is derived from the available *width* (never from
    // an ambient bounded height), since this widget is meant to sit inside
    // a scrollable (`PlanScreen`'s `ListView`) — which hands its children
    // unbounded height. A naive `Expanded`-inside-`Column` approach for the
    // weekday-label rows broke exactly there (`Expanded` needs a bounded
    // parent height); a `LayoutBuilder` sidesteps that entirely.
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth =
            constraints.maxWidth - _weekdayColumnWidth - _weekdayGap;
        final totalGaps = _cellGap * (grid.length - 1);
        final cellSize = ((gridWidth - totalGaps) / grid.length).clamp(
          4.0,
          double.infinity,
        );
        final labelStyle = TextStyle(
          fontSize: 9.3,
          color: Colors.black.withValues(alpha: 0.48),
        );

        return Semantics(
          image: true,
          label: 'Habits heatmap',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _weekdayColumnWidth,
                child: Column(
                  children: [
                    const SizedBox(height: _monthLabelHeight + _cellGap),
                    for (final label in _weekdayLabels)
                      SizedBox(
                        height: cellSize + _cellGap,
                        child: Center(child: Text(label, style: labelStyle)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: _weekdayGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: _monthLabelHeight,
                      child: Row(
                        children: [
                          for (final label in months)
                            Expanded(
                              child: Text(label, style: labelStyle),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _cellGap),
                    Row(
                      children: [
                        for (final week in grid)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _cellGap / 2,
                              ),
                              child: Column(
                                children: [
                                  for (final day in week)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: _cellGap / 2,
                                      ),
                                      child: _HeatCell(
                                        day: day,
                                        // Height is the one dimension a
                                        // Column can't hand a child for
                                        // free — width instead comes
                                        // exactly from Expanded above, so
                                        // cells stay square without this
                                        // estimate needing to be exact.
                                        height: cellSize,
                                        isToday: day.date == today,
                                        color: heatmap.heatFill(
                                          day.level,
                                          accent,
                                        ),
                                        onTap: onTapDay,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class const _HeatCell({
  required final heatmap.HeatDay day,
  required final double height,
  required final bool isToday,
  required final Color color,
  required final void Function(String date)? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final callback = onTap;
        if (day.future || callback == null) return;
        callback(day.date);
      },
      child: Opacity(
        opacity: day.future ? 0.38 : 1,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: isToday
                ? Border.all(color: const Color(0xFF2B261F), width: 1.4)
                : null,
          ),
        ),
      ),
    );
  }
}

class const _HabitRow({
  required final Habit habit,
  required final bool done,
  required final bool selected,
  required final bool editing,
  required final List<String> recentDates,
  required final List<HabitCheck> checks,
  required final Color accent,
  required final VoidCallback onToggleToday,
  required final VoidCallback onSelect,
  required final VoidCallback onRemove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: selected
            ? Border.all(color: const Color(0xFF2B261F), width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Material(
            color: done ? accent : Colors.black.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggleToday,
              child: SizedBox(
                width: 40,
                height: 40,
                child: done
                    ? const Icon(Icons.check, size: 16)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onSelect,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final date in recentDates)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: heatmap.hasCheck(checks, habit.id, date)
                                    ? accent
                                    : Colors.black.withValues(alpha: 0.16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (editing)
            IconButton(
              tooltip: 'Remove ${habit.name}',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}
