/// Direct port of `lib/notes/markdown.ts` — the source's intentionally
/// minimal custom mini-Markdown (headings h1–h3, `- [ ]` tasks, `-`/`•`
/// bullets, images; no bold/italic/code/tables — a deliberate scope
/// decision in the source, not a gap here).
library;

/// One parsed line of a note's body.
sealed class const MarkdownBlock();

class const HeadingBlock({required final int level, required final String text})
    extends MarkdownBlock;

class const TaskBlock({
  required final bool checked,
  required final String text,
  required final int line,
}) extends MarkdownBlock;

class const ListBlock({required final String text}) extends MarkdownBlock;

class const ImageBlock({required final String src, required final String alt})
    extends MarkdownBlock;

class const ParagraphBlock({required final String text}) extends MarkdownBlock;

final RegExp _headingRe = RegExp(r'^(#{1,3})\s+(.*)$');
final RegExp _imageRe = RegExp(r'^!\[([^\]]*)\]\((.+)\)$');
final RegExp _taskRe = RegExp(r'^\s*- \[( |x|X)\]\s+(.*)$');
final RegExp _listRe = RegExp(r'^\s*-\s+');

List<MarkdownBlock> parseMarkdown(String body) {
  if (body.trim().isEmpty) return const [];
  final blocks = <MarkdownBlock>[];
  final lines = body.split('\n');
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    if (line.trim().isEmpty) continue;

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      blocks.add(
        HeadingBlock(level: heading.group(1)!.length, text: heading.group(2)!),
      );
      continue;
    }

    final image = _imageRe.firstMatch(line.trim());
    if (image != null) {
      blocks.add(ImageBlock(src: image.group(2)!, alt: image.group(1)!));
      continue;
    }

    final task = _taskRe.firstMatch(line);
    if (task != null) {
      blocks.add(
        TaskBlock(
          checked: task.group(1)!.toLowerCase() == 'x',
          text: task.group(2)!,
          line: lineIndex,
        ),
      );
      continue;
    }

    if (_listRe.hasMatch(line)) {
      blocks.add(ListBlock(text: line.replaceFirst(_listRe, '')));
      continue;
    }

    blocks.add(ParagraphBlock(text: line));
  }
  return blocks;
}

/// Appends a fresh `- [ ] ` line — matches `insertChecklist`.
String insertChecklist(String body) {
  final prefix = body.trim().isNotEmpty
      ? '${body.replaceAll(RegExp(r'\s+$'), '')}\n'
      : '';
  return '$prefix- [ ] ';
}

/// Appends `![alt](src)` as its own paragraph — matches
/// `insertImageMarkdown`. `src` is a `data:` URI in this build (see
/// `note_card.dart`'s doc comment on why there's no separate blob store).
String insertImageMarkdown(String body, String src, [String alt = 'image']) {
  final prefix = body.trim().isNotEmpty
      ? '${body.replaceAll(RegExp(r'\s+$'), '')}\n\n'
      : '';
  return '$prefix![$alt]($src)';
}

/// Task-checkbox totals for one body — matches `checklistProgress`.
class const ChecklistProgress({
  required final int total,
  required final int done,
});

ChecklistProgress checklistProgress(String body) {
  final tasks = RegExp(r'^\s*- \[[ xX]\]', multiLine: true).allMatches(body);
  final done = RegExp(r'^\s*- \[[xX]\]', multiLine: true).allMatches(body);
  return ChecklistProgress(total: tasks.length, done: done.length);
}

/// Matches `wordCount`.
int wordCount(String text) {
  final words = RegExp(r'\S+').allMatches(text.trim());
  return words.length;
}

/// Appends dictated speech to the body with sensible punctuation-aware
/// spacing — matches `lib/native/speech.ts`'s `appendSpoken`.
String appendSpoken(String current, String spoken) {
  final next = spoken.trim();
  if (next.isEmpty) return current;
  if (current.trim().isEmpty) return next;
  final trimmedCurrent = current.trim();
  final glue = RegExp(r'[\n.!?]$').hasMatch(trimmedCurrent) ? '\n' : ' ';
  return '${current.replaceAll(RegExp(r'\s+$'), '')}$glue$next';
}

/// Toggles the checkbox on one body line, matching `toggleTaskLine`.
String toggleTaskLine(String body, int lineIndex) {
  final lines = body.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return body;
  final line = lines[lineIndex];
  if (line.contains('- [ ]')) {
    lines[lineIndex] = line.replaceFirst('- [ ]', '- [x]');
  } else if (line.contains('- [x]')) {
    lines[lineIndex] = line.replaceFirst('- [x]', '- [ ]');
  } else {
    return body;
  }
  return lines.join('\n');
}

/// Strips images/wiki-links/heading markers for the card's plain-text
/// preview — matches `cardBodyPreview`.
String cardBodyPreview(String body, [String fallbackPreview = '']) {
  final text = (body.isNotEmpty ? body : fallbackPreview).trim();
  return text
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '')
      .replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
      .trim();
}

/// What a `NoteCard` actually renders: up to 6 tasks, up to 6 bullets, and
/// the remaining prose — matches `cardSurface`.
class const NoteCardSurface({
  required final List<TaskBlock> shownTasks,
  required final List<ListBlock> shownBullets,
  required final String prose,
});

/// Bounded LRU memoization for [cardSurface] — every visible `NoteCard`
/// calls this on every rebuild of the notes grid (any note anywhere
/// changing invalidates the whole list, since `visibleNoteListProvider`
/// hands back a fresh `List` each time), which otherwise means re-running
/// several regex passes over a note's full body just to re-render cards
/// whose own content hasn't changed at all. Capped so a long session full
/// of distinct edited bodies can't grow this unboundedly. Keyed by a
/// record (not a concatenated string) so two different (body,
/// fallbackPreview) pairs can never collide onto the same cache entry.
const _cardSurfaceCacheLimit = 64;
final Map<(String, String), NoteCardSurface> _cardSurfaceCache = {};

NoteCardSurface cardSurface(String body, [String fallbackPreview = '']) {
  final key = (body, fallbackPreview);
  final cached = _cardSurfaceCache.remove(key);
  if (cached != null) {
    _cardSurfaceCache[key] = cached; // Re-insert at the end (most-recent).
    return cached;
  }
  final normalized = body.replaceAll(RegExp(r'^•\s+', multiLine: true), '- ');
  final blocks = parseMarkdown(normalized);
  final tasks = blocks.whereType<TaskBlock>().toList();
  final bullets = blocks.whereType<ListBlock>().toList();
  final prose = cardBodyPreview(normalized, fallbackPreview)
      .replaceAll(RegExp(r'^\s*- \[[ xX]\].*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*-\s+.+$', multiLine: true), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  final result = NoteCardSurface(
    shownTasks: tasks.take(6).toList(),
    shownBullets: bullets.take(6).toList(),
    prose: prose,
  );
  _cardSurfaceCache[key] = result;
  if (_cardSurfaceCache.length > _cardSurfaceCacheLimit) {
    _cardSurfaceCache.remove(_cardSurfaceCache.keys.first);
  }
  return result;
}
