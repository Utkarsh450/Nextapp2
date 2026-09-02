import { todayISO } from './dates.ts'
import type { Note, SavedTemplate, TemplateKey } from './types.ts'

export const NOTE_TEMPLATES: Record<
  TemplateKey,
  { name: string; title: string; tag: string; notebook: string; notebookId: string; body: string; preview: string }
> = {
  meeting: {
    name: 'Meeting',
    title: 'Meeting notes',
    tag: 'Work',
    notebook: 'Work',
    notebookId: 'work',
    preview: 'Agenda and follow-ups',
    body: '## Attendees\n\n- \n\n## Agenda\n\n- [ ] \n\n## Notes\n\n\n## Action items\n\n- [ ] ',
  },
  idea: {
    name: 'Idea',
    title: 'New idea',
    tag: 'Ideas',
    notebook: 'Ideas',
    notebookId: 'ideas',
    preview: 'A spark to expand',
    body: '## The idea\n\n\n## Why it matters\n\n\n## Next step\n\n- [ ] ',
  },
  daily: {
    name: 'Daily log',
    title: 'Daily log',
    tag: 'Daily',
    notebook: 'Journal',
    notebookId: 'journal',
    preview: 'Wins and tasks',
    body: '## Wins\n\n- \n\n## Tasks\n\n- [ ] \n\n## Notes\n\n',
  },
}

export const applyTemplate = (key: TemplateKey, now = new Date()) => {
  const template = NOTE_TEMPLATES[key]
  const title = key === 'daily' ? `Daily log · ${todayISO(now)}` : template.title
  return { ...template, title }
}

export const dailyNoteTitle = (now = new Date()) => `Daily log · ${todayISO(now)}`

export const findDailyNote = (notes: Note[], now = new Date()) => {
  const title = dailyNoteTitle(now)
  return notes.find((note) => !note.trashedAt && note.title === title) ?? null
}

export const templateFromSaved = (item: SavedTemplate) => ({
  title: item.title,
  tag: item.tag,
  notebookId: item.notebookId,
  body: item.body,
  preview: item.name,
})
