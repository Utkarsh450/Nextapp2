import { normalizeNote } from './normalize.ts'
import type { LegacyNote, Note } from './types.ts'

export const exportNotesJson = (notes: Note[]) => JSON.stringify(notes, null, 2)

export const importNotesJson = (raw: string, existing: Note[], ownerEmail: string) => {
  const parsed = JSON.parse(raw) as unknown
  if (!Array.isArray(parsed)) throw new Error('Backup must be an array of notes')
  const usedIds = new Set(existing.map((note) => note.id))
  const imported = parsed.map((item, index) => {
    const note = normalizeNote(item as LegacyNote, existing.length + index, ownerEmail)
    if (!usedIds.has(note.id)) {
      usedIds.add(note.id)
      return { ...note, ownerEmail }
    }
    const id = Date.now() + index
    usedIds.add(id)
    return { ...note, id, ownerEmail }
  })
  return [...existing, ...imported]
}

export const exportNotesMarkdown = (notes: Note[]) =>
  notes
    .map((note) => {
      const heading = `# ${note.title || 'Untitled note'}`
      const meta = [
        `tag: ${note.tag || 'Note'}`,
        `notebook: ${note.notebook || 'Inbox'}`,
        note.dueAt ? `due: ${note.dueAt}${note.dueTime ? ` ${note.dueTime}` : ''}` : '',
        note.labels.length ? `labels: ${note.labels.join(', ')}` : '',
      ]
        .filter(Boolean)
        .join(' · ')
      const body = note.body.replace(/!\[([^\]]*)\]\(notes-blob:[^)]+\)/g, '![$1](attachment)')
      const files = note.attachments.length
        ? note.attachments.map((item) => `- ${item.name}`).join('\n')
        : ''
      return [heading, meta, note.preview, body, files ? `## Attachments\n\n${files}` : '']
        .filter(Boolean)
        .join('\n\n')
    })
    .join('\n\n---\n\n')

export const parseNoteIdFromSearch = (search: string) => {
  const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
  const value = Number(params.get('note'))
  return Number.isFinite(value) && value > 0 ? value : null
}

export const sharePath = (id: number) => `?note=${id}`
