import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/account/domain/note_export.dart';
import 'package:notes_app/features/notes/domain/note.dart';

Note _note({
  int id = 1,
  String title = 'Groceries',
  String tag = 'Errand',
  String notebook = 'Home',
  String preview = 'Milk, eggs',
  String body = 'Milk, eggs, bread',
  String? dueAt,
  String? dueTime,
  List<String> labels = const [],
}) {
  return Note(
    id: id,
    ownerEmail: 'ada@example.com',
    createdAt: 0,
    updatedAt: 0,
    color: '#C5CA8A',
    title: title,
    tag: tag,
    notebook: notebook,
    preview: preview,
    body: body,
    dueAt: dueAt,
    dueTime: dueTime,
    labels: labels,
  );
}

void main() {
  group('exportNotesMarkdown', () {
    test('renders heading, meta line, preview, and body', () {
      final markdown = exportNotesMarkdown([_note()]);
      expect(markdown, contains('# Groceries'));
      expect(markdown, contains('tag: Errand'));
      expect(markdown, contains('notebook: Home'));
      expect(markdown, contains('Milk, eggs, bread'));
    });

    test('falls back to "Untitled note" and default tag/notebook', () {
      final markdown = exportNotesMarkdown([
        _note(title: '', tag: '', notebook: '', preview: '', body: ''),
      ]);
      expect(markdown, contains('# Untitled note'));
      expect(markdown, contains('tag: Note'));
      expect(markdown, contains('notebook: Inbox'));
    });

    test('includes a due line only when the note has a due date', () {
      final withDue = exportNotesMarkdown([
        _note(dueAt: '2026-09-10', dueTime: '14:00'),
      ]);
      expect(withDue, contains('due: 2026-09-10 14:00'));

      final withoutDue = exportNotesMarkdown([_note()]);
      expect(withoutDue, isNot(contains('due:')));
    });

    test('includes labels only when present', () {
      final markdown = exportNotesMarkdown([
        _note(labels: const ['urgent', 'home']),
      ]);
      expect(markdown, contains('labels: urgent, home'));
    });

    test('rewrites notes-blob image links to a plain "attachment" marker', () {
      final markdown = exportNotesMarkdown([
        _note(body: 'See ![photo](notes-blob:abc123) for details'),
      ]);
      expect(markdown, contains('![photo](attachment)'));
      expect(markdown, isNot(contains('notes-blob:')));
    });

    test('joins multiple notes with a horizontal rule', () {
      final markdown = exportNotesMarkdown([
        _note(title: 'First'),
        _note(id: 2, title: 'Second'),
      ]);
      expect(markdown, contains('# First'));
      expect(markdown, contains('\n\n---\n\n'));
      expect(markdown, contains('# Second'));
    });
  });

  group('exportNotesJson / importNotesJson round-trip', () {
    test('exports pretty-printed JSON that imports back to equal notes', () {
      final notes = [_note(), _note(id: 2, title: 'Second note')];
      final json = exportNotesJson(notes);
      expect(json, contains('  '));

      final imported = importNotesJson(json, const [], 'ada@example.com');
      expect(imported, hasLength(2));
      expect(imported[0].title, 'Groceries');
      expect(imported[1].title, 'Second note');
      expect(imported[0].ownerEmail, 'ada@example.com');
    });

    test('throws FormatException when the backup is not a JSON array', () {
      expect(
        () => importNotesJson('{"not":"an array"}', const [], 'a@b.com'),
        throwsFormatException,
      );
    });

    test(
      'assigns a fresh id when an imported id collides with an existing note',
      () {
        final existing = [_note(title: 'Existing')];
        final json = exportNotesJson([_note(title: 'Imported')]);

        final merged = importNotesJson(json, existing, 'ada@example.com');

        expect(merged, hasLength(2));
        expect(merged[0].id, 1);
        expect(merged[1].id, isNot(1));
        expect(merged[1].title, 'Imported');
      },
    );

    test('fills sensible defaults for missing fields', () {
      final imported = importNotesJson('[{}]', const [], 'ada@example.com');
      expect(imported, hasLength(1));
      expect(imported.single.title, '');
      expect(imported.single.notebook, 'Inbox');
      expect(imported.single.notebookId, 'inbox');
      expect(imported.single.color, '#C5CA8A');
      expect(imported.single.alertMinutes, -1);
    });
  });
}
