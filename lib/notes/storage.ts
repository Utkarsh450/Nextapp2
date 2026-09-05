import Dexie, { type Table } from 'dexie'
import { TRASH_TTL_MS, LEGACY_STORAGE_KEY, SEARCH_RECENTS_LIMIT, type AccountBundle, type Attachment, type BlobRecord, type Habit, type HabitCheck, type Note, type Notebook, type QueuedMutation, type SavedTemplate } from './types.ts'
import { normalizeNote } from './normalize.ts'
import { ensureNotebooks } from './notebooks.ts'
import { createSampleNotes } from './seed.ts'
import {
  attachmentMeta,
  blobMarkdownSrc,
  blobToDataUrl,
  collectBlobIds,
  dataUrlMime,
  dataUrlToBlob,
} from './blobs.ts'
import { compactMutations, formatBytes, shouldEnqueue } from './queue.ts'
import { isolateBundle, isolateHabitChecks, isolateHabits, isolateNotes, isolateTemplates } from './isolation.ts'

type PrefRow = { key: string; value: unknown }

class NotesDatabase extends Dexie {
  notes!: Table<Note, [string, number]>
  notebooks!: Table<Notebook, [string, string]>
  templates!: Table<SavedTemplate, [string, string]>
  habits!: Table<Habit, [string, string]>
  habitChecks!: Table<HabitCheck, [string, string, string]>
  mutations!: Table<QueuedMutation, number>
  prefs!: Table<PrefRow, string>
  blobs!: Table<BlobRecord, [string, string]>

