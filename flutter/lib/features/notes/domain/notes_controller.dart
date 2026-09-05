import 'package:collection/collection.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_markdown.dart';
import 'package:notes_app/features/notes/domain/sample_notes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_controller.g.dart';

/// Holds the notes list itself.
///
/// **In-memory only, per instruction:** no Drift wiring yet, so state
/// resets to [sampleNotes] on every app restart. Mirrors the action set of
/// `hooks/useNotes.ts` for the actions this screen needs; note creation and
/// editing arrive with the note editor screen.
@riverpod
class NotesController extends _$NotesController {
  @override
  List<Note> build() => sampleNotes();

  void _patch(int id, Note Function(Note note) update) {
    state = [
      for (final note in state) if (note.id == id) update(note) else note,
    ];
  }

  /// `togglePin` — flips `pinned`.
  void togglePin(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _patch(id, (n) => n.copyWith(pinned: !n.pinned, updatedAt: now));
  }

  /// `toggleArchive` — flips `archived`, and unpins (matching the source:
  /// an archived note is never shown pinned).
  void toggleArchive(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _patch(
      id,
      (n) => n.copyWith(archived: !n.archived, pinned: false, updatedAt: now),
    );
  }

  /// `toggleDone` — flips `confirmed`. Decided in `docs/feature-audit.md`
  /// as a real, wired-up gesture in Flutter (the source built this at the
  /// data layer but never shipped a UI for it).
  void toggleDone(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _patch(id, (n) => n.copyWith(confirmed: !n.confirmed, updatedAt: now));
  }

  /// `toggleTask` — flips one `- [ ]`/`- [x]` line inside the body.
  void toggleTask(int id, int line) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _patch(
      id,
      (n) => n.copyWith(body: toggleTaskLine(n.body, line), updatedAt: now),
    );
  }

  /// `moveToTrash`.
  void moveToTrash(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = [
      for (final note in state)
        if (note.id == id) trashNote(note, now) else note,
    ];
  }

  /// `restoreTrashed`.
  void restoreTrashed(int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    state = [
      for (final note in state)
        if (note.id == id) restoreFromTrash(note, now) else note,
    ];
  }

  /// `deleteForever`.
  void deleteForever(int id) {
    state = [
      for (final note in state) if (note.id != id) note,
    ];
  }

  /// `emptyTrash`.
  void emptyTrash() {
    state = [
      for (final note in state) if (note.trashedAt == null) note,
    ];
  }

  /// `duplicateNote` — copies title/body/color/labels; resets pin/archive/
  /// trash state and stamps a fresh id, matching the source's
  /// `duplicateNote`. Attachment cloning doesn't apply yet (see `note.dart`).
  void duplicateNote(int id) {
    final source = state.where((n) => n.id == id).firstOrNull;
    if (source == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = Note(
      id: now,
      ownerEmail: source.ownerEmail,
      title: source.title.isNotEmpty ? '${source.title} copy' : 'Untitled copy',
      tag: source.tag,
      notebookId: source.notebookId,
      notebook: source.notebook,
      body: source.body,
      color: source.color,
      labels: source.labels,
      createdAt: now,
      updatedAt: now,
    );
    state = [copy, ...state];
  }

  /// `reorder` — drag-to-reorder is a decided real feature per
  /// `docs/feature-audit.md`, but its own gesture/UI is deferred to a
  /// follow-up pass (see this build's completion notes); the underlying
  /// data-layer operation is wired up now so nothing here changes when
  /// that UI lands.
  void reorder(int fromId, int toId) {
    state = moveNote(state, fromId, toId);
  }
}

/// `board.filterKey` — defaults to `all`, matching the source.
@riverpod
class NoteFilterKey extends _$NoteFilterKey {
  @override
  NoteFilter build() => NoteFilter.all;

  // See theme_controller.dart's `setSkin` for why this stays a method.
  // ignore: use_setters_to_change_properties
  void set(NoteFilter value) => state = value;
}

/// `board.sortKey`. The source defines `newest`/`oldest`/`title`/`tag` at
/// the data layer (`lib/notes/filters.ts`) but — confirmed by a repo-wide
/// search for `setSortKey` — never wires a control to change it in any
/// screen. `newest` (the default) is genuinely the only value the shipped
/// app ever uses; kept as real state here rather than a hardcoded constant
/// so a future sort-control screen is a pure UI addition.
@riverpod
class NoteSortKey extends _$NoteSortKey {
  @override
  NoteSort build() => NoteSort.newest;

  // See theme_controller.dart's `setSkin` for why this stays a method.
  // ignore: use_setters_to_change_properties
  void set(NoteSort value) => state = value;
}

@riverpod
class NoteColorFilter extends _$NoteColorFilter {
  @override
  String? build() => null;

  // See theme_controller.dart's `setSkin` for why this stays a method.
  // ignore: use_setters_to_change_properties
  void set(String? value) => state = value;
}

@riverpod
class NoteLabelFilter extends _$NoteLabelFilter {
  @override
  String? build() => null;

  // See theme_controller.dart's `setSkin` for why this stays a method.
  // ignore: use_setters_to_change_properties
  void set(String? value) => state = value;
}

/// `AccountPanel`'s board-layout toggle. In-memory only for now — the
/// source persists this via `lib/theme.ts`'s `LAYOUT_KEY`; that lands once
/// `Prefs` is wired up.
enum NoteBoardLayout { masonry, grid }

@riverpod
class NoteBoardLayoutController extends _$NoteBoardLayoutController {
  @override
  NoteBoardLayout build() => NoteBoardLayout.masonry;

  void toggle() {
    state = state == NoteBoardLayout.masonry
        ? NoteBoardLayout.grid
        : NoteBoardLayout.masonry;
  }
}

/// `shown` in `NotesApp.tsx` — the filtered, sorted list this screen shows.
@riverpod
List<Note> visibleNoteList(Ref ref) {
  final notes = ref.watch(notesControllerProvider);
  return visibleNotes(
    notes: notes,
    sortKey: ref.watch(noteSortKeyProvider),
    filterKey: ref.watch(noteFilterKeyProvider),
    label: ref.watch(noteLabelFilterProvider),
    color: ref.watch(noteColorFilterProvider),
  );
}

@riverpod
List<String> noteLabelOptions(Ref ref) =>
    uniqueLabels(ref.watch(notesControllerProvider));

@riverpod
List<String> noteColorOptions(Ref ref) =>
    uniqueColors(ref.watch(notesControllerProvider));

@riverpod
List<Note> upcomingNoteReminders(Ref ref) =>
    upcomingReminders(ref.watch(notesControllerProvider));
