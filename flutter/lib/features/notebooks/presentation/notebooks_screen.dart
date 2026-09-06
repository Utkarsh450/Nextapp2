import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notebooks/domain/notebook.dart';
import 'package:notes_app/features/notebooks/domain/notebooks_controller.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/notes/NotebooksView.tsx` — the Notebooks library
/// (feature-audit #11): create a notebook, rename/recolor an existing one,
/// and tap one to filter the Notes tab by it. There is deliberately no
/// delete-notebook action anywhere here, matching the source exactly.
///
/// **Not ported:** the `CardTape` washi-tape decoration on the compose
/// form — `components/ui/PaperStickers.tsx` isn't built yet (same
/// call-out as `CardTape` in `habits_board.dart`). The "New notebook"
/// tile's dashed outline is also approximated as a solid border — Flutter
/// has no built-in dashed `Border`, and a custom dash painter felt like
/// overkill for one cosmetic outline.
class const NotebooksScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends ConsumerState<NotebooksScreen> {
  bool _composing = false;
  String _composeColor = NoteSwatches.paletteHex[0];
  final _nameController = TextEditingController();

  String? _editingId;
  final _renameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  void _makeNotebook() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    ref
        .read(notebooksControllerProvider.notifier)
        .addNotebook(name, _composeColor);
    _nameController.clear();
    setState(() {
      _composeColor = NoteSwatches.paletteHex[0];
      _composing = false;
    });
  }

  void _startEditing(Notebook notebook) {
    _renameController.text = notebook.name;
    setState(() => _editingId = notebook.id);
  }

  void _commitRename(String id) {
    final next = _renameController.text.trim();
    if (next.isNotEmpty) {
      ref.read(notebooksControllerProvider.notifier).renameNotebook(id, next);
    }
    setState(() => _editingId = null);
  }

  void _openNotebook(String id) {
    ref.read(noteNotebookFilterProvider.notifier).set(id);
    ref.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    context.go('/notes');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final swatches = theme.extension<NoteSwatches>()!;
    final notebooks = ref.watch(notebooksControllerProvider);
    final counts = ref.watch(liveNotebookCountsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.sm,
            spacing.lg,
            spacing.xxxl,
          ),
          children: [
            Text(
              'Your library',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Books to fill',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 29.6,
                fontWeight: FontWeight.bold,
                height: 1.05,
                letterSpacing: -1.18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a book to open it. The pencil lets you rename and '
              'recolor.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: spacing.xl),
            if (_composing) ...[
              _ComposeForm(
                nameController: _nameController,
                color: _composeColor,
                swatches: swatches,
                onColor: (c) => setState(() => _composeColor = c),
                onSubmit: _makeNotebook,
                onCancel: () {
                  _nameController.clear();
                  setState(() => _composing = false);
                },
              ),
              SizedBox(height: spacing.md),
            ],
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // A fixed `mainAxisExtent` (rather than a width-derived
              // `childAspectRatio`) is a hard-won lesson from the Today
              // dashboard's notebook tiles: an aspect ratio makes height
              // depend on the grid's width, which can undershoot the
              // content's real height on a narrow screen. The source's
              // CSS only sets a *minimum* height (`min-h-[11.2rem]`) and
              // lets content grow it; a generous fixed extent is the
              // simplest equivalent that can't overflow.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 179,
              ),
              children: [
                for (final (index, notebook) in notebooks.indexed)
                  _NotebookTile(
                    key: ValueKey('notebook-${notebook.id}'),
                    notebook: notebook,
                    count: counts[notebook.id] ?? 0,
                    rotation: index % 4 == 1
                        ? -1.4
                        : index % 4 == 2
                        ? 1.1
                        : 0,
                    color: swatches.resolveHex(notebook.color),
                    editing: _editingId == notebook.id,
                    renameController: _renameController,
                    swatches: swatches,
                    onOpen: () => _openNotebook(notebook.id),
                    onStartEditing: () => _startEditing(notebook),
                    onCommitRename: () => _commitRename(notebook.id),
                    onCancelEditing: () => setState(() => _editingId = null),
                    onRecolor: (c) => ref
                        .read(notebooksControllerProvider.notifier)
                        .recolorNotebook(notebook.id, c),
                  ),
                _AddNotebookTile(
                  onTap: () => setState(() => _composing = true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class const _ComposeForm({
  required final TextEditingController nameController,
  required final String color,
  required final NoteSwatches swatches,
  required final ValueChanged<String> onColor,
  required final VoidCallback onSubmit,
  required final VoidCallback onCancel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radii = Theme.of(context).extension<AppRadii>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: swatches.resolveHex(color),
        borderRadius: radii.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New notebook',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            autofocus: true,
            onSubmitted: (_) => onSubmit(),
            style: const TextStyle(
              fontSize: 21.6,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.65,
              color: _ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Work, recipes, late-night ideas…',
              hintStyle: TextStyle(color: _ink.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in NoteSwatches.paletteHex)
                _ColorDot(
                  hex: item,
                  size: 32,
                  fill: swatches.resolveHex(item),
                  selected: color == item,
                  onTap: () => onColor(item),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1814),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Make notebook'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    foregroundColor: _ink,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _ColorDot({
  required final String hex,
  required final double size,
  required final Color fill,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? _ink : Colors.black.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class const _NotebookTile({
  required final Notebook notebook,
  required final int count,
  required final double rotation,
  required final Color color,
  required final bool editing,
  required final TextEditingController renameController,
  required final NoteSwatches swatches,
  required final VoidCallback onOpen,
  required final VoidCallback onStartEditing,
  required final VoidCallback onCommitRename,
  required final VoidCallback onCancelEditing,
  required final ValueChanged<String> onRecolor,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final card = Material(
      color: color,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: editing ? _buildEditing(context) : _buildIdle(context),
      ),
    );
    final tile = rotation == 0
        ? card
        : Transform.rotate(angle: rotation * 3.1415926535 / 180, child: card);

    if (!editing) {
      return Stack(
        children: [
          tile,
          Positioned(
            right: 6,
            top: 6,
            child: _PencilButton(label: notebook.name, onTap: onStartEditing),
          ),
        ],
      );
    }
    return tile;
  }

  Widget _buildIdle(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined, size: 18, color: _ink),
          const SizedBox(height: 20),
          Text(
            notebook.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16.8,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'note' : 'notes'}',
            style: TextStyle(fontSize: 14, color: _ink.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Open →',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.menu_book_outlined, size: 18, color: _ink),
        const SizedBox(height: 14),
        TextField(
          controller: renameController,
          autofocus: true,
          onSubmitted: (_) => onCommitRename(),
          style: const TextStyle(
            fontSize: 16.8,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: _ink,
          ),
          decoration: const InputDecoration(
            isDense: true,
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in NoteSwatches.paletteHex)
              _ColorDot(
                hex: item,
                size: 20,
                fill: swatches.resolveHex(item),
                selected: notebook.color == item,
                onTap: () => onRecolor(item),
              ),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: onCommitRename,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _ink,
              ),
              child: const Text(
                'Save →',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class const _PencilButton({
  required final String label,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Semantics(
            button: true,
            label: 'Rename $label',
            child: const Icon(Icons.edit_outlined, size: 14, color: _ink),
          ),
        ),
      ),
    );
  }
}

class const _AddNotebookTile({required final VoidCallback onTap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(26);
    return Material(
      color: ink.withValues(alpha: 0.04),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: ink.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1814),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                'New notebook',
                style: TextStyle(
                  fontSize: 16.8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A fresh cover for a new pile.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: ink.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
