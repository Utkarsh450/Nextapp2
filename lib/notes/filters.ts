import { isDueToday, isOverdue } from './dates.ts'
import { cardBodyPreview } from './markdown.ts'
import type { FilterKey, Note, SortKey } from './types.ts'

export const uniqueNotebooks = (notes: Note[]) => {
  const values = notes
    .filter((note) => !note.archived && !note.trashedAt)
    .map((note) => note.notebook.trim() || 'Inbox')
  return [...new Set(values)].sort((a, b) => a.localeCompare(b))
}

export const uniqueTags = (notes: Note[]) => {
  const values = notes
    .filter((note) => !note.archived && !note.trashedAt && note.tag.trim())
    .map((note) => note.tag.trim())
  return [...new Set(values)].sort((a, b) => a.localeCompare(b))
}

export const uniqueLabels = (notes: Note[]) => {
  const values = notes
    .filter((note) => !note.archived && !note.trashedAt)
    .flatMap((note) => note.labels)
  return [...new Set(values)].sort((a, b) => a.localeCompare(b))
}

export const uniqueColors = (notes: Note[]) => {
  const values = notes
    .filter((note) => !note.archived && !note.trashedAt && note.color)
    .map((note) => note.color)
  return [...new Set(values)]
}

export const restoreNote = (notes: Note[], note: Note) => {
  if (notes.some((item) => item.id === note.id)) return notes
  return [...notes, note]
}

export const moveNote = (notes: Note[], fromId: number, toId: number) => {
  const from = notes.findIndex((note) => note.id === fromId)
  const to = notes.findIndex((note) => note.id === toId)
  if (from < 0 || to < 0 || from === to) return notes
  const next = [...notes]
  const [item] = next.splice(from, 1)
  next.splice(to, 0, item)
  return next.map((note, index) => ({ ...note, order: index }))
}

export const trashNote = (note: Note, now = Date.now()): Note => ({
  ...note,
  trashedAt: now,
  updatedAt: now,
  pinned: false,
})

export const restoreFromTrash = (note: Note, now = Date.now()): Note => ({
  ...note,
  trashedAt: null,
  updatedAt: now,
})

export const visibleNotes = ({
  notes,
  search,
  sortKey,
  filterKey,
  notebookId,
  tag,
  label,
  color,
  today,
  ownerEmail,
}: {
  notes: Note[]
  search: string
  sortKey: SortKey
  filterKey: FilterKey
  notebookId: string | null
  tag: string | null
  label?: string | null
  color?: string | null
  today?: string
  ownerEmail?: string
}) => {
  const query = search.trim().toLowerCase()

  return notes
    .filter((note) => {
      if (ownerEmail && note.ownerEmail !== ownerEmail) return false
      if (filterKey === 'trash') return Boolean(note.trashedAt)
      if (note.trashedAt) return false
      if (filterKey === 'archived') return note.archived
      if (note.archived) return false
      if (filterKey === 'done' && !note.confirmed) return false
      if (filterKey === 'open' && note.confirmed) return false
      if (filterKey === 'due' && !isDueToday(note.dueAt, today) && !isOverdue(note.dueAt, today)) {
        return false
      }
      if (notebookId && note.notebookId !== notebookId) return false
      if (tag && note.tag.trim() !== tag) return false
      if (label && !note.labels.includes(label)) return false
      if (color && note.color !== color) return false
      if (!query) return true
      return [
        note.title,
        note.tag,
        note.preview,
        note.notebook,
        note.body,
        cardBodyPreview(note.body, note.preview),
        ...note.labels,
      ]
        .join(' ')
        .toLowerCase()
        .includes(query)
    })
    .sort((a, b) => {
      if (filterKey !== 'trash' && a.pinned !== b.pinned) return a.pinned ? -1 : 1
      if (sortKey === 'oldest') return a.createdAt - b.createdAt
      if (sortKey === 'title') return a.title.localeCompare(b.title)
      if (sortKey === 'tag') return a.tag.localeCompare(b.tag)
      if (a.order !== b.order) return a.order - b.order
      return b.createdAt - a.createdAt
    })
}

export const upcomingReminders = (notes: Note[], today = '') =>
  notes.filter((note) =>
    !note.trashedAt &&
    !note.archived &&
    note.dueAt &&
    (isDueToday(note.dueAt, today) || isOverdue(note.dueAt, today))
  )
