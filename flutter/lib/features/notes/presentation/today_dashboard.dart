import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dashboard.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/notes/TodayBoard.tsx` — the Notes tab's home
/// dashboard, shown only when no filter is active (feature-audit #5); see
/// `notes_controller.dart`'s `showTodayDashboardProvider` for the gate.
///
/// **Not ported:** the `SquiggleSticker`/`TodayStickers`/`HeartSticker`
/// hand-drawn doodles from `components/ui/PaperStickers.tsx` — that file
/// isn't built yet (same call-out as `CardTape` in `habits_board.dart`).
///
/// **No account/profile screen yet** (feature-audit #14), so there's no
/// real name to greet with — this always falls through to the source's own
/// "there" fallback (`name.trim().split(/\s+/)[0] || 'there'` with an empty
/// name), rather than inventing a placeholder identity.
///
/// **Added beyond the source:** the progress ring and its percentage
/// animate in with a `TweenAnimationBuilder` instead of snapping straight
/// to their value — the source's SVG arc has no such transition. Pure
/// polish, no behavior change.
class const TodayDashboard({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(noteDashboardDataProvider);
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final swatches = Theme.of(context).extension<NoteSwatches>()!;
    final hour = DateTime.now().hour;
    const first = 'there';

    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Greeting(hour: hour, name: first),
          SizedBox(height: spacing.lg),
          _ProgressCard(dashboard: dashboard, swatches: swatches),
          if (dashboard.due.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            _DueCard(due: dashboard.due, swatches: swatches),
          ],
          SizedBox(height: spacing.sm),
          _NotebookTiles(dashboard: dashboard, swatches: swatches),
          SizedBox(height: spacing.sm),
          _MetricChipRow(dashboard: dashboard, swatches: swatches),
        ],
      ),
    );
  }
}

class const _Greeting({required final int hour, required final String name})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${greetingForHour(hour)}, $name',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover, create, enjoy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 29.6,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                  letterSpacing: -1.18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class const _ProgressCard({
  required final NoteDashboard dashboard,
  required final NoteSwatches swatches,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(28);
    final featured = dashboard.featured;
    final headline = dashboard.tasksTotal > 0
        ? '${dashboard.tasksDone} of ${dashboard.tasksTotal} tasks'
        : '${dashboard.done} notes done';
    final spark = sparkPath(dashboard.week.map((w) => w.count).toList());
    final featuredTasks = featured != null
        ? checklistProgress(featured.body)
        : null;
    var nextUpLine = '';
    if (featured != null) {
      final title = featured.title.isEmpty ? 'Untitled' : featured.title;
      final taskSuffix = featuredTasks!.total > 0
          ? ' · ${featuredTasks.done}/${featuredTasks.total}'
          : '';
      nextUpLine = 'Next up · $title$taskSuffix';
    }

    return Material(
      color: swatches.resolveHex('#C5CA8A'),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          if (featured != null) {
            unawaited(context.push('/notes/${featured.id}/edit'));
          } else {
            ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.open);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          'Your progress',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _ink.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          headline,
                          style: const TextStyle(
                            fontSize: 21.6,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            letterSpacing: -0.65,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dashboard.open} open · '
                          '${dashboard.due.length} due',
                          style: TextStyle(
                            fontSize: 14,
                            color: _ink.withValues(alpha: 0.7),
                          ),
                        ),
                        if (spark.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 96,
                            height: 32,
                            child: CustomPaint(
                              painter: _SparklinePainter(spark: spark),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ProgressRing(percent: dashboard.percent),
                ],
              ),
              if (featured != null) ...[
                const SizedBox(height: 16),
                Text(
                  nextUpLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class const _ProgressRing({required final int percent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: percent.toDouble()),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(88, 88),
                painter: _RingPainter(percent: value),
              ),
              Text(
                '${value.round()}%',
                style: const TextStyle(
                  fontSize: 18.4,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class const _RingPainter({required final double percent})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * (10 / 120);
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - strokeWidth / 2,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0x292B261F);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (percent <= 0) return;
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * (percent / 100).clamp(0, 1),
      false,
      value,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

class const _SparklinePainter({required final String spark})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = RegExp(r'[ML]([\d.]+) ([\d.]+)')
        .allMatches(spark)
        .map(
          (m) => Offset(double.parse(m.group(1)!), double.parse(m.group(2)!)),
        )
        .toList();
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.spark != spark;
}

class const _DueCard({
  required final List<Note> due,
  required final NoteSwatches swatches,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(28);
    final shown = due.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: swatches.resolveHex('#E7A3A3'),
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due with you',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          for (final note in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DueRow(note: note),
            ),
          if (due.length > 3)
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _ink,
              ),
              onPressed: () =>
                  ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.due),
              child: const Text(
                'See all due →',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class const _DueRow({required final Note note}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => unawaited(context.push('/notes/${note.id}/edit')),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ),
              const Icon(Icons.north_east, size: 16, color: _ink),
            ],
          ),
        ),
      ),
    );
  }
}

class const _NotebookTiles({
  required final NoteDashboard dashboard,
  required final NoteSwatches swatches,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = dashboard.notebooks.take(4).toList();
    if (tiles.isEmpty) return const SizedBox.shrink();

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // A fixed `mainAxisExtent` (rather than `childAspectRatio`) keeps
      // tile height constant regardless of the grid's width — on a narrow
      // phone, a width-derived aspect ratio here made these tiles too
      // short for their own content (icon + name + count + "Check →"),
      // overflowing. The source's CSS only sets a *minimum* height
      // (`min-h-[7.4rem]`) and lets content grow it; a fixed extent is the
      // simplest equivalent that's guaranteed not to overflow.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 148,
      ),
      children: [
        for (final (index, tile) in tiles.indexed)
          _NotebookTile(
            key: ValueKey('notebook-tile-${tile.id}'),
            tile: tile,
            rotation: index == 1
                ? -1.5
                : index == 2
                ? 1.2
                : 0,
            color: swatches.resolveHex(tile.color),
            onTap: () {
              ref.read(noteNotebookFilterProvider.notifier).set(tile.id);
              ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
            },
          ),
      ],
    );
  }
}

class const _NotebookTile({
  required final NotebookTile tile,
  required final double rotation,
  required final Color color,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final card = Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 18, color: _ink),
              const SizedBox(height: 14),
              Text(
                tile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tile.count} notes',
                style: TextStyle(
                  fontSize: 14,
                  color: _ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (rotation == 0) return card;
    return Transform.rotate(angle: rotation * math.pi / 180, child: card);
  }
}

class const _MetricChipRow({
  required final NoteDashboard dashboard,
  required final NoteSwatches swatches,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MetricChip(
            icon: Icons.checklist_rtl,
            label: 'Open lists',
            value: '${dashboard.open}',
            tone: swatches.resolveHex('#BEC3BC'),
            onTap: () =>
                ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.open),
          ),
          const SizedBox(width: 12),
          _MetricChip(
            icon: Icons.calendar_today_outlined,
            label: 'Due today',
            value: '${dashboard.due.length}',
            tone: swatches.resolveHex('#E89569'),
            onTap: () =>
                ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.due),
          ),
          const SizedBox(width: 12),
          _MetricChip(
            icon: Icons.check_circle_outline,
            label: 'Finished',
            value: '${dashboard.done}',
            tone: swatches.resolveHex('#A9D4C4'),
            onTap: () =>
                ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.done),
          ),
        ],
      ),
    );
  }
}

class const _MetricChip({
  required final IconData icon,
  required final String label,
  required final String value,
  required final Color tone,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Material(
      color: tone,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 136),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _ink),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19.2,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.58,
                  color: _ink,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
