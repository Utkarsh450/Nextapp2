import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/core/widgets/empty_state_view.dart';
import 'package:notes_app/core/widgets/paper_icon_button.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_labels.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/note_card.dart';
import 'package:notes_app/features/notes/presentation/today_dashboard.dart';

/// Creates a blank note and jumps straight into its editor. Stands in for
/// the source's dock "+" → quick-capture flow (`AppTabs.tsx`/
/// `CreateSheet.tsx`, feature-audit #9) — that dock isn't built yet, so
/// this FAB/empty-state action is the one entry point into note creation
/// for now.
void _createAndEdit(BuildContext context, WidgetRef ref) {
  final note = ref.read(notesControllerProvider.notifier).createBlank();
  unawaited(context.push('/notes/${note.id}/edit'));
}

const List<(NoteFilter, String)> _filters = [
  (NoteFilter.all, 'All'),
  (NoteFilter.open, 'Open'),
  (NoteFilter.due, 'Due'),
  (NoteFilter.done, 'Done'),
  (NoteFilter.archived, 'Archive'),
  (NoteFilter.trash, 'Trash'),
];

/// Port of the Notes tab in `features/notes/NotesApp.tsx` +
/// `NotesGrid.tsx`/`NoteCard.tsx` — the app's core screen (feature-audit #6),
/// now including the Today dashboard (#5 — see `today_dashboard.dart`).
///
/// **Scope note (this build):** the templates chip row and the "Today's
/// log" quick-create chip are deferred until the note editor exists to
/// receive them — called out again in the screen's completion notes, not
/// silently dropped.
class const NotesListScreen({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterKey = ref.watch(noteFilterKeyProvider);
    final shown = ref.watch(visibleNoteListProvider);
    final reminders = ref.watch(upcomingNoteRemindersProvider);
    final showToday = ref.watch(showTodayDashboardProvider);
    final spacing = Theme.of(context).extension<AppSpacing>()!;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createAndEdit(context, ref),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      // A single CustomScrollView (rather than a fixed header Column with
      // only the grid scrolling underneath) matches the source's
      // whole-page scroll — and matters more than cosmetics here: once
      // Today (with its progress/due/notebook sections) is showing, a
      // fixed-height header could overflow on shorter screens. One scroll
      // surface means the header content simply scrolls away instead.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          // No real network sync exists yet (see
          // docs/flutter-architecture.md §2 — the mutation queue is
          // dropped), so "refresh" has nothing to fetch; the gesture is
          // kept because it costs nothing and matches user expectation on
          // a scrollable list.
          onRefresh: () async {},
          child: CustomScrollView(
            key: const PageStorageKey('notes-list-scroll'),
            slivers: [
              const SliverToBoxAdapter(child: _HeaderRow()),
              if (showToday) const SliverToBoxAdapter(child: TodayDashboard()),
              if (!showToday &&
                  reminders.isNotEmpty &&
                  filterKey != NoteFilter.trash)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.lg,
                      0,
                      spacing.lg,
                      spacing.sm,
                    ),
                    child: _ReminderBanner(reminders: reminders),
                  ),
                ),
              const SliverToBoxAdapter(child: _FilterChipRow()),
              SliverToBoxAdapter(child: SizedBox(height: spacing.sm)),
              const SliverToBoxAdapter(child: _LabelChipRow()),
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NotesEmptyState(filterKey: filterKey),
                )
              else
                _NotesResultsSliver(shown: shown),
              if (filterKey == NoteFilter.trash && shown.isNotEmpty)
                const SliverToBoxAdapter(child: _EmptyTrashButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class const _HeaderRow() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final layout = ref.watch(noteBoardLayoutControllerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.sm,
        spacing.lg,
        spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notes',
              style: theme.textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PaperIconButton(
            label: layout == NoteBoardLayout.masonry
                ? 'Use even grid'
                : 'Use masonry',
            onPressed: () =>
                ref.read(noteBoardLayoutControllerProvider.notifier).toggle(),
            child: Icon(
              layout == NoteBoardLayout.masonry
                  ? Icons.grid_view_rounded
                  : Icons.view_column_outlined,
              size: 18,
            ),
          ),
          PaperIconButton(
            label: 'Search notes',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search — not built yet')),
            ),
            child: const Icon(Icons.search, size: 18),
          ),
        ],
      ),
    );
  }
}

