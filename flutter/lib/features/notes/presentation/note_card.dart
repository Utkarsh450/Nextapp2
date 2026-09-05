import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/tokens/app_motion.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/core/theme/tokens/paper_tokens.dart';
import 'package:notes_app/core/widgets/paytm_tick.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

enum _NoteMenuAction {
  pin,
  archive,
  duplicate,
  open,
  trash,
  restore,
  deleteForever,
}

/// Port of `features/notes/NoteCard.tsx`.
///
/// Fixes the source's known context-menu bug (`NoteCard.tsx` calls a
/// `setMenu` that isn't in scope, so every menu action throws — see
/// `docs/feature-audit.md` §3b): here the menu is Flutter's own [showMenu],
/// which only returns a selection after it has already dismissed itself,
/// so the "close, then act" bug the source has isn't structurally possible.
///
/// Also wires up the "mark done" gesture (`PaytmTick`) and a long-press
/// context menu (Flutter's built-in ~500ms `onLongPress`, matching the
/// source's hand-rolled 480ms timer closely enough — see
/// `docs/design-system.md` §7) that the source built but never shipped.
class const NoteCard({
  required final Note note,
  required final int index,
  required final VoidCallback onOpen,
  required final void Function(int line) onToggleTask,
  required final VoidCallback onToggleDone,
  required final VoidCallback onPin,
  required final VoidCallback onArchive,
  required final VoidCallback onDuplicate,
  required final VoidCallback onTrash,
  required final VoidCallback onRestore,
  required final VoidCallback onDeleteForever,
  super.key,
}) extends StatelessWidget {
  List<PopupMenuEntry<_NoteMenuAction>> get _menuItems {
    if (note.trashedAt != null) {
      return const [
        PopupMenuItem(
          value: _NoteMenuAction.restore,
          child: _MenuRow(icon: Icons.restore, label: 'Restore'),
        ),
        PopupMenuItem(
          value: _NoteMenuAction.deleteForever,
          child: _MenuRow(
            icon: Icons.delete_forever,
            label: 'Delete forever',
          ),
        ),
      ];
    }
    return [
      PopupMenuItem(
        value: _NoteMenuAction.pin,
        child: _MenuRow(
          icon: Icons.push_pin_outlined,
          label: note.pinned ? 'Unpin' : 'Pin',
        ),
      ),
      PopupMenuItem(
        value: _NoteMenuAction.archive,
        child: _MenuRow(
          icon: Icons.archive_outlined,
          label: note.archived ? 'Unarchive' : 'Archive',
        ),
      ),
      const PopupMenuItem(
        value: _NoteMenuAction.duplicate,
        child: _MenuRow(icon: Icons.copy_outlined, label: 'Duplicate'),
      ),
      const PopupMenuItem(
        value: _NoteMenuAction.open,
        child: _MenuRow(icon: Icons.bookmark_border, label: 'Open'),
      ),
      const PopupMenuItem(
        value: _NoteMenuAction.trash,
        child: _MenuRow(
          icon: Icons.delete_outline,
          label: 'Move to trash',
        ),
      ),
    ];
  }

  void _handleSelection(_NoteMenuAction? selection) {
    switch (selection) {
      case _NoteMenuAction.pin:
        onPin();
      case _NoteMenuAction.archive:
        onArchive();
      case _NoteMenuAction.duplicate:
        onDuplicate();
      case _NoteMenuAction.open:
        onOpen();
      case _NoteMenuAction.trash:
        onTrash();
      case _NoteMenuAction.restore:
        onRestore();
      case _NoteMenuAction.deleteForever:
        onDeleteForever();
      case null:
        break;
    }
  }

  /// Long-press (touch): Flutter's `onLongPress` carries no position, so
  /// the menu anchors to the card's own bounds instead of the touch point.
  Future<void> _openMenuFromWidget(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final position = RelativeRect.fromRect(
      topLeft & box.size,
      Offset.zero & overlayBox.size,
    );
    _handleSelection(
      await showMenu<_NoteMenuAction>(
        context: context,
        position: position,
        items: _menuItems,
      ),
    );
  }

  /// Right-click (desktop/web testing, matching the source's secondary
  /// affordance): anchors exactly at the pointer.
  Future<void> _openMenuAt(BuildContext context, Offset globalPosition) async {
    final overlayBox =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlayBox.size,
    );
    _handleSelection(
      await showMenu<_NoteMenuAction>(
        context: context,
        position: position,
        items: _menuItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radii = theme.extension<AppRadii>()!;
    final motion = theme.extension<AppMotion>()!;
    final swatches = theme.extension<NoteSwatches>()!;
    final paper = theme.extension<PaperTokens>()!;
    final cardColor = swatches.resolveHex(
      note.color.isEmpty ? NoteSwatches.paletteHex[4] : note.color,
    );
    final ink = theme.brightness == Brightness.dark
        ? const Color(0xFFF3EEE6)
        : const Color(0xFF2B261F);
    final surface = cardSurface(note.body, note.preview);
    final showTasks = surface.shownTasks.isNotEmpty;
    final showBullets = !showTasks && surface.shownBullets.isNotEmpty;
    final delayMs = index.clamp(0, 8) * motion.cardStagger.inMilliseconds;
    final totalMs = delayMs + motion.cardEnter.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: motion.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radii.cardRadius,
          boxShadow: paper.cardShadow,
        ),
        child: Material(
          color: cardColor,
          borderRadius: radii.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            onLongPress: () => _openMenuFromWidget(context),
            onSecondaryTapDown: (details) =>
                _openMenuAt(context, details.globalPosition),
            child: Padding(
              padding: const EdgeInsets.all(18.4),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: ink),
                child: Stack(
                  children: [
                    _NoteCardBody(
                      note: note,
                      surface: surface,
                      showTasks: showTasks,
                      showBullets: showBullets,
                      ink: ink,
                      onToggleTask: onToggleTask,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: PaytmTick(
                        active: note.confirmed,
                        onToggle: onToggleDone,
                      ),
                    ),
                    if (note.pinned)
                      Positioned(
                        right: 0,
                        top: 26,
                        child: Icon(
                          Icons.push_pin,
                          size: 14,
                          color: ink.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's title/prose/tasks/bullets/timestamp column — split out of
/// [NoteCard] purely to keep `build()` readable, per the single-
/// responsibility-widget code-quality requirement.
class const _NoteCardBody({
  required final Note note,
  required final NoteCardSurface surface,
  required final bool showTasks,
  required final bool showBullets,
  required final Color ink,
  required final void Function(int line) onToggleTask,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Text(
              note.title,
              style: theme.textTheme.titleMedium?.copyWith(color: ink),
            ),
          ),
        if (surface.prose.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: note.title.trim().isNotEmpty ? spacing.sm : 0,
            ),
            child: Text(
              surface.prose,
              maxLines: showTasks || showBullets ? 4 : 8,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: 0.9),
              ),
            ),
          ),
        if (showTasks)
          Padding(
            padding: EdgeInsets.only(top: spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final task in surface.shownTasks)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.sm),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onToggleTask(task.line),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TaskCheck(checked: task.checked),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              task.text.isEmpty ? 'Item' : task.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: task.checked
                                    ? ink.withValues(alpha: 0.45)
                                    : ink,
                                decoration: task.checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (showBullets)
          Padding(
            padding: EdgeInsets.only(top: spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final bullet in surface.shownBullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7.5),
                          child: Container(
                            width: 5.1,
                            height: 5.1,
                            decoration: BoxDecoration(
                              color: ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(
                          child: Text(
                            bullet.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: spacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 13,
                color: ink.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 6),
              Text(
                formatNoteTimestamp(note.updatedAt),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ink.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class const _TaskCheck({required final bool checked}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF3EEE6)
        : const Color(0xFF3A322C);
    return Padding(
      padding: const EdgeInsets.only(top: 2.9),
      child: Container(
        width: 14.7,
        height: 14.7,
        decoration: BoxDecoration(
          color: checked ? ink : Colors.transparent,
          border: Border.all(color: ink, width: 1.6),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class const _MenuRow({
  required final IconData icon,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }
}
