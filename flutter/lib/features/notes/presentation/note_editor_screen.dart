import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/core/widgets/paytm_tick.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_backlinks.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_labels.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/markdown_preview_view.dart';
import 'package:notes_app/features/notes/presentation/reminder_fields_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Port of `features/notes/NoteEditor.tsx` — the most feature-dense screen
/// in the source app (feature-audit #8).
///
/// **Scope, per the "no backend/DB for now" instruction and this build's
/// own completion notes:**
/// - Images insert inline as `data:` URIs in the body (compressed via
///   `flutter_image_compress`, matching the source's max-1280px/q72
///   settings) — there's no separate Attachments table yet, so no
///   thumbnail grid or per-attachment remove button; delete the markdown
///   text to remove one.
/// - "Save as template" is dropped — `SavedTemplate` isn't modeled (that's
///   its own feature, not built).
/// - Due date/alert are fully editable and stored (`dueAt`/`dueTime`/
///   `alertMinutes`/`remindAt`), but nothing schedules an OS notification
///   from them yet — see `note_reminders.dart`.
/// - Export shares the note as Markdown *text* via the share sheet
///   (`share_plus`), not a written `.md` file — simpler, and the user can
///   still save it from there.
/// - Pin/Archive/Duplicate/Mark-done/Trash are surfaced here (as an
///   overflow menu) even though the source's editor header only has
///   Close/Done — `NoteDetail`, the screen that normally hosts these, isn't
///   built yet, so leaving them out would make an opened note a dead end.
class const NoteEditorScreen({required final int noteId, super.key})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  final _labelDraftController = TextEditingController();
  final _speech = SpeechToText();

  int? _syncedNoteId;
  bool _preview = false;
  bool _linkOpen = false;
  bool _detailsOpen = false;
  bool _listening = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _labelDraftController.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  NotesController get _controller =>
      ref.read(notesControllerProvider.notifier);

  /// Resets local editor UI (and re-seeds the text controllers) only when
  /// switching to a different note — matches the source's
  /// `if (note.id !== noteId) { … }` guard, so mid-typing rebuilds from
  /// provider updates never fight the user's cursor.
  void _syncControllers(Note note) {
    if (_syncedNoteId == note.id) return;
    _syncedNoteId = note.id;
    _titleController.text = note.title;
    _bodyController.text = note.body;
    _tagController.text = note.tag;
    _labelDraftController.clear();
    _preview = false;
    _linkOpen = false;
    _detailsOpen = false;
  }

  void _patch(Note note, Note Function(Note note) update) {
    _controller.saveNote(update(note));
  }

  void _updateBody(Note note, String newBody) {
    _patch(note, (n) => n.copyWith(body: newBody));
    _bodyController.value = TextEditingValue(
      text: newBody,
      selection: TextSelection.collapsed(offset: newBody.length),
    );
  }

  Future<void> _pickImage(Note note) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    final file = files.firstOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1280,
      minHeight: 1280,
      quality: 72,
    );
    final dataUri = 'data:image/jpeg;base64,${base64Encode(compressed)}';
    _updateBody(note, insertImageMarkdown(note.body, dataUri, file.name));
  }

  Future<void> _listen(Note note) async {
    if (_listening) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          setState(() => _listening = false);
        }
      },
      onError: (_) => setState(() => _listening = false),
    );
    if (!available) {
      if (mounted) _showVoiceMissing();
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final spoken = result.recognizedWords.trim();
        if (spoken.isEmpty) return;
        _updateBody(note, appendSpoken(note.body, spoken));
      },
      listenOptions: SpeechListenOptions(partialResults: false),
    );
  }

  void _showVoiceMissing() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voice is not available')));
  }

  void _openLink(Note note, List<Note> allNotes, String title) {
    final match = findNoteByTitle(allNotes, title);
    if (match != null) {
      unawaited(context.push('/notes/${match.id}/edit'));
    } else {
      // `onCreateLinked` — link forward from here, then jump into a new,
      // already-titled note for it.
      _patch(note, (n) => n.copyWith(body: insertWikiLink(n.body, title)));
      final created = _controller.createBlank(title: title);
      unawaited(context.push('/notes/${created.id}/edit'));
    }
  }

  Future<void> _export(Note note) async {
    final heading = '# ${note.title.isEmpty ? 'Untitled note' : note.title}';
    final meta = [
      'tag: ${note.tag.isEmpty ? 'Note' : note.tag}',
      'notebook: ${note.notebook.isEmpty ? 'Inbox' : note.notebook}',
      if (note.dueAt != null)
        'due: ${note.dueAt}${note.dueTime != null ? ' ${note.dueTime}' : ''}',
      if (note.labels.isNotEmpty) 'labels: ${note.labels.join(', ')}',
    ].join(' · ');
    final markdown = [heading, meta, note.body].join('\n\n');
    await SharePlus.instance.share(
      ShareParams(
        text: markdown,
        title: '${note.title.isEmpty ? 'note' : note.title}.md',
      ),
    );
  }

  void _handleMenuAction(BuildContext context, Note note, String action) {
    switch (action) {
      case 'pin':
        _controller.togglePin(note.id);
      case 'archive':
        _controller.toggleArchive(note.id);
      case 'duplicate':
        final copy = _controller.duplicateNote(note.id);
        if (copy != null) context.pushReplacement('/notes/${copy.id}/edit');
      case 'trash':
        _controller.moveToTrash(note.id);
        context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteByIdProvider(widget.noteId));
    if (note == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('This note is gone.')),
      );
    }
    _syncControllers(note);

    final allNotes = ref.watch(notesControllerProvider);
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final swatches = theme.extension<NoteSwatches>()!;
    final paperColor = swatches.resolveHex(
      note.color.isEmpty ? NoteSwatches.paletteHex[0] : note.color,
    );
    final ink = ThemeData.estimateBrightnessForColor(paperColor) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF2B261F);

    return Scaffold(
      backgroundColor: paperColor,
      appBar: AppBar(
        backgroundColor: paperColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close editor',
          onPressed: () => context.pop(),
        ),
        title: Text(
          note.notebook.isEmpty ? 'Inbox' : note.notebook,
          style: TextStyle(fontSize: 14, color: ink.withValues(alpha: 0.7)),
        ),
        centerTitle: true,
        actions: [
          PaytmTick(
            active: note.confirmed,
            onToggle: () => _controller.toggleDone(note.id),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, note, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Text(note.pinned ? 'Unpin' : 'Pin'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(note.archived ? 'Unarchive' : 'Archive'),
              ),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              const PopupMenuItem(
                value: 'trash',
                child: Text('Move to trash'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Done', style: TextStyle(color: ink)),
          ),
          SizedBox(width: spacing.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            spacing.xl,
            spacing.sm,
            spacing.xl,
            spacing.xl,
          ),
          children: [
            TextField(
              controller: _titleController,
              onChanged: (value) =>
                  _patch(note, (n) => n.copyWith(title: value)),
              style: theme.textTheme.headlineLarge?.copyWith(color: ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
                hintStyle: TextStyle(color: ink.withValues(alpha: 0.35)),
              ),
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final hex in NoteSwatches.paletteHex)
                  _ColorDot(
                    color: swatches.resolveHex(hex),
                    selected: note.color == hex,
                    onTap: () => _patch(note, (n) => n.copyWith(color: hex)),
                  ),
              ],
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                _ToolChip(
                  icon: Icons.checklist,
                  label: 'Checklist',
                  onTap: () =>
                      _updateBody(note, insertChecklist(note.body)),
                ),
                _ToolChip(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Image',
                  onTap: () => _pickImage(note),
                ),
                _ToolChip(
                  icon: Icons.mic_none,
                  label: _listening ? 'Listening…' : 'Voice',
                  active: _listening,
                  onTap: () => _listen(note),
                ),
                _ToolChip(
                  icon: Icons.link,
                  label: 'Link',
                  active: _linkOpen,
                  onTap: () => setState(() => _linkOpen = !_linkOpen),
                ),
                _ToolChip(
                  icon: _preview
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  label: _preview ? 'Edit' : 'Preview',
                  active: _preview,
                  onTap: () => setState(() => _preview = !_preview),
                ),
                _ToolChip(
                  icon: Icons.ios_share,
                  label: 'Export',
                  onTap: () => _export(note),
                ),
              ],
            ),
            if (_linkOpen) ...[
              SizedBox(height: spacing.md),
              _LinkPanel(
                notes: linkableNotes(allNotes, note.id),
                onPick: (title) {
                  _updateBody(note, insertWikiLink(note.body, title));
                  setState(() => _linkOpen = false);
                },
              ),
            ],
            SizedBox(height: spacing.xl),
            if (_preview)
              MarkdownPreviewView(
                body: note.body,
                onToggleTask: (line) =>
                    _updateBody(note, toggleTaskLine(note.body, line)),
                onOpenLink: (title) => _openLink(note, allNotes, title),
              )
            else
              TextField(
                controller: _bodyController,
                onChanged: (value) =>
                    _patch(note, (n) => n.copyWith(body: value)),
                minLines: 10,
                maxLines: null,
                style: theme.textTheme.bodyLarge?.copyWith(color: ink),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Write here. Checklists use - [ ]. '
                      'Link notes with [[Title]].',
                  hintStyle: TextStyle(color: ink.withValues(alpha: 0.4)),
                ),
              ),
            _BacklinksPanel(note: note, allNotes: allNotes),
            SizedBox(height: spacing.xl),
            _DetailsToggle(
              note: note,
              open: _detailsOpen,
              onTap: () => setState(() => _detailsOpen = !_detailsOpen),
            ),
            if (_detailsOpen)
              _DetailsPanel(
                note: note,
                tagController: _tagController,
                labelDraftController: _labelDraftController,
                onTagChanged: (value) =>
                    _patch(note, (n) => n.copyWith(tag: value)),
                onNotebookChanged: (id, name) => _patch(
                  note,
                  (n) => n.copyWith(notebookId: id, notebook: name),
                ),
                onReminderChanged: (fields) =>
                    _patch(note, (n) => n.withReminder(fields)),
                onAddLabel: (label) {
                  if (label.isEmpty || note.labels.contains(label)) return;
                  _patch(note, (n) => n.copyWith(labels: [...n.labels, label]));
                  _labelDraftController.clear();
                },
                onRemoveLabel: (label) => _patch(
                  note,
                  (n) => n.copyWith(
                    labels: n.labels.where((l) => l != label).toList(),
                  ),
                ),
                allNotebooks: uniqueNotebooks(allNotes),
              ),
            SizedBox(height: spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${wordCount('${note.title} ${note.body}')} words',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ink.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  note.notebook,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _ColorDot({
  required final Color color,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.black87
                : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class const _ToolChip({
  required final IconData icon,
  required final String label,
  required final VoidCallback onTap,
  final bool active = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = active
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.65);
    final foreground = active ? Colors.white : theme.colorScheme.onSurface;
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _LinkPanel({
  required final List<Note> notes,
  required final void Function(String title) onPick,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link another note',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            Text(
              'Give another note a title, then link it here.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in notes)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      onTap: () => onPick(item.title),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class const _BacklinksPanel({
  required final Note note,
  required final List<Note> allNotes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final incoming = backlinksTo(note, allNotes);
    if (incoming.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Padding(
      padding: EdgeInsets.only(top: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linked from',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              for (final item in incoming)
                ActionChip(
                  label: Text(item.title.isEmpty ? 'Untitled' : item.title),
                  onPressed: () => context.push('/notes/${item.id}/edit'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _DetailsToggle({
  required final Note note,
  required final bool open,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = [
      note.notebook,
      formatDueChip(note.dueAt, note.dueTime),
      if (note.labels.isNotEmpty)
        '${note.labels.length} label${note.labels.length == 1 ? '' : 's'}',
      if (note.tag.isNotEmpty) note.tag,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

    return Material(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary.isEmpty ? 'Notebook, due date, labels' : summary,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _DetailsPanel({
  required final Note note,
  required final TextEditingController tagController,
  required final TextEditingController labelDraftController,
  required final void Function(String value) onTagChanged,
  required final void Function(String id, String name) onNotebookChanged,
  required final void Function(ReminderFields fields) onReminderChanged,
  required final void Function(String label) onAddLabel,
  required final void Function(String label) onRemoveLabel,
  required final List<String> allNotebooks,
}) extends StatelessWidget {
  Future<void> _pickNotebook(BuildContext context) async {
    final options = {'Inbox', ...allNotebooks}.toList()..sort();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in options)
              ListTile(title: Text(name), onTap: () => context.pop(name)),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New notebook'),
              onTap: () => context.pop('__new__'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == '__new__') {
      if (!context.mounted) return;
      final typed = await _promptNewNotebook(context);
      if (typed == null || typed.trim().isEmpty) return;
      onNotebookChanged(slugify(typed), typed.trim());
      return;
    }
    onNotebookChanged(slugify(choice), choice);
  }

  Future<String?> _promptNewNotebook(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New notebook'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: EdgeInsets.only(top: spacing.md),
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: theme.extension<AppRadii>()!.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Tag',
                  child: TextField(
                    controller: tagController,
                    onChanged: onTagChanged,
                    decoration: const InputDecoration(hintText: 'Work, home…'),
                  ),
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _LabeledField(
                  label: 'Notebook',
                  child: OutlinedButton(
                    onPressed: () => _pickNotebook(context),
                    child: Text(
                      note.notebook.isEmpty ? 'Inbox' : note.notebook,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          ReminderFieldsView(
            dueAt: note.dueAt,
            dueTime: note.dueTime,
            alertMinutes: note.alertMinutes,
            onChange: onReminderChanged,
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Labels',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              for (final label in note.labels)
                InputChip(
                  label: Text(label),
                  backgroundColor: theme
                      .extension<NoteSwatches>()!
                      .resolveHex(labelTint(label))
                      .withValues(alpha: 0.6),
                  onDeleted: () => onRemoveLabel(label),
                ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: labelDraftController,
                  decoration: const InputDecoration(hintText: 'Add a label'),
                  onSubmitted: onAddLabel,
                ),
              ),
              SizedBox(width: spacing.sm),
              TextButton(
                onPressed: () => onAddLabel(labelDraftController.text.trim()),
                child: const Text('Add'),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              for (final preset in labelPresets)
                if (!note.labels.contains(preset))
                  ActionChip(
                    label: Text(preset),
                    onPressed: () => onAddLabel(preset),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _LabeledField({
  required final String label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
