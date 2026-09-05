import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:notes_app/features/notes/domain/note_backlinks.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';

/// Port of `features/notes/MarkdownPreview.tsx` — read-only rendering of
/// the note body's parsed blocks, with tappable checkboxes and wiki-links.
///
/// Images render straight from a `data:` URI via [Image.memory] — there's
/// no separate blob store in this build (see `note_card.dart`'s doc
/// comment), so `blobUrls` indirection from the source doesn't apply.
class const MarkdownPreviewView({
  required final String body,
  required final void Function(int line) onToggleTask,
  required final void Function(String title) onOpenLink,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdown(body);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    if (blocks.isEmpty) {
      return Text('Start writing…', style: TextStyle(color: muted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildBlock(context, block),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, MarkdownBlock block) {
    final theme = Theme.of(context);
    return switch (block) {
      HeadingBlock(:final level, :final text) => Text(
        text,
        style: (level == 1
                ? theme.textTheme.titleLarge
                : level == 2
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyLarge)
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      TaskBlock(:final checked, :final text, :final line) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onToggleTask(line),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _LinkedText(
                text: text,
                onOpenLink: onOpenLink,
                muted: checked,
              ),
            ),
          ),
        ],
      ),
      ListBlock(:final text) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: _LinkedText(text: text, onOpenLink: onOpenLink)),
          ],
        ),
      ),
      ImageBlock(:final src, :final alt) => _buildImage(src, alt),
      ParagraphBlock(:final text) => _LinkedText(
        text: text,
        onOpenLink: onOpenLink,
      ),
    };
  }

  Widget _buildImage(String src, String alt) {
    final match = RegExp(r'^data:[^;]+;base64,(.+)$').firstMatch(src);
    if (match == null) return const SizedBox.shrink();
    try {
      final bytes = base64Decode(match.group(1)!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          bytes,
          semanticLabel: alt,
          height: 192,
          fit: BoxFit.cover,
        ),
      );
    } on FormatException {
      return const SizedBox.shrink();
    }
  }
}

/// Renders [text] as wrapped inline runs so `[[wiki links]]` can be
/// individually tappable — a `Wrap` of small widgets instead of a
/// `Text.rich`/`TapGestureRecognizer` tree, so there's no recognizer
/// lifecycle to manage for what is otherwise a fully stateless view.
class const _LinkedText({
  required final String text,
  required final void Function(String title) onOpenLink,
  final bool muted = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = muted
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface;
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      color: baseColor,
      decoration: muted ? TextDecoration.lineThrough : null,
    );

    return Wrap(
      children: [
        for (final segment in wikiSegments(text))
          if (segment.link != null)
            GestureDetector(
              onTap: () => onOpenLink(segment.link!),
              child: Text(
                segment.text,
                style: baseStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: baseColor.withValues(alpha: 0.4),
                ),
              ),
            )
          else
            Text(segment.text, style: baseStyle),
      ],
    );
  }
}
