import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/note_filters.dart';
import 'package:notes_app/features/notes/domain/note_templates.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('toggleDone flips confirmed without touching other notes', () {
    final before = container.read(notesControllerProvider);
    final target = before.first;
    container.read(notesControllerProvider.notifier).toggleDone(target.id);
    final after = container.read(notesControllerProvider);
    expect(
      after.firstWhere((n) => n.id == target.id).confirmed,
      !target.confirmed,
    );
    expect(after.length, before.length);
  });

  test('togglePin flips pinned and visibleNoteList sorts pinned first', () {
    final notes = container.read(notesControllerProvider);
    final unpinned = notes.firstWhere((n) => !n.pinned);
    container.read(notesControllerProvider.notifier).togglePin(unpinned.id);

    final shown = container.read(visibleNoteListProvider);
    expect(shown.firstWhere((n) => n.id == unpinned.id).pinned, isTrue);
    final lastPinnedIndex = shown.lastIndexWhere((n) => n.pinned);
    final firstUnpinnedIndex = shown.indexWhere((n) => !n.pinned);
    // Every pinned note (including the one just pinned) sorts ahead of
    // every unpinned note — not necessarily first overall, since the seed
    // data already has another pinned note.
    expect(
      firstUnpinnedIndex == -1 || lastPinnedIndex < firstUnpinnedIndex,
      isTrue,
    );
  });

  test('moveToTrash then restoreTrashed round-trips through both filters', () {
    final notes = container.read(notesControllerProvider);
    final target = notes.firstWhere((n) => n.trashedAt == null && !n.archived);
    final notifier = container.read(notesControllerProvider.notifier);

    // Not a cascade: this reads its own state back through the container
    // between calls (see the `container.read(noteFilterKeyProvider...)`
    // line right after), so `notifier..moveToTrash(...)` would misleadingly
    // suggest these two calls are unrelated to that.
    // ignore: cascade_invocations
    notifier.moveToTrash(target.id);
    container.read(noteFilterKeyProvider.notifier).set(NoteFilter.trash);
    expect(
      container.read(visibleNoteListProvider).map((n) => n.id),
      contains(target.id),
    );

    notifier.restoreTrashed(target.id);
    container.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    expect(
      container.read(visibleNoteListProvider).map((n) => n.id),
      contains(target.id),
    );
  });

  test('deleteForever removes the note permanently', () {
    final target = container.read(notesControllerProvider).first;
    container.read(notesControllerProvider.notifier)
      ..moveToTrash(target.id)
      ..deleteForever(target.id);
    expect(
      container.read(notesControllerProvider).any((n) => n.id == target.id),
      isFalse,
    );
  });

  test('duplicateNote inserts a copy with a fresh id and reset flags', () {
    final notifier = container.read(notesControllerProvider.notifier);
    final source = container.read(notesControllerProvider).first;
    notifier.togglePin(source.id); // so we can assert the copy isn't pinned
    final pinnedSource = container
        .read(notesControllerProvider)
        .firstWhere((n) => n.id == source.id);

    final before = container.read(notesControllerProvider).length;
    notifier.duplicateNote(source.id);
    final after = container.read(notesControllerProvider);

    expect(after.length, before + 1);
    final copy = after.first;
    expect(copy.id, isNot(pinnedSource.id));
    expect(copy.pinned, isFalse);
    expect(copy.title, '${pinnedSource.title} copy');
  });

  test(
    'createFromTemplate seeds title/tag/body/notebook from the template',
    () {
      final note = container
          .read(notesControllerProvider.notifier)
          .createFromTemplate(TemplateKey.meeting);
      expect(note.title, 'Meeting notes');
      expect(note.tag, 'Work');
      expect(note.notebookId, 'work');
      expect(note.body, contains('## Attendees'));
    },
  );

  test('openDailyNote creates once, then reuses the same note', () {
    final notifier = container.read(notesControllerProvider.notifier);
    final first = notifier.openDailyNote();
    final second = notifier.openDailyNote();
    expect(second.id, first.id);
    expect(
      container.read(notesControllerProvider).where((n) => n.id == first.id),
      hasLength(1),
    );
  });

  test('filter chips actually change what visibleNoteList returns', () {
    container.read(noteFilterKeyProvider.notifier).set(NoteFilter.archived);
    final archivedShown = container.read(visibleNoteListProvider);
    expect(archivedShown.every((n) => n.archived), isTrue);

    container.read(noteFilterKeyProvider.notifier).set(NoteFilter.all);
    final allShown = container.read(visibleNoteListProvider);
    expect(allShown.any((n) => n.archived), isFalse);
  });
}