  constructor() {
    super('notes-personal-v1')
    this.version(1).stores({
      notes: '[ownerEmail+id], ownerEmail, notebookId, trashedAt, archived, updatedAt',
      notebooks: '[ownerEmail+id], ownerEmail',
      templates: '[ownerEmail+id], ownerEmail',
      mutations: '++id, ownerEmail, createdAt, synced',
      prefs: 'key',
    })
    this.version(2).stores({
      blobs: '[ownerEmail+id], ownerEmail, noteId',
    })
    this.version(3).stores({
      habits: '[ownerEmail+id], ownerEmail',
      habitChecks: '[ownerEmail+habitId+date], ownerEmail, [ownerEmail+date], [ownerEmail+habitId]',
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
const seedKey = (email: string) => `seeded:v5:${email}`
const SAMPLE_ID_MIN = 10_000
const SAMPLE_ID_MAX = 12_000

export const putNoteBlob = async (record: Omit<BlobRecord, 'blob'> & { blob: Blob }) => {
  const store = getDb()
  if (!store) return
  await store.blobs.put(record)
}

export const readNoteBlob = async (ownerEmail: string, id: string) => {
  const store = getDb()
  if (!store) return null
  return (await store.blobs.get([ownerEmail.trim().toLowerCase(), id])) ?? null
}

export const readNoteBlobUrl = async (ownerEmail: string, id: string) => {
  const record = await readNoteBlob(ownerEmail, id)
  if (!record) return null
  return URL.createObjectURL(record.blob)
}

export const deleteBlobsForNotes = async (ownerEmail: string, noteIds: number[]) => {
  const store = getDb()
  if (!store || noteIds.length === 0) return
  const email = ownerEmail.trim().toLowerCase()
  const keep = new Set(noteIds)
  const rows = await store.blobs.where('ownerEmail').equals(email).toArray()
  const drop = rows.filter((row) => keep.has(row.noteId)).map((row) => [email, row.id] as [string, string])
  if (drop.length) await store.blobs.bulkDelete(drop)
}

export const deleteNoteBlob = async (ownerEmail: string, id: string) => {
  const store = getDb()
  if (!store) return
  await store.blobs.delete([ownerEmail.trim().toLowerCase(), id])
}

export const duplicateNoteBlobs = async (ownerEmail: string, source: Note, copyId: number) => {
  const email = ownerEmail.trim().toLowerCase()
  const ids = collectBlobIds(source)
  let body = source.body
  const attachments: Attachment[] = []
  for (const id of ids) {
    const record = await readNoteBlob(email, id)
    const nextId = `att-${copyId}-${id}`
    if (record) {
      await putNoteBlob({
        ...record,
        id: nextId,
        noteId: copyId,
      })
      body = body.replaceAll(`notes-blob:${id}`, blobMarkdownSrc(nextId))
    }
  }
  for (const item of source.attachments) {
    attachments.push({
      ...attachmentMeta(item),
      id: `att-${copyId}-${item.id}`,
    })
  }
  return { body, attachments }
}

const migrateNoteMedia = async (email: string, notes: Note[]) => {
  const store = getDb()
  const next: Note[] = []
  let dirty = false
  for (const note of notes) {
    let body = note.body
    const attachments: Attachment[] = []
    const inline: Array<{ alt: string; dataUrl: string }> = []
    body.replace(/!\[([^\]]*)\]\((data:[^)]+)\)/g, (_full, alt: string, dataUrl: string) => {
      inline.push({ alt, dataUrl })
      return _full
    })
    for (const [index, item] of inline.entries()) {
      const id = `att-${note.id}-img-${index}`
      await putNoteBlob({
        id,
        ownerEmail: email,
        noteId: note.id,
        name: item.alt || 'Image',
        mime: dataUrlMime(item.dataUrl) || 'image/jpeg',
        createdAt: Date.now(),
        blob: dataUrlToBlob(item.dataUrl),
      })
      body = body.replace(`](${item.dataUrl})`, `](${blobMarkdownSrc(id)})`)
      dirty = true
    }
    for (const item of note.attachments) {
      if (item.dataUrl && store) {
        await putNoteBlob({
          id: item.id,
          ownerEmail: email,
          noteId: note.id,
          name: item.name,
          mime: item.mime,
          createdAt: item.createdAt,
          blob: dataUrlToBlob(item.dataUrl),
        })
        dirty = true
      }
      attachments.push(attachmentMeta(item))
    }
    next.push({ ...note, body, attachments })
  }
  if (dirty && store) await store.notes.bulkPut(next.map((note) => ({ ...note, ownerEmail: email })))
  return next
}

export const hydrateNotesForExport = async (ownerEmail: string, notes: Note[]) => {
  const email = ownerEmail.trim().toLowerCase()
  const hydrated: Note[] = []
  for (const note of notes) {
    const urls: Record<string, string> = {}
    const attachments: Attachment[] = []
    for (const id of collectBlobIds(note)) {
      const record = await readNoteBlob(email, id)
      if (!record) continue
      const dataUrl = await blobToDataUrl(record.blob)
      urls[id] = dataUrl
    }
    for (const item of note.attachments) {
      attachments.push({
        ...attachmentMeta(item),
        dataUrl: urls[item.id] || item.dataUrl,
      })
    }
    let body = note.body
    for (const [id, dataUrl] of Object.entries(urls)) {
      body = body.replaceAll(blobMarkdownSrc(id), dataUrl)
    }
    hydrated.push({ ...note, body, attachments })
  }
  return hydrated
}

export const ingestImportedAttachments = async (ownerEmail: string, notes: Note[]) => {
  const email = ownerEmail.trim().toLowerCase()
  const next: Note[] = []
  for (const note of notes) {
    let body = note.body
    const attachments: Attachment[] = []
    const inline: Array<{ alt: string; dataUrl: string }> = []
    body.replace(/!\[([^\]]*)\]\((data:[^)]+)\)/g, (_full, alt: string, dataUrl: string) => {
      inline.push({ alt, dataUrl })
      return _full
    })
    for (const [index, item] of inline.entries()) {
      const id = `att-${note.id}-imp-${index}`
      await putNoteBlob({
        id,
        ownerEmail: email,
        noteId: note.id,
        name: item.alt || 'Image',
        mime: dataUrlMime(item.dataUrl) || 'image/jpeg',
        createdAt: Date.now(),
        blob: dataUrlToBlob(item.dataUrl),
      })
      body = body.replace(`](${item.dataUrl})`, `](${blobMarkdownSrc(id)})`)
    }
    for (const item of note.attachments) {
      if (item.dataUrl) {
        await putNoteBlob({
          id: item.id,
          ownerEmail: email,
          noteId: note.id,
          name: item.name,
          mime: item.mime,
          createdAt: item.createdAt,
          blob: dataUrlToBlob(item.dataUrl),
        })
      }
      attachments.push(attachmentMeta(item))
    }
    next.push({ ...note, body, attachments })
  }
  return next
}

