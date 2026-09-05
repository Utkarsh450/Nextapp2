/// Direct port of `lib/notes/backlinks.ts` — `[[Note Title]]` wiki-links.
library;

import 'package:notes_app/features/notes/domain/note.dart';

final RegExp _wikiRe = RegExp(r'\[\[([^\[\]]+)\]\]');

/// Every distinct linked title in [body], in first-seen order.
List<String> parseWikiLinks(String body) {
  final titles = <String>[];
  final seen = <String>{};
  for (final match in _wikiRe.allMatches(body)) {
    final title = match.group(1)?.trim();
    if (title == null || title.isEmpty) continue;
    final key = title.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    titles.add(title);
  }
  return titles;
}

/// Appends `[[title]]` unless it's already linked — matches
/// `insertWikiLink`.
String insertWikiLink(String body, String title) {
  final name = title.trim();
  if (name.isEmpty) return body;
  final token = '[[$name]]';
  if (body.contains(token)) return body;
  final prefix = body.trim().isNotEmpty
      ? '${body.replaceAll(RegExp(r'\s+$'), '')} '
      : '';
  return '$prefix$token';
}

/// One run of plain text or one `[[link]]` — matches `wikiSegments`.
class const WikiSegment({required final String text, final String? link});

/// Splits [text] into plain-text and link segments for rendering, matching
/// `wikiSegments`.
List<WikiSegment> wikiSegments(String text) {
  final parts = <WikiSegment>[];
  var last = 0;
  for (final match in _wikiRe.allMatches(text)) {
    if (match.start > last) {
      parts.add(WikiSegment(text: text.substring(last, match.start)));
    }
    final title = match.group(1)!.trim();
    parts.add(WikiSegment(text: title, link: title));
    last = match.start + match.group(0)!.length;
  }
  if (last < text.length) parts.add(WikiSegment(text: text.substring(last)));
  return parts.isNotEmpty ? parts : [WikiSegment(text: text)];
}

List<Note> _liveNotes(List<Note> notes) =>
    notes.where((n) => n.trashedAt == null && !n.archived).toList();

/// Case-insensitive title lookup among live (non-trashed, non-archived)
/// notes — matches `findNoteByTitle`.
Note? findNoteByTitle(List<Note> notes, String title) {
  final key = title.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final note in _liveNotes(notes)) {
    if (note.title.trim().toLowerCase() == key) return note;
  }
  return null;
}

/// Live notes that link *to* [note] — matches `backlinksTo`.
List<Note> backlinksTo(Note note, List<Note> notes) {
  final title = note.title.trim().toLowerCase();
  if (title.isEmpty) return const [];
  return _liveNotes(notes).where((item) {
    if (item.id == note.id) return false;
    return parseWikiLinks(
      item.body,
    ).any((link) => link.toLowerCase() == title);
  }).toList();
}

/// Every other live, titled note — the "link another note" picker list —
/// matches `linkableNotes`.
List<Note> linkableNotes(List<Note> notes, int currentId) {
  return _liveNotes(notes)
      .where((n) => n.id != currentId && n.title.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));
}
