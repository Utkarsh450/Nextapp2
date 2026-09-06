/// Direct port of `lib/notes/templates.ts` — the three built-in starter
/// templates offered from Quick capture (feature-audit #9). `SavedTemplate`
/// (a user's own custom templates) isn't modeled — see
/// `note_editor_screen.dart`'s doc comment on "Save as template" — so
/// `templateFromSaved` has no equivalent here.
library;

import 'package:notes_app/features/notes/domain/note.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';

enum TemplateKey { meeting, idea, daily }

class const NoteTemplate({
  required final String name,
  required final String title,
  required final String tag,
  required final String notebook,
  required final String notebookId,
  required final String body,
  required final String preview,
});

const Map<TemplateKey, NoteTemplate> noteTemplates = {
  TemplateKey.meeting: NoteTemplate(
    name: 'Meeting',
    title: 'Meeting notes',
    tag: 'Work',
    notebook: 'Work',
    notebookId: 'work',
    preview: 'Agenda and follow-ups',
    body:
        '## Attendees\n\n- \n\n## Agenda\n\n- [ ] \n\n## Notes\n\n\n'
        '## Action items\n\n- [ ] ',
  ),
  TemplateKey.idea: NoteTemplate(
    name: 'Idea',
    title: 'New idea',
    tag: 'Ideas',
    notebook: 'Ideas',
    notebookId: 'ideas',
    preview: 'A spark to expand',
    body: '## The idea\n\n\n## Why it matters\n\n\n## Next step\n\n- [ ] ',
  ),
  TemplateKey.daily: NoteTemplate(
    name: 'Daily log',
    title: 'Daily log',
    tag: 'Daily',
    notebook: 'Journal',
    notebookId: 'journal',
    preview: 'Wins and tasks',
    body: '## Wins\n\n- \n\n## Tasks\n\n- [ ] \n\n## Notes\n\n',
  ),
};

/// Matches `applyTemplate` — the `daily` key gets today's date folded into
/// its title, the others use their template's title as-is.
NoteTemplate applyTemplate(TemplateKey key, [DateTime? now]) {
  final template = noteTemplates[key]!;
  if (key != TemplateKey.daily) return template;
  return NoteTemplate(
    name: template.name,
    title: dailyNoteTitle(now),
    tag: template.tag,
    notebook: template.notebook,
    notebookId: template.notebookId,
    body: template.body,
    preview: template.preview,
  );
}

String dailyNoteTitle([DateTime? now]) => 'Daily log · ${todayIso(now)}';

/// Matches `findDailyNote` — today's daily log, if one already exists.
Note? findDailyNote(List<Note> notes, [DateTime? now]) {
  final title = dailyNoteTitle(now);
  for (final note in notes) {
    if (note.trashedAt == null && note.title == title) return note;
  }
  return null;
}
