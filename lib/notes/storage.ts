import Dexie, { type Table } from 'dexie'
import { TRASH_TTL_MS, LEGACY_STORAGE_KEY, SEARCH_RECENTS_LIMIT, type AccountBundle, type Attachment, type BlobRecord, type Note, type Notebook, type QueuedMutation, type SavedTemplate } from './types.ts'
import { normalizeNote } from './normalize.ts'
import { ensureNotebooks } from './notebooks.ts'
import { createSampleNotes } from './seed.ts'
import {
  attachmentMeta,
  blobMarkdownSrc,
  blobToDataUrl,
  collectBlobIds,
  dataUrlToBlob,
} from './blobs.ts'
import { compactMutations, formatBytes, shouldEnqueue } from './queue.ts'
import { isolateBundle, isolateNotes, isolateTemplates } from './isolation.ts'

type PrefRow = { key: string; value: unknown }

class NotesDatabase extends Dexie {
  notes!: Table<Note, [string, number]>
  notebooks!: Table<Notebook, [string, string]>
  templates!: Table<SavedTemplate, [string, string]>
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
        mime: /data:([^;]+)/.exec(item.dataUrl)?.[1] || 'image/jpeg',
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
        mime: /data:([^;]+)/.exec(item.dataUrl)?.[1] || 'image/jpeg',
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
    await deleteBlobsForNotes(email, expired.map((note) => note.id))
    notes = notes.filter((note) => !expired.some((item) => item.id === note.id))
  }

  notes = isolateNotes(notes, email)
  notes = await migrateNoteMedia(email, notes)

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
