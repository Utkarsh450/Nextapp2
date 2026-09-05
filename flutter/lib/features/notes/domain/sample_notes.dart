import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';

/// **Placeholder demo data.** Per the "no backend/DB for now" instruction,
/// there is no Drift wiring behind this screen yet — `NotesController`
/// seeds itself from this fixed, in-memory list instead of `loadAccount()`.
/// This is a stand-in for `lib/notes/seed.ts` (which generates ~90 starter
/// notes), not a port of it — replace with real persistence when the data
/// layer is wired up.
List<Note> sampleNotes() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final today = todayIso();
  const p = NoteSwatches.paletteHex;

  Note note({
    required int id,
    required String title,
    required String body,
    String tag = '',
    String notebook = 'Inbox',
    String notebookId = 'inbox',
    String color = '#C5CA8A',
    bool pinned = false,
    bool confirmed = false,
    bool archived = false,
    int? trashedAt,
    String? dueAt,
    List<String> labels = const [],
    int ageMinutes = 0,
    int order = 0,
  }) {
    final createdAt = now - ageMinutes * 60 * 1000;
    return Note(
      id: id,
      ownerEmail: 'you@notes.dev',
      title: title,
      tag: tag,
      notebook: notebook,
      notebookId: notebookId,
      body: body,
      color: color,
      pinned: pinned,
      confirmed: confirmed,
      archived: archived,
      trashedAt: trashedAt,
      dueAt: dueAt,
      labels: labels,
      createdAt: createdAt,
      updatedAt: createdAt,
      order: order,
    );
  }

  return [
    note(
      id: 1,
      title: 'Welcome to Notes',
      body:
          'This is a scattered, paper-styled notebook for quick capture and '
          'habit tracking. Long-press a card for more actions.',
      pinned: true,
      color: p[4],
      tag: 'intro',
      labels: const ['Ideas'],
      ageMinutes: 5,
    ),
    note(
      id: 2,
      title: 'Grocery run',
      body: '- [ ] Milk\n- [ ] Eggs\n- [x] Coffee\n- [ ] Spinach',
      color: p[6],
      notebook: 'Home',
      notebookId: 'home',
      labels: const ['Home'],
      ageMinutes: 40,
    ),
    note(
      id: 3,
      title: 'Sprint planning notes',
      body:
          '# Goals\n- Ship the notes list screen\n- Wire up filters\n'
          '- Keep parity with the design system',
      color: p[2],
      tag: 'work',
      notebook: 'Work',
      notebookId: 'work',
      labels: const ['Work'],
      dueAt: today,
      ageMinutes: 120,
    ),
    note(
      id: 4,
      title: 'Book recs from Priya',
      body: '- Piranesi\n- The Overstory\n- Klara and the Sun',
      color: p[5],
      tag: 'reading',
      labels: const ['Ideas'],
      ageMinutes: 300,
    ),
    note(
      id: 5,
      title: 'Renew passport',
      body: 'Appointment booked — bring the old passport and two photos.',
      color: p[3],
      dueAt: today,
      ageMinutes: 500,
    ),
    note(
      id: 6,
      title: 'Done: fix login bug',
      body: 'Root cause was a stale session token. Shipped and verified.',
      color: p[0],
      confirmed: true,
      tag: 'work',
      notebook: 'Work',
      notebookId: 'work',
      labels: const ['Work'],
      ageMinutes: 1440,
    ),
    note(
      id: 7,
      title: 'Old draft',
      body: 'This one has been archived — no longer active.',
      color: p[2],
      archived: true,
      ageMinutes: 20000,
    ),
    note(
      id: 8,
      title: 'Deleted scratch note',
      body: 'This should only show up in Trash.',
      color: p[1],
      trashedAt: now - 60 * 60 * 1000,
      ageMinutes: 30000,
    ),
  ];
}
