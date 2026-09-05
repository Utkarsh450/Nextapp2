import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

/// Direct port of the filter/sort logic in `lib/notes/filters.ts`.

enum NoteFilter { all, open, done, due, archived, trash }

enum NoteSort { newest, oldest, title, tag }

/// Derives a `notebookId` from a typed notebook name — matches `slugify`
/// in `lib/notes/types.ts`.
String slugify(String name) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'inbox' : slug;
}

/// `moveNote` — reorders [notes] by dragging `fromId` next to `toId`,
/// writing back through `order` exactly as the source does. Kept even
/// though drag-to-reorder UI is deferred to its own pass — see the
/// screen-completion notes for this build.
List<Note> moveNote(List<Note> notes, int fromId, int toId) {
  final from = notes.indexWhere((n) => n.id == fromId);
  final to = notes.indexWhere((n) => n.id == toId);
  if (from < 0 || to < 0 || from == to) return notes;
  final next = List<Note>.of(notes);
  final item = next.removeAt(from);
  next.insert(to, item);
  return [
    for (var i = 0; i < next.length; i++) next[i].copyWith(order: i),
  ];
}

/// `trashNote` — moves a note to trash: sets `trashedAt`, unpins it.
Note trashNote(Note note, int now) =>
    note.copyWith(trashedAt: now, pinned: false, updatedAt: now);

/// `restoreFromTrash` — clears `trashedAt`.
Note restoreFromTrash(Note note, int now) =>
    note.copyWith(trashedAt: null, updatedAt: now);

List<String> uniqueNotebooks(List<Note> notes) {
  return notes
      .where((n) => !n.archived && n.trashedAt == null)
      .map((n) => n.notebook.trim().isEmpty ? 'Inbox' : n.notebook.trim())
      .toSet()
      .toList()
    ..sort();
}

List<String> uniqueTags(List<Note> notes) {
  return notes
      .where(
        (n) => !n.archived && n.trashedAt == null && n.tag.trim().isNotEmpty,
      )
      .map((n) => n.tag.trim())
      .toSet()
      .toList()
    ..sort();
}

List<String> uniqueLabels(List<Note> notes) {
  return notes
      .where((n) => !n.archived && n.trashedAt == null)
      .expand((n) => n.labels)
      .toSet()
      .toList()
    ..sort();
}

List<String> uniqueColors(List<Note> notes) {
  final values = <String>{};
  for (final n in notes) {
    if (!n.archived && n.trashedAt == null && n.color.isNotEmpty) {
      values.add(n.color);
    }
  }
  return values.toList();
}

/// `visibleNotes` — the single source of truth for what a filter/sort/
/// search combination shows. Ported field-for-field from `filters.ts` so
/// there is exactly one place this logic can drift from the original.
List<Note> visibleNotes({
  required List<Note> notes,
  String search = '',
  NoteSort sortKey = NoteSort.newest,
  NoteFilter filterKey = NoteFilter.all,
  String? notebookId,
  String? tag,
  String? label,
  String? color,
  String? today,
  String? ownerEmail,
}) {
  final query = search.trim().toLowerCase();
  final at = today ?? todayIso();

  final filtered = notes.where((note) {
    if (ownerEmail != null && note.ownerEmail != ownerEmail) return false;
    if (filterKey == NoteFilter.trash) return note.trashedAt != null;
    if (note.trashedAt != null) return false;
    if (filterKey == NoteFilter.archived) return note.archived;
    if (note.archived) return false;
    if (filterKey == NoteFilter.done && !note.confirmed) return false;
    if (filterKey == NoteFilter.open && note.confirmed) return false;
    if (filterKey == NoteFilter.due &&
        !isDueToday(note.dueAt, at) &&
        !isOverdue(note.dueAt, at)) {
      return false;
    }
    if (notebookId != null && note.notebookId != notebookId) return false;
    if (tag != null && note.tag.trim() != tag) return false;
    if (label != null && !note.labels.contains(label)) return false;
    if (color != null && note.color != color) return false;
    if (query.isEmpty) return true;
    final haystack = [
      note.title,
      note.tag,
      note.preview,
      note.notebook,
      note.body,
      cardBodyPreview(note.body, note.preview),
      ...note.labels,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }).toList();

  return filtered
    ..sort((a, b) {
      if (filterKey != NoteFilter.trash && a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }
      switch (sortKey) {
        case NoteSort.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case NoteSort.title:
          return a.title.compareTo(b.title);
        case NoteSort.tag:
          return a.tag.compareTo(b.tag);
        case NoteSort.newest:
          if (a.order != b.order) return a.order.compareTo(b.order);
          return b.createdAt.compareTo(a.createdAt);
      }
    });
}

List<Note> upcomingReminders(List<Note> notes, [String? today]) {
  final at = today ?? todayIso();
  return notes
      .where(
        (n) =>
            n.trashedAt == null &&
            !n.archived &&
            n.dueAt != null &&
            (isDueToday(n.dueAt, at) || isOverdue(n.dueAt, at)),
      )
      .toList();
}
