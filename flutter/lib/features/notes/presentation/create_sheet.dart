import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/note_templates.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Shows the Quick capture sheet (`features/notes/CreateSheet.tsx`,
/// feature-audit #9) as a modal bottom sheet, then opens the editor for
/// whatever note it creates — matching the source's own
/// `onCreate` → `editNote(note.id)` flow.
///
/// **Reached from:** the dock's + button (`shell/app_dock.dart`) — either
/// its "Quick capture" row in the "Add…" menu, or a long press on the +
/// itself, which bypasses that menu entirely (matching the source's own
/// 480ms hold-to-capture shortcut in `AppTabs.tsx`).
Future<void> showCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CreateSheet(),
  );
}

class const _CreateSheet() extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  void _saveBlank() {
    final note = ref
        .read(notesControllerProvider.notifier)
        .createBlank(title: _titleController.text, body: _bodyController.text);
    Navigator.of(context).pop();
    unawaited(context.push('/notes/${note.id}/edit'));
  }

  /// Matches the source's own quirk: picking a template chip starts a
  /// fresh templated note and discards whatever was already typed in the
  /// title/body fields — not a bug, `onCreate`'s handler in `NotesApp.tsx`
  /// really does ignore them once a `template` key is present.
  void _saveTemplate(TemplateKey key) {
    final note = ref
        .read(notesControllerProvider.notifier)
        .createFromTemplate(key);
    Navigator.of(context).pop();
    unawaited(context.push('/notes/${note.id}/edit'));
  }

  Future<void> _listen() async {
    if (_listening) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Voice is not available')));
      }
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final spoken = result.recognizedWords.trim();
        if (spoken.isEmpty) return;
        final next = appendSpoken(_bodyController.text, spoken);
        _bodyController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      },
      listenOptions: SpeechListenOptions(partialResults: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final radii = theme.extension<AppRadii>()!;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: radii.cardRadius.topLeft),
          ),
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.md,
            spacing.lg,
            spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUICK CAPTURE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 2.3,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
              TextField(
                controller: _titleController,
                autofocus: true,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Title',
                ),
              ),
              SizedBox(height: spacing.xs),
              TextField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'What’s on your mind?',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              SizedBox(height: spacing.sm),
              Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.sm,
                children: [
                  for (final key in TemplateKey.values)
                    ActionChip(
                      label: Text(noteTemplates[key]!.name),
                      onPressed: () => _saveTemplate(key),
                    ),
                  ActionChip(
                    avatar: Icon(
                      _listening ? Icons.mic : Icons.mic_none,
                      size: 16,
                    ),
                    label: Text(_listening ? 'Listening…' : 'Voice'),
                    onPressed: _listen,
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveBlank,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Save note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