class const _ReminderBanner({required final List<Note> reminders})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = Theme.of(context).extension<AppRadii>()!.bannerRadius;
    final titles = reminders
        .take(3)
        .map((n) => n.title.isEmpty ? 'Untitled' : n.title)
        .toList();

    return Material(
      color: const Color(0xD9F9D368),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () =>
            ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.due),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${reminders.length} '
                'reminder${reminders.length == 1 ? '' : 's'} due today',
                style: const TextStyle(
                  fontSize: 16.8,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF27272A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titles.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xCC3F3F46)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _FilterChipRow() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final swatches = Theme.of(context).extension<NoteSwatches>()!;
    final filterKey = ref.watch(noteFilterKeyProvider);
    final colorFilter = ref.watch(noteColorFilterProvider);
    final labelFilter = ref.watch(noteLabelFilterProvider);
    final notebookFilter = ref.watch(noteNotebookFilterProvider);
    final colors = ref.watch(noteColorOptionsProvider);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        children: [
          for (final (key, label) in _filters)
            Padding(
              padding: EdgeInsets.only(right: spacing.sm),
              child: _Chip(
                label: label,
                selected: filterKey == key,
                onTap: () => ref.read(noteFilterKeyProvider.notifier).set(key),
              ),
            ),
          if (notebookFilter != null)
            Padding(
              padding: EdgeInsets.only(right: spacing.sm),
              child: _Chip(
                label: 'All notebooks',
                selected: false,
                onTap: () =>
                    ref.read(noteNotebookFilterProvider.notifier).set(null),
              ),
            ),
          for (final color in colors)
            Padding(
              padding: EdgeInsets.only(right: spacing.sm),
              child: _ColorSwatch(
                color: swatches.resolveHex(color),
                selected: colorFilter == color,
                onTap: () {
                  final next = colorFilter == color ? null : color;
                  ref.read(noteColorFilterProvider.notifier).set(next);
                },
              ),
            ),
          if (colorFilter != null || labelFilter != null)
            _Chip(
              label: 'Clear filters',
              selected: false,
              onTap: () {
                ref.read(noteColorFilterProvider.notifier).set(null);
                ref.read(noteLabelFilterProvider.notifier).set(null);
              },
            ),
        ],
      ),
    );
  }
}

class const _LabelChipRow() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterKey = ref.watch(noteFilterKeyProvider);
    final labels = ref.watch(noteLabelOptionsProvider);
    if (labels.isEmpty || filterKey == NoteFilter.trash) {
      return const SizedBox.shrink();
    }

    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final swatches = Theme.of(context).extension<NoteSwatches>()!;
    final labelFilter = ref.watch(noteLabelFilterProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          children: [
            for (final label in labels)
              Padding(
                padding: EdgeInsets.only(right: spacing.sm),
                child: _Chip(
                  label: label,
                  selected: labelFilter == label,
                  tint: swatches.resolveHex(labelTint(label)),
                  onTap: () {
                    final next = labelFilter == label ? null : label;
                    ref.read(noteLabelFilterProvider.notifier).set(next);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class const _NotesEmptyState({required final NoteFilter filterKey})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelFilter = ref.watch(noteLabelFilterProvider);
    final isTrash = filterKey == NoteFilter.trash;
    final isDue = filterKey == NoteFilter.due;

    return EmptyStateView(
      glyph: isTrash ? '🗑️' : (isDue ? '⏰' : '✎'),
      title: isTrash
          ? 'Trash is empty. Deleted notes wait here for 30 days.'
          : isDue
          ? 'Nothing due today.'
          : labelFilter != null
          ? 'No notes labeled $labelFilter.'
          : 'Write your first note',
      actionLabel: isTrash ? null : 'Write your first note',
      onAction: isTrash ? null : () => _createAndEdit(context, ref),
    );
  }
}

class const _NotesResultsSliver({required final List<Note> shown})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final layout = ref.watch(noteBoardLayoutControllerProvider);
    final controller = ref.read(notesControllerProvider.notifier);
    final padding = EdgeInsets.symmetric(horizontal: spacing.lg)
        .copyWith(bottom: spacing.xxl);

    Widget buildCard(BuildContext context, int index) {
      final note = shown[index];
      return NoteCard(
        key: ValueKey(note.id),
        note: note,
        index: index,
        onOpen: () => context.push('/notes/${note.id}'),
        onToggleTask: (line) => controller.toggleTask(note.id, line),
        onToggleDone: () => controller.toggleDone(note.id),
        onPin: () => controller.togglePin(note.id),
        onArchive: () => controller.toggleArchive(note.id),
        onDuplicate: () => controller.duplicateNote(note.id),
        onTrash: () {
          controller.moveToTrash(note.id);
          _showUndoTrash(context, controller, note.id);
        },
        onRestore: () => controller.restoreTrashed(note.id),
        onDeleteForever: () => controller.deleteForever(note.id),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: layout == NoteBoardLayout.masonry
          ? SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: spacing.sm,
              crossAxisSpacing: spacing.sm,
              childCount: shown.length,
              itemBuilder: buildCard,
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => index.isOdd
                    ? SizedBox(height: spacing.sm)
                    : buildCard(context, index ~/ 2),
                childCount: shown.isEmpty ? 0 : shown.length * 2 - 1,
              ),
            ),
    );
  }

  void _showUndoTrash(
    BuildContext context,
    NotesController controller,
    int id,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.restoreTrashed(id),
        ),
      ),
    );
  }
}

class const _EmptyTrashButton() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final controller = ref.read(notesControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: TextButton(
        onPressed: () => _confirmEmptyTrash(context, controller),
        child: Text(
          'Empty trash',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    NotesController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty trash?'),
        content: const Text('This permanently deletes everything in Trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty now'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.emptyTrash();
  }
}

class const _Chip({
  required final String label,
  required final bool selected,
  required final VoidCallback onTap,
  final Color? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fallback = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.62);
    final background = selected
        ? theme.colorScheme.primary
        : tint?.withValues(alpha: 0.6) ?? fallback;

    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 13.6),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class const _ColorSwatch({
  required final Color color,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ink : Colors.black.withValues(alpha: 0.1),
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
