import 'package:collection/collection.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notebooks/domain/notebook.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notebooks_controller.g.dart';

/// **In-memory only**, matching every other controller in this build (no
/// Drift wiring yet). The source always loads this array from the account
/// bundle (`bundle.notebooks` in `hooks/useNotes.ts`) — there's no local
/// equivalent to seed from, so this seeds the three notebooks
/// `sample_notes.dart` already references (`inbox`/`home`/`work`) with
/// preset palette colors, giving the Today dashboard's tiles and the future
/// Notebooks library (feature-audit #11) something real to show.
@riverpod
class NotebooksController extends _$NotebooksController {
  @override
  List<Notebook> build() {
    const p = NoteSwatches.paletteHex;
    return [
      Notebook(
        id: 'inbox',
        ownerEmail: 'you@notes.dev',
        name: 'Inbox',
        color: p[2],
        createdAt: 0,
      ),
      Notebook(
        id: 'home',
        ownerEmail: 'you@notes.dev',
        name: 'Home',
        color: p[6],
        createdAt: 1,
      ),
      Notebook(
        id: 'work',
        ownerEmail: 'you@notes.dev',
        name: 'Work',
        color: p[4],
        createdAt: 2,
      ),
    ];
  }

  /// `onCreate` — appends a new notebook, matching the source's
  /// `createNotebook`.
  Notebook addNotebook(String name, String color) {
    final trimmed = name.trim();
    final notebook = Notebook(
      id: _uniqueId(trimmed),
      ownerEmail: state.firstOrNull?.ownerEmail ?? 'you@notes.dev',
      name: trimmed.isEmpty ? 'Notebook' : trimmed,
      color: color,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    state = [...state, notebook];
    return notebook;
  }

  /// `onRename`.
  void renameNotebook(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = [
      for (final book in state)
        if (book.id == id) book.copyWith(name: trimmed) else book,
    ];
  }

  /// `onRecolor`.
  void recolorNotebook(String id, String color) {
    state = [
      for (final book in state)
        if (book.id == id) book.copyWith(color: color) else book,
    ];
  }

  String _uniqueId(String name) {
    final base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final slug = base.isEmpty ? 'notebook' : base;
    if (state.every((book) => book.id != slug)) return slug;
    return '$slug-${DateTime.now().millisecondsSinceEpoch}';
  }
}
