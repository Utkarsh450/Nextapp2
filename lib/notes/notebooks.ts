import { NOTEBOOK_COVERS, slugify, type Notebook } from './types.ts'

export const DEFAULT_NOTEBOOKS: Array<{ id: string; name: string; color: string }> = [
  { id: 'inbox', name: 'Inbox', color: '#F9D368' },
  { id: 'work', name: 'Work', color: '#CDE0E8' },
  { id: 'journal', name: 'Journal', color: '#B8E0D2' },
  { id: 'ideas', name: 'Ideas', color: '#D4C4F0' },
  { id: 'personal', name: 'Personal', color: '#F9A8B6' },
]

export const defaultNotebooksFor = (ownerEmail: string, now = Date.now()): Notebook[] =>
  DEFAULT_NOTEBOOKS.map((item, index) => ({
    ...item,
    ownerEmail,
    createdAt: now - (DEFAULT_NOTEBOOKS.length - index) * 1000,
  }))

export const ensureNotebooks = (ownerEmail: string, existing: Notebook[], now = Date.now()) => {
  const have = new Set(existing.map((item) => item.id))
  const missing = defaultNotebooksFor(ownerEmail, now).filter((item) => !have.has(item.id))
  return [...existing, ...missing]
}

export const createNotebook = (
  ownerEmail: string,
  name: string,
  color: string = NOTEBOOK_COVERS[0],
  now = Date.now()
): Notebook => ({
  id: `${slugify(name)}-${now}`,
  ownerEmail,
  name: name.trim() || 'Notebook',
  color,
  createdAt: now,
})

export const renameNotebook = (notebook: Notebook, name: string): Notebook => ({
  ...notebook,
  name: name.trim() || notebook.name,
})

export const notebookById = (notebooks: Notebook[], id: string | null | undefined) =>
  notebooks.find((item) => item.id === id) ?? notebooks[0] ?? null
