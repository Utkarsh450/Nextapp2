export const NOTE_COLORS = [
  '#C5CA8A',
  '#E7A3A3',
  '#BEC3BC',
  '#E89569',
  '#E8C44A',
  '#D4C4E8',
  '#A9D4C4',
] as const

export const NOTEBOOK_COVERS = NOTE_COLORS

export const THEME_KEY = 'notes-board-theme'
export const LEGACY_STORAGE_KEY = 'notes-board-v2'
export const SEARCH_RECENTS_LIMIT = 8
export const TRASH_TTL_MS = 30 * 24 * 60 * 60 * 1000

export type SortKey = 'newest' | 'oldest' | 'title' | 'tag'
export type FilterKey = 'all' | 'open' | 'done' | 'due' | 'archived' | 'trash'
export type TemplateKey = 'meeting' | 'idea' | 'daily'
export type AppTab = 'notes' | 'notebooks' | 'plan' | 'you'

export type Attachment = {
  id: string
  name: string
  mime: string
  createdAt: number
  dataUrl?: string
}

export type BlobRecord = {
  id: string
  ownerEmail: string
  noteId: number
  name: string
  mime: string
  createdAt: number
  blob: Blob
}

export type Note = {
  id: number
  ownerEmail: string
  title: string
  tag: string
  preview: string
  notebookId: string
  notebook: string
  logo: string | null
  confirmed: boolean
  createdAt: number
  updatedAt: number
  body: string
  pinned: boolean
  archived: boolean
  trashedAt: number | null
  color: string
  dueAt: string | null
  dueTime: string | null
  alertMinutes: number
  remindAt: string | null
  labels: string[]
  attachments: Attachment[]
  order: number
}

export type Notebook = {
  id: string
  ownerEmail: string
  name: string
  color: string
  createdAt: number
}

export type SavedTemplate = {
  id: string
  ownerEmail: string
  name: string
  title: string
  tag: string
  notebookId: string
  body: string
  color?: string
  labels?: string[]
  dueAt?: string | null
  dueTime?: string | null
  alertMinutes?: number
  createdAt: number
}

export type Habit = {
  id: string
  ownerEmail: string
  name: string
  color: string
  createdAt: number
}

export type HabitCheck = {
  ownerEmail: string
  habitId: string
  date: string
}

export type QueuedMutation = {
  id?: number
  ownerEmail: string
  kind: string
  payload: unknown
  createdAt: number
  synced: 0 | 1
}

export type AccountBundle = {
  notes: Note[]
  notebooks: Notebook[]
  templates: SavedTemplate[]
  recents: string[]
}

export type LegacyNote = Partial<Note> & {
  amount?: string
  author?: string
  institute?: string
  authorId?: string
  visibility?: string
}

export const slugify = (name: string) =>
  name.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'inbox'

export const randomNoteColor = () =>
  NOTE_COLORS[Math.floor(Math.random() * NOTE_COLORS.length)]

export const newId = (now = Date.now()) => now + Math.floor(Math.random() * 1000)
