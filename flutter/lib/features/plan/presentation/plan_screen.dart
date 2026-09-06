import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/features/habits/presentation/habits_board.dart';

/// Port of `features/notes/PlanView.tsx`'s header + `HabitsBoard`
/// (feature-audit #13, this build's actual target).
///
/// **Scope note:** the agenda section below the habit tracker in the
/// source (Overdue/Due today/Coming up/Open lists, feature-audit #12 —
/// its own, separate item from the habit tracker) is not built here.
/// `lib/notes/agenda.ts`'s bucket logic (`noteAgenda`) isn't ported, so
/// this screen ends after the habit tracker rather than showing an
/// agenda section with nothing behind it.
class const PlanScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.lg),
          children: [
            Text(
              'Your day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: spacing.xs),
            Text('Plan', style: theme.textTheme.headlineMedium),
            SizedBox(height: spacing.sm),
            Text(
              'Habits fill the paper. Dates, pings, and unfinished lists '
              'wait underneath.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: spacing.xl),
            const HabitsBoard(),
          ],
        ),
      ),
    );
  }
}
