import Dexie, { type Table } from 'dexie'
import { TRASH_TTL_MS, LEGACY_STORAGE_KEY, SEARCH_RECENTS_LIMIT, type AccountBundle, type Note, type Notebook, type QueuedMutation, type SavedTemplate } from './types.ts'
import { normalizeNote } from './normalize.ts'
import { ensureNotebooks } from './notebooks.ts'
import { createSampleNotes } from './seed.ts'

type PrefRow = { key: string; value: unknown }

class NotesDatabase extends Dexie {
  notes!: Table<Note, [string, number]>
  notebooks!: Table<Notebook, [string, string]>
  templates!: Table<SavedTemplate, [string, string]>
  mutations!: Table<QueuedMutation, number>
  prefs!: Table<PrefRow, string>

  constructor() {
    super('notes-personal-v1')
    this.version(1).stores({
      notes: '[ownerEmail+id], ownerEmail, notebookId, trashedAt, archived, updatedAt',
      notebooks: '[ownerEmail+id], ownerEmail',
      templates: '[ownerEmail+id], ownerEmail',
      mutations: '++id, ownerEmail, createdAt, synced',
      prefs: 'key',
    })
  }
}

let db: NotesDatabase | null = null

const getDb = () => {
  if (typeof indexedDB === 'undefined') return null
  if (!db) db = new NotesDatabase()
  return db
}

const recentsKey = (email: string) => `search:${email}`
const seedKey = (email: string) => `seeded:${email}`

export const enqueueMutation = async (ownerEmail: string, kind: string, payload: unknown) => {
  const store = getDb()
  if (!store) return
  await store.mutations.add({
    ownerEmail,
    kind,
    payload,
    createdAt: Date.now(),
    synced: 0,
  })
}

export const pendingMutations = async (ownerEmail: string) => {
  const store = getDb()
  if (!store) return []
  return store.mutations.where('ownerEmail').equals(ownerEmail).and((item) => item.synced === 0).toArray()
}

const migrateLegacyNotes = (ownerEmail: string): Note[] => {
  if (typeof localStorage === 'undefined') return []
  const raw = localStorage.getItem(LEGACY_STORAGE_KEY)
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw) as unknown
    if (!Array.isArray(parsed)) return []
    return parsed
      .map((item, index) => normalizeNote(item as Note, index, ownerEmail))
      .filter((note) => {
        const legacy = note as Note & { authorId?: string }
        return !legacy.authorId || legacy.authorId === 'you' || note.ownerEmail === ownerEmail
      })
      .map((note) => ({ ...note, ownerEmail }))
  } catch {
    return []
  }
}

export const loadAccount = async (ownerEmail: string): Promise<AccountBundle> => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store) {
    return {
      notes: createSampleNotes(email),
      notebooks: ensureNotebooks(email, []),
      templates: [],
      recents: [],
    }
  }

  const [existingNotes, existingNotebooks, templates, pref] = await Promise.all([
    store.notes.where('ownerEmail').equals(email).toArray(),
    store.notebooks.where('ownerEmail').equals(email).toArray(),
    store.templates.where('ownerEmail').equals(email).toArray(),
    store.prefs.get(recentsKey(email)),
  ])

  let notes = existingNotes
  if (notes.length === 0) {
    const migrated = migrateLegacyNotes(email)
    notes = migrated
    if (migrated.length > 0) {
      await store.notes.bulkPut(migrated)
      await enqueueMutation(email, 'account.migrated', { count: migrated.length })
    }
  }

  const alreadySeeded = await store.prefs.get(seedKey(email))
  if (notes.length === 0 && !alreadySeeded) {
    notes = createSampleNotes(email)
    await store.notes.bulkPut(notes)
    await store.prefs.put({ key: seedKey(email), value: true })
    await enqueueMutation(email, 'account.seeded', { count: notes.length })
  }

  const cutoff = Date.now() - TRASH_TTL_MS
  const expired = notes.filter((note) => note.trashedAt && note.trashedAt < cutoff)
  if (expired.length) {
    await store.notes.bulkDelete(expired.map((note) => [email, note.id] as [string, number]))
    notes = notes.filter((note) => !expired.some((item) => item.id === note.id))
  }

  const notebooks = ensureNotebooks(email, existingNotebooks)
  if (notebooks.length !== existingNotebooks.length) {
    await store.notebooks.bulkPut(notebooks)
  }

  await enqueueMutation(email, 'account.opened', { at: Date.now() })

  return {
    notes,
    notebooks,
    templates,
    recents: Array.isArray(pref?.value) ? (pref.value as string[]) : [],
  }
}

export const persistAccount = async (ownerEmail: string, bundle: Omit<AccountBundle, 'recents'> & { recents?: string[] }) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store) return
  const current = await store.notes.where('ownerEmail').equals(email).toArray()
  const currentIds = new Set(current.map((note) => note.id))
  const nextIds = new Set(bundle.notes.map((note) => note.id))
  const removed = [...currentIds].filter((id) => !nextIds.has(id)).map((id) => [email, id] as [string, number])
  await store.transaction('rw', store.notes, store.notebooks, store.templates, store.prefs, async () => {
    if (removed.length) await store.notes.bulkDelete(removed)
    await store.notes.bulkPut(bundle.notes.map((note) => ({ ...note, ownerEmail: email })))
    await store.notebooks.bulkPut(bundle.notebooks.map((item) => ({ ...item, ownerEmail: email })))
    const existingTemplates = await store.templates.where('ownerEmail').equals(email).toArray()
    const keep = new Set(bundle.templates.map((item) => item.id))
    const drop = existingTemplates.filter((item) => !keep.has(item.id)).map((item) => [email, item.id] as [string, string])
    if (drop.length) await store.templates.bulkDelete(drop)
    if (bundle.templates.length) await store.templates.bulkPut(bundle.templates.map((item) => ({ ...item, ownerEmail: email })))
    if (bundle.recents) {
      await store.prefs.put({
        key: recentsKey(email),
        value: bundle.recents.slice(0, SEARCH_RECENTS_LIMIT),
      })
    }
  })
  await enqueueMutation(email, 'account.saved', { notes: bundle.notes.length })
}

export const rememberSearch = async (ownerEmail: string, query: string, recents: string[]) => {
  const next = [query, ...recents.filter((item) => item !== query)].slice(0, SEARCH_RECENTS_LIMIT)
  const store = getDb()
  if (store) await store.prefs.put({ key: recentsKey(ownerEmail), value: next })
  return next
}