export const enqueueMutation = async (ownerEmail: string, kind: string, payload: unknown) => {
  const store = getDb()
  if (!store || !shouldEnqueue(kind) || !ownerEmail) return
  const email = ownerEmail.trim().toLowerCase()
  await store.mutations.add({
    ownerEmail: email,
    kind,
    payload,
    createdAt: Date.now(),
    synced: 0,
  })
  await compactStoredMutations(email)
}

const compactStoredMutations = async (ownerEmail: string) => {
  const store = getDb()
  if (!store) return []
  const email = ownerEmail.trim().toLowerCase()
  const rows = await store.mutations.where('ownerEmail').equals(email).toArray()
  const keep = compactMutations(rows)
  const keepIds = new Set(keep.map((item) => item.id))
  const drop = rows.filter((item) => item.id != null && !keepIds.has(item.id)).map((item) => item.id as number)
  if (drop.length) await store.mutations.bulkDelete(drop)
  return keep
}

export const pendingMutations = async (ownerEmail: string) => {
  if (!ownerEmail) return []
  return compactStoredMutations(ownerEmail)
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
  if (!alreadySeeded) {
    const samples = createSampleNotes(email)
    const sampleIds = new Set(samples.map((note) => note.id))
    const renamed = notes.filter((note) => {
      const sample = samples.find((item) => item.id === note.id)
      return Boolean(sample && note.title !== sample.title)
    })
    const keep = new Set(renamed.map((note) => note.id))
    const nextSamples = samples.filter((note) => !keep.has(note.id))
    const userNotes = notes.filter((note) => !sampleIds.has(note.id) && (note.id < SAMPLE_ID_MIN || note.id > SAMPLE_ID_MAX))
    notes = [...nextSamples, ...renamed, ...userNotes]
    if (nextSamples.length) await store.notes.bulkPut(nextSamples)
    await store.prefs.put({ key: seedKey(email), value: true })
    if (nextSamples.length) await enqueueMutation(email, 'account.seeded', { count: nextSamples.length })
  }

  const cutoff = Date.now() - TRASH_TTL_MS
  const expired = notes.filter((note) => note.trashedAt && note.trashedAt < cutoff)
  if (expired.length) {
    await store.notes.bulkDelete(expired.map((note) => [email, note.id] as [string, number]))
    await deleteBlobsForNotes(email, expired.map((note) => note.id))
    notes = notes.filter((note) => !expired.some((item) => item.id === note.id))
  }

  notes = isolateNotes(notes, email)
  try {
    notes = await migrateNoteMedia(email, notes)
  } catch {
    // Keep notes even if an inline image cannot be moved into blob storage.
  }

  const notebooks = ensureNotebooks(email, existingNotebooks)
  if (notebooks.length !== existingNotebooks.length) {
    await store.notebooks.bulkPut(notebooks)
  }

  return {
    notes,
    notebooks,
    templates: isolateTemplates(templates, email),
    recents: Array.isArray(pref?.value) ? (pref.value as string[]) : [],
  }
}

