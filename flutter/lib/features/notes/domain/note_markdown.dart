/// Direct port of `lib/notes/markdown.ts` — the source's intentionally
/// minimal custom mini-Markdown (headings h1–h3, `- [ ]` tasks, `-`/`•`
/// bullets, images; no bold/italic/code/tables — a deliberate scope
/// decision in the source, not a gap here).
library;

/// One parsed line of a note's body.
sealed class const MarkdownBlock();

class const HeadingBlock({
  required final int level,
  required final String text,
}) extends MarkdownBlock;

class const TaskBlock({
  required final bool checked,
  required final String text,
  required final int line,
}) extends MarkdownBlock;

class const ListBlock({required final String text}) extends MarkdownBlock;

class const ParagraphBlock({required final String text})
    extends MarkdownBlock;

final RegExp _headingRe = RegExp(r'^(#{1,3})\s+(.*)$');
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

NoteCardSurface cardSurface(String body, [String fallbackPreview = '']) {
  final normalized = body.replaceAll(RegExp(r'^•\s+', multiLine: true), '- ');
  final blocks = parseMarkdown(normalized);
  final tasks = blocks.whereType<TaskBlock>().toList();
  final bullets = blocks.whereType<ListBlock>().toList();
  final prose = cardBodyPreview(normalized, fallbackPreview)
      .replaceAll(RegExp(r'^\s*- \[[ xX]\].*$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*-\s+.+$', multiLine: true), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return NoteCardSurface(
    shownTasks: tasks.take(6).toList(),
    shownBullets: bullets.take(6).toList(),
    prose: prose,
  );
}
