import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_backlinks.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_labels.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/markdown_preview_view.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/notes/NoteDetail.tsx` — the read-only note viewer
/// (feature-audit #7). Tapping a note card now opens here first, matching
/// the source; the note editor (`note_editor_screen.dart`) is reached only
/// through this screen's Edit button, at `/notes/:id/edit`.
///
/// **Not ported:** the `CardTape` washi-tape decoration
/// (`components/ui/PaperStickers.tsx` isn't built yet, same call-out as
/// elsewhere), and the attachments thumbnail grid — `Note.attachments`
/// isn't modeled yet (see `note.dart`'s doc comment), so there's nothing
/// to render there.
class const NoteDetailScreen({required final int noteId, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('This note is gone.')),
      );
    }

    final allNotes = ref.watch(notesControllerProvider);
    final controller = ref.read(notesControllerProvider.notifier);
    final swatches = Theme.of(context).extension<NoteSwatches>()!;
    final paperColor = swatches.resolveHex(
      note.color.isEmpty ? NoteSwatches.paletteHex[0] : note.color,
    );
    final trashed = note.trashedAt != null;
    final due = formatDueChip(note.dueAt, note.dueTime, todayIso());
    final stamp = formatNoteTimestamp(note.updatedAt);
    final count = wordCount('${note.title} ${note.body}');
    final incoming = backlinksTo(note, allNotes);

    void openLink(String title) {
      final match = findNoteByTitle(allNotes, title);
      if (match != null) unawaited(context.push('/notes/${match.id}'));
    }

    return Scaffold(
      backgroundColor: paperColor,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHeader(
              note: note,
              trashed: trashed,
              onClose: () => context.pop(),
              onEdit: () => context.push('/notes/${note.id}/edit'),
              onRestore: () {
                controller.restoreTrashed(note.id);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Restored')));
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title.trim().isEmpty ? 'Untitled' : note.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                        letterSpacing: -1.44,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stamp,
                      style: TextStyle(
                        fontSize: 14,
                        color: _ink.withValues(alpha: 0.55),
                      ),
                    ),
                    if (due != null ||
                        note.labels.isNotEmpty ||
                        note.tag.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (due != null) _Chip(label: due),
                          if (note.tag.isNotEmpty) _Chip(label: note.tag),
                          for (final label in note.labels)
                            _Chip(
                              label: label,
                              tint: swatches.resolveHex(labelTint(label)),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 160),
                      child: note.body.trim().isEmpty
                          ? Text(
                              'This note is still empty.',
                              style: TextStyle(
                                color: _ink.withValues(alpha: 0.45),
                              ),
                            )
                          : MarkdownPreviewView(
                              body: note.body,
                              onToggleTask: (line) =>
                                  controller.toggleTask(note.id, line),
                              onOpenLink: openLink,
                            ),
                    ),
                    if (incoming.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Linked from',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _ink.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in incoming)
                            _Chip(
                              label: item.title.isEmpty
                                  ? 'Untitled'
                                  : item.title,
                              onTap: () => context.push('/notes/${item.id}'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _DetailFooter(
              trashed: trashed,
              wordCount: count,
              onDelete: () {
                controller.moveToTrash(note.id);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Moved to trash'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => controller.restoreTrashed(note.id),
                    ),
                  ),
                );
              },
              onDeleteForever: () {
                controller.deleteForever(note.id);
                context.pop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class const _DetailHeader({
  required final Note note,
  required final bool trashed,
  required final VoidCallback onClose,
  required final VoidCallback onEdit,
  required final VoidCallback onRestore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close, size: 18, color: _ink),
              ),
            ),
          ),
          Expanded(
            child: Text(
              note.notebook.isEmpty ? 'Inbox' : note.notebook,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink.withValues(alpha: 0.7),
              ),
            ),
          ),
          Material(
            color: const Color(0xFF1A1814),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: trashed ? onRestore : onEdit,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: trashed
                    ? const Text(
                        'Restore',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _Chip({
  required final String label,
  final Color? tint,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final content = Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            tint?.withValues(alpha: 0.6) ?? Colors.white.withValues(alpha: 0.7),
        borderRadius: radius,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

class const _DetailFooter({
  required final bool trashed,
  required final int wordCount,
  required final VoidCallback onDelete,
  required final VoidCallback onDeleteForever,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    const dangerColor = Color(0xFF7A2418);
    final radius = BorderRadius.circular(999);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.sm,
        spacing.lg,
        spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: trashed ? onDeleteForever : onDelete,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: dangerColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trashed ? 'Delete forever' : 'Delete',
                        style: const TextStyle(
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$wordCount words',
              style: TextStyle(
                fontSize: 12.5,
                color: _ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
