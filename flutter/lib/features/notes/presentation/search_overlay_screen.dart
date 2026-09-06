import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_highlight.dart';
import 'package:notes_app/features/notes/domain/note_labels.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/domain/search_history_controller.dart';

/// Port of `features/notes/SearchOverlay.tsx` — a full-screen search
/// surface (feature-audit #10), reached from the Notes tab's search
/// button. Modeled as a real pushed route (`/notes/search`) rather than a
/// boolean-toggled overlay, the natural go_router equivalent.
class const SearchOverlayScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchOverlayScreen> createState() =>
      _SearchOverlayScreenState();
}

class _SearchOverlayScreenState extends ConsumerState<SearchOverlayScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(noteSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryControllerProvider.notifier).remember(trimmed);
    }
    ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    context.pop();
  }

  void _pickRecent(String query) {
    ref.read(noteSearchQueryProvider.notifier).set(query);
    ref.read(searchHistoryControllerProvider.notifier).remember(query);
    context.pop();
  }

  void _pickLabel(String? label) {
    ref.read(noteLabelFilterProvider.notifier).set(label);
    ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    context.pop();
  }

  void _pickColor(String? color) {
    ref.read(noteColorFilterProvider.notifier).set(color);
    ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    context.pop();
  }

  void _openNote(int id) {
    context.pop();
    unawaited(context.push('/notes/$id'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final swatches = theme.extension<NoteSwatches>()!;
    final query = ref.watch(noteSearchQueryProvider);
    final recents = ref.watch(searchHistoryControllerProvider);
    final labels = ref.watch(noteLabelOptionsProvider);
    final activeLabel = ref.watch(noteLabelFilterProvider);
    final activeColor = ref.watch(noteColorFilterProvider);
    final hits = ref.watch(searchHitsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: theme.textTheme.titleLarge,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search notes',
                      ),
                      onChanged: (value) =>
                          ref.read(noteSearchQueryProvider.notifier).set(value),
                      onSubmitted: _commit,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    tooltip: 'Close search',
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  spacing.md,
                  spacing.lg,
                  spacing.xxxl,
                ),
                children: [
                  _SectionLabel(label: 'Colors', theme: theme),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in NoteSwatches.paletteHex)
                        _ColorDot(
                          key: ValueKey('search-color-$color'),
                          fill: swatches.resolveHex(color),
                          selected: activeColor == color,
                          onTap: () =>
                              _pickColor(activeColor == color ? null : color),
                        ),
                    ],
                  ),
                  if (labels.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Labels', theme: theme),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final label in labels)
                          _TextChip(
                            label: label,
                            tint: swatches.resolveHex(labelTint(label)),
                            selected: activeLabel == label,
                            onTap: () =>
                                _pickLabel(activeLabel == label ? null : label),
                          ),
                      ],
                    ),
                  ],
                  if (recents.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Recent', theme: theme),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in recents)
                          _TextChip(
                            label: item,
                            selected: false,
                            onTap: () => _pickRecent(item),
                          ),
                      ],
                    ),
                  ],
                  if (query.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Matches', theme: theme),
                    const SizedBox(height: 8),
                    if (hits.isEmpty)
                      Text(
                        'No notes match that search.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      )
                    else
                      for (final note in hits.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MatchRow(
                            note: note,
                            query: query,
                            onTap: () => _openNote(note.id),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _SectionLabel({
  required final String label,
  required final ThemeData theme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 2.3,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}

class const _ColorDot({
  required final Color fill,
  required final bool selected,
  required final VoidCallback onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? const Color(0xFF2B261F)
                : Colors.black.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class const _TextChip({
  required final String label,
  required final bool selected,
  required final VoidCallback onTap,
  final Color? tint,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(999);
    final fallback = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.62);
    return Material(
      color: tint?.withValues(alpha: 0.6) ?? fallback,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected
                ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                : null,
          ),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
      ),
    );
  }
}

class const _MatchRow({
  required final Note note,
  required final String query,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);
    final title = note.title.isEmpty ? 'Untitled' : note.title;
    final snippet = note.body.isEmpty
        ? null
        : note.body
              .replaceAll(RegExp(r'\s+'), ' ')
              .substring(0, note.body.length.clamp(0, 120));

    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HighlightedText(
                text: title,
                query: query,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (snippet != null) ...[
                const SizedBox(height: 4),
                _HighlightedText(
                  text: snippet,
                  query: query,
                  maxLines: 2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

class const _HighlightedText({
  required final String text,
  required final String query,
  final TextStyle? style,
  final int? maxLines,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final segments = highlightSegments(text, query);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final segment in segments)
            TextSpan(
              text: segment.text,
              style: segment.match
                  ? const TextStyle(backgroundColor: Color(0xCCF9D368))
                  : null,
            ),
        ],
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