export const persistAccount = async (ownerEmail: string, bundle: Omit<AccountBundle, 'recents'> & { recents?: string[] }) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store) return
  const owned = isolateBundle({
    notes: bundle.notes,
    notebooks: bundle.notebooks,
    templates: bundle.templates,
    recents: bundle.recents ?? [],
  }, email)
  const current = await store.notes.where('ownerEmail').equals(email).toArray()
  const currentIds = new Set(current.map((note) => note.id))
  const nextIds = new Set(owned.notes.map((note) => note.id))
  const removed = [...currentIds].filter((id) => !nextIds.has(id)).map((id) => [email, id] as [string, number])
  await store.transaction('rw', store.notes, store.notebooks, store.templates, store.prefs, store.blobs, async () => {
    if (removed.length) {
      await store.notes.bulkDelete(removed)
      await deleteBlobsForNotes(email, removed.map((item) => item[1]))
    }
    await store.notes.bulkPut(owned.notes.map((note) => ({
      ...note,
      ownerEmail: email,
      attachments: note.attachments.map(attachmentMeta),
    })))
    await store.notebooks.bulkPut(owned.notebooks.map((item) => ({ ...item, ownerEmail: email })))
    const existingTemplates = await store.templates.where('ownerEmail').equals(email).toArray()
    const keep = new Set(owned.templates.map((item) => item.id))
    const drop = existingTemplates.filter((item) => !keep.has(item.id)).map((item) => [email, item.id] as [string, string])
    if (drop.length) await store.templates.bulkDelete(drop)
    if (owned.templates.length) await store.templates.bulkPut(owned.templates.map((item) => ({ ...item, ownerEmail: email })))
    if (bundle.recents) {
      await store.prefs.put({
        key: recentsKey(email),
        value: bundle.recents.slice(0, SEARCH_RECENTS_LIMIT),
      })
    }
  })
}

export const rememberSearch = async (ownerEmail: string, query: string, recents: string[]) => {
  const next = [query, ...recents.filter((item) => item !== query)].slice(0, SEARCH_RECENTS_LIMIT)
  const store = getDb()
  if (store) await store.prefs.put({ key: recentsKey(ownerEmail), value: next })
  return next
}

export const accountStorageStats = async (ownerEmail: string) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  const pending = await pendingMutations(email)
  if (!store) {
    return { pending: pending.length, notes: 0, blobs: 0, usageLabel: null as string | null }
  }
  const [notes, blobs] = await Promise.all([
    store.notes.where('ownerEmail').equals(email).count(),
    store.blobs.where('ownerEmail').equals(email).count(),
  ])
  let usageLabel: string | null = null
  if (typeof navigator !== 'undefined' && navigator.storage?.estimate) {
    const estimate = await navigator.storage.estimate()
    if (typeof estimate.usage === 'number') usageLabel = formatBytes(estimate.usage)
  }
  return { pending: pending.length, notes, blobs, usageLabel }
}

export const loadHabits = async (ownerEmail: string) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store || !email) return { habits: [] as Habit[], checks: [] as HabitCheck[] }
  const [habits, checks] = await Promise.all([
    store.habits.where('ownerEmail').equals(email).toArray(),
    store.habitChecks.where('ownerEmail').equals(email).toArray(),
  ])
  return {
    habits: isolateHabits(habits, email).sort((a, b) => a.createdAt - b.createdAt),
    checks: isolateHabitChecks(checks, email),
  }
}

export const putHabit = async (habit: Habit) => {
  const store = getDb()
  if (!store) return
  const email = habit.ownerEmail.trim().toLowerCase()
  await store.habits.put({ ...habit, ownerEmail: email })
}

export const deleteHabitRecord = async (ownerEmail: string, id: string) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store || !email) return
  await store.transaction('rw', store.habits, store.habitChecks, async () => {
    await store.habits.delete([email, id])
    await store.habitChecks.where('[ownerEmail+habitId]').equals([email, id]).delete()
  })
}

export const putHabitCheck = async (check: HabitCheck) => {
  const store = getDb()
  if (!store) return
  const email = check.ownerEmail.trim().toLowerCase()
  await store.habitChecks.put({ ...check, ownerEmail: email })
}

export const deleteHabitCheck = async (ownerEmail: string, habitId: string, date: string) => {
  const store = getDb()
  const email = ownerEmail.trim().toLowerCase()
  if (!store) return
  await store.habitChecks.delete([email, habitId, date])
}
