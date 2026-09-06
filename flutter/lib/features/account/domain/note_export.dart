/// Direct port of the export half of `lib/notes/export.ts`.
///
/// `attachments` has no equivalent here — `Note.attachments` isn't
/// modeled yet (see `note.dart`'s doc comment) — so the "## Attachments"
/// section the source appends never applies in this build.
library;

import 'dart:convert';

import 'package:notes_app/features/notes/domain/note.dart';

String exportNotesMarkdown(List<Note> notes) {
  return notes
      .map((note) {
        final heading =
            '# ${note.title.isEmpty ? 'Untitled note' : note.title}';
        final meta = [
          'tag: ${note.tag.isEmpty ? 'Note' : note.tag}',
          'notebook: ${note.notebook.isEmpty ? 'Inbox' : note.notebook}',
          if (note.dueAt != null)
            'due: ${note.dueAt}${note.dueTime != null ? ' ${note.dueTime}' : ''}',
          if (note.labels.isNotEmpty) 'labels: ${note.labels.join(', ')}',
        ].join(' · ');
        final body = note.body.replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\(notes-blob:[^)]+\)'),
          (m) => '![${m.group(1)}](attachment)',
        );
        return [
          heading,
          meta,
          note.preview,
          body,
        ].where((part) => part.trim().isNotEmpty).join('\n\n');
      })
      .join('\n\n---\n\n');
}

/// Matches `exportNotesJson` — pretty-printed, matching the source's
/// `JSON.stringify(notes, null, 2)`.
String exportNotesJson(List<Note> notes) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(notes.map(_noteToJson).toList());
}

Map<String, dynamic> _noteToJson(Note note) => {
  'id': note.id,
  'ownerEmail': note.ownerEmail,
  'title': note.title,
  'tag': note.tag,
  'preview': note.preview,
  'notebookId': note.notebookId,
  'notebook': note.notebook,
  'confirmed': note.confirmed,
  'body': note.body,
  'pinned': note.pinned,
  'archived': note.archived,
  'trashedAt': note.trashedAt,
  'color': note.color,
  'dueAt': note.dueAt,
  'dueTime': note.dueTime,
  'alertMinutes': note.alertMinutes,
  'remindAt': note.remindAt,
  'labels': note.labels,
  'order': note.order,
  'createdAt': note.createdAt,
  'updatedAt': note.updatedAt,
};

/// Simplified port of `importNotesJson` — the source runs each imported
/// item through `normalizeNote` to migrate old/legacy field shapes; there
/// is no legacy format for this Flutter model to migrate from, so this
/// reads the same JSON shape [exportNotesJson] writes directly. An id
/// that collides with an existing note gets a fresh one, same as source.
List<Note> importNotesJson(String raw, List<Note> existing, String ownerEmail) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('Backup must be an array of notes');
  }
  final usedIds = existing.map((n) => n.id).toSet();
  final imported = <Note>[];
  for (final (index, item) in decoded.indexed) {
    final map = item as Map<String, dynamic>;
    final rawId = (map['id'] as num?)?.toInt() ?? existing.length + index;
    final id = usedIds.contains(rawId)
        ? DateTime.now().millisecondsSinceEpoch + index
        : rawId;
    usedIds.add(id);
    imported.add(
      Note(
        id: id,
        ownerEmail: ownerEmail,
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
        updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
        color: map['color'] as String? ?? '#C5CA8A',
        title: map['title'] as String? ?? '',
        tag: map['tag'] as String? ?? '',
        preview: map['preview'] as String? ?? '',
        notebookId: map['notebookId'] as String? ?? 'inbox',
        notebook: map['notebook'] as String? ?? 'Inbox',
        confirmed: map['confirmed'] as bool? ?? false,
        body: map['body'] as String? ?? '',
        pinned: map['pinned'] as bool? ?? false,
        archived: map['archived'] as bool? ?? false,
        trashedAt: (map['trashedAt'] as num?)?.toInt(),
        dueAt: map['dueAt'] as String?,
        dueTime: map['dueTime'] as String?,
        alertMinutes: (map['alertMinutes'] as num?)?.toInt() ?? -1,
        remindAt: map['remindAt'] as String?,
        labels: (map['labels'] as List?)?.cast<String>() ?? const [],
        order: (map['order'] as num?)?.toInt() ?? 0,
      ),
    );
  }
  return [...existing, ...imported];
}
