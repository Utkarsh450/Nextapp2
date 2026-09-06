import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/habits/presentation/habits_board.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';
import 'package:notes_app/features/plan/domain/plan_providers.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/notes/PlanView.tsx` — the habit tracker
/// (feature-audit #13) plus the "What's next" agenda section
/// (feature-audit #12): Overdue/Due today/Coming up/Open-lists buckets,
/// or a "Clear for now" card when nothing's waiting.
class const PlanScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final swatches = theme.extension<NoteSwatches>()!;
    final agenda = ref.watch(planAgendaProvider);
    final today = todayIso();

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
            SizedBox(height: spacing.xxl),
            Text(
              'What’s next',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: spacing.md),
            if (agenda.waiting == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: swatches.resolveHex('#C5CA8A'),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 22, color: _ink),
                    SizedBox(height: 16),
                    Text(
                      'Clear for now',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.6,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Put a date on a note, or a checklist, and it will '
                      'land here.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xB32B261F),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _AgendaCard(
                    title: 'Overdue',
                    tone: swatches.resolveHex('#E7A3A3'),
                    notes: agenda.overdue,
                    today: today,
                    onOpen: (id) => context.push('/notes/$id'),
                  ),
                  _AgendaCard(
                    title: 'Due today',
                    tone: swatches.resolveHex('#C5CA8A'),
                    notes: agenda.dueToday,
                    today: today,
                    onOpen: (id) => context.push('/notes/$id'),
                  ),
                  _AgendaCard(
                    title: 'Coming up',
                    tone: swatches.resolveHex('#E89569'),
                    notes: agenda.soon,
                    today: today,
                    onOpen: (id) => context.push('/notes/$id'),
                  ),
                  _AgendaCard(
                    title: 'Open lists',
                    tone: swatches.resolveHex('#D4C4E8'),
                    notes: agenda.lists,
                    today: today,
                    isLists: true,
                    onOpen: (id) => context.push('/notes/$id'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class const _AgendaCard({
  required final String title,
  required final Color tone,
  required final List<Note> notes,
  required final String today,
  required final void Function(int id) onOpen,
  final bool isLists = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final spacing = Theme.of(context).extension<AppSpacing>()!;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tone,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _ink.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${notes.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AgendaRow(
                  note: note,
                  today: today,
                  isLists: isLists,
                  onTap: () => onOpen(note.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class const _AgendaRow({
  required final Note note,
  required final String today,
  required final bool isLists,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = checklistProgress(note.body);
    final when = formatDueChip(note.dueAt, note.dueTime, today);
    final subtitle = isLists && tasks.total > 0
        ? '${tasks.done} of ${tasks.total} tasks'
        : when ?? note.notebook;
    final radius = BorderRadius.circular(999);

    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLists ? Icons.checklist_rtl : Icons.north_east,
                size: 16,
                color: _ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
