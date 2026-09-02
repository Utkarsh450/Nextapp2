import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  applyTemplate,
  attachmentMeta,
  blobMarkdownSrc,
  compressImageToBlob,
  createNotebook,
  templateFromSaved,
  dailyNoteTitle,
  duplicateNoteBlobs,
  enqueueMutation,
  findDailyNote,
  hydrateNotesForExport,
  accountStorageStats,
  ingestImportedAttachments,
  importNotesJson,
  isolateNotes,
  isImageMime,
  loadAccount,
  moveNote,
  newId,
  normalizeNote,
  persistAccount,
  putNoteBlob,
  deleteNoteBlob,
  randomNoteColor,
  pendingMutations,
  rememberSearch,
  reminderBody,
  reminderFields,
  reminderFireDate,
  restoreFromTrash,
  trashNote,
  type FilterKey,
  type Note,
  type Notebook,
  type SavedTemplate,
  type SortKey,
  type TemplateKey,
} from '@/lib/notes'
import { cancelNoteReminder, scheduleNoteReminder } from '@/lib/native/notifications'
import { useDebouncedValue } from './useDebouncedValue'

const queueReminder = (note: Note | undefined) => {
  if (!note || note.trashedAt || note.archived) {
    if (note) void cancelNoteReminder(note.id)
    return
  }
  const at = reminderFireDate(note.dueAt, note.dueTime, note.alertMinutes)
  if (at) {
    void scheduleNoteReminder({
      id: note.id,
      title: note.title || 'Note reminder',
      body: reminderBody(note.title, note.dueAt, note.dueTime, note.preview || note.body),
      at,
    })
  } else {
    void cancelNoteReminder(note.id)
  }
}

export const useNotes = (ownerEmail: string | null) => {
  const [notes, setNotes] = useState<Note[]>([])
  const [notebooks, setNotebooks] = useState<Notebook[]>([])
  const [templates, setTemplates] = useState<SavedTemplate[]>([])
  const [recents, setRecents] = useState<string[]>([])
  const [ready, setReady] = useState(false)
  const [search, setSearch] = useState('')
  const [sortKey, setSortKey] = useState<SortKey>('newest')
  const [filterKey, setFilterKey] = useState<FilterKey>('all')
  const [notebookId, setNotebookId] = useState<string | null>(null)
  const [tag, setTag] = useState<string | null>(null)
  const [label, setLabel] = useState<string | null>(null)
  const [color, setColor] = useState<string | null>(null)
  const [loadedFor, setLoadedFor] = useState<string | null>(null)
  const [pendingCount, setPendingCount] = useState(0)
  const [persistError, setPersistError] = useState<string | null>(null)
  const [usageLabel, setUsageLabel] = useState<string | null>(null)
  const skipPersist = useRef(true)

  if (ownerEmail !== loadedFor) {
    setLoadedFor(ownerEmail)
    setNotes([])
    setNotebooks([])
    setTemplates([])
    setRecents([])
    setReady(false)
    setPendingCount(0)
    setPersistError(null)
    setUsageLabel(null)
  }

  const snapshot = useMemo(
    () => ({ notes, notebooks, templates, recents }),
    [notes, notebooks, templates, recents]
  )
  const debounced = useDebouncedValue(snapshot, 400)

  const refreshStorage = useCallback(async (email: string) => {
    const stats = await accountStorageStats(email)
    setPendingCount(stats.pending)
    setUsageLabel(stats.usageLabel)
  }, [])

  useEffect(() => {
    let cancelled = false
    if (!ownerEmail) return
    void loadAccount(ownerEmail).then(async (bundle) => {
      if (cancelled) return
      const owned = isolateNotes(bundle.notes, ownerEmail)
      setNotes(owned)
      setNotebooks(bundle.notebooks)
      setTemplates(bundle.templates)
      setRecents(bundle.recents)
      setReady(true)
      skipPersist.current = true
      owned.forEach(queueReminder)
      await refreshStorage(ownerEmail)
    })
    return () => {
      cancelled = true
    }
  }, [ownerEmail, refreshStorage])

  useEffect(() => {
    if (!ready || !ownerEmail) return
    if (skipPersist.current) {
      skipPersist.current = false
      return
    }
    void persistAccount(ownerEmail, debounced)
      .then(() => {
        setPersistError(null)
        return refreshStorage(ownerEmail)
      })
      .catch(() => {
        setPersistError('Could not save notes on this device')
      })
  }, [debounced, ownerEmail, ready, refreshStorage])

  useEffect(() => {
    if (!ready || !ownerEmail) return
    const flush = () => {
      void persistAccount(ownerEmail, snapshot).catch(() => undefined)
    }
    const onHide = () => {
      if (document.visibilityState === 'hidden') flush()
    }
    window.addEventListener('pagehide', flush)
    document.addEventListener('visibilitychange', onHide)
    return () => {
      window.removeEventListener('pagehide', flush)
      document.removeEventListener('visibilitychange', onHide)
    }
  }, [ownerEmail, ready, snapshot])

  const patchNote = useCallback((id: number, updater: (note: Note) => Note) => {
    setNotes((current) => current.map((note) => (note.id === id ? updater(note) : note)))
  }, [])

  const saveNote = useCallback((next: Note) => {
    if (!ownerEmail) return next
    const stamped = {
      ...next,
      ...reminderFields(next),
      ownerEmail,
      updatedAt: Date.now(),
      attachments: next.attachments.map(attachmentMeta),
    }
    setNotes((current) => {
      const exists = current.some((note) => note.id === next.id)
      return exists
        ? current.map((note) => (note.id === next.id ? stamped : note))
        : [stamped, ...current]
    })
    queueReminder(stamped)
    void enqueueMutation(ownerEmail, 'note.saved', { id: stamped.id })
    void pendingMutations(ownerEmail).then((items) => setPendingCount(items.length))
    return stamped
  }, [ownerEmail])

  const createBlank = useCallback((partial: Partial<Note> = {}) => {
    const notebook = notebooks.find((item) => item.id === (partial.notebookId || notebookId)) ?? notebooks[0]
    const note = normalizeNote({
      id: newId(),
      ownerEmail: ownerEmail ?? '',
      title: partial.title ?? '',
      tag: partial.tag ?? '',
      preview: partial.preview ?? '',
      notebook: notebook?.name ?? 'Inbox',
      notebookId: notebook?.id ?? 'inbox',
      body: partial.body ?? '',
      color: partial.color ?? randomNoteColor(),
      ...reminderFields({
        dueAt: partial.dueAt ?? null,
        dueTime: partial.dueTime ?? null,
        alertMinutes: partial.alertMinutes,
      }),
      labels: partial.labels ?? [],
      attachments: partial.attachments ?? [],
      pinned: Boolean(partial.pinned),
      order: 0,
    }, 0, ownerEmail ?? '')
    return saveNote(note)
  }, [notebookId, notebooks, ownerEmail, saveNote])

  const createFromTemplate = useCallback((key: TemplateKey) => {
    const template = applyTemplate(key)
    const notebook = notebooks.find((item) => item.id === template.notebookId) ?? notebooks[0]
    return createBlank({
      title: template.title,
      tag: template.tag,
      preview: template.preview,
      notebookId: notebook?.id,
      body: template.body,
    })
  }, [createBlank, notebooks])

  const openDailyNote = useCallback(() => {
    const existing = findDailyNote(notes)
    if (existing) return existing
    return createFromTemplate('daily')
  }, [createFromTemplate, notes])

  const duplicateNote = useCallback((note: Note) => {
    const copy = createBlank({
      ...note,
      title: note.title ? `${note.title} copy` : 'Untitled copy',
      pinned: false,
      archived: false,
      trashedAt: null,
      attachments: [],
      body: note.body,
    })
    if (ownerEmail) {
      void duplicateNoteBlobs(ownerEmail, note, copy.id).then((cloned) => {
        saveNote({ ...copy, body: cloned.body, attachments: cloned.attachments })
      })
    }
    return copy
  }, [createBlank, ownerEmail, saveNote])

  const moveToTrash = useCallback((id: number) => {
    setNotes((current) => current.map((note) => (note.id === id ? trashNote(note) : note)))
    void cancelNoteReminder(id)
    void enqueueMutation(ownerEmail ?? '', 'note.trashed', { id })
  }, [ownerEmail])

  const restoreTrashed = useCallback((id: number) => {
    setNotes((current) => {
      const next = current.map((note) => (note.id === id ? restoreFromTrash(note) : note))
      const restored = next.find((note) => note.id === id)
      queueReminder(restored)
      return next
    })
  }, [])

  const deleteForever = useCallback((id: number) => {
    setNotes((current) => current.filter((note) => note.id !== id))
    void cancelNoteReminder(id)
    void enqueueMutation(ownerEmail ?? '', 'note.deleted', { id })
  }, [ownerEmail])

  const emptyTrash = useCallback(() => {
    setNotes((current) => {
      current.filter((note) => note.trashedAt).forEach((note) => void cancelNoteReminder(note.id))
      return current.filter((note) => !note.trashedAt)
    })
    void enqueueMutation(ownerEmail ?? '', 'trash.emptied', {})
  }, [ownerEmail])

  const togglePin = useCallback((id: number) => {
    patchNote(id, (note) => ({ ...note, pinned: !note.pinned, updatedAt: Date.now() }))
  }, [patchNote])

  const toggleArchive = useCallback((id: number) => {
    patchNote(id, (note) => {
      const next = { ...note, archived: !note.archived, pinned: false, updatedAt: Date.now() }
      queueReminder(next)
      return next
    })
  }, [patchNote])

  const toggleDone = useCallback((id: number) => {
    patchNote(id, (note) => ({ ...note, confirmed: !note.confirmed, updatedAt: Date.now() }))
  }, [patchNote])

  const reorder = useCallback((fromId: number, toId: number) => {
    setNotes((current) => moveNote(current, fromId, toId))
  }, [])

  const addNotebook = useCallback((name: string, color?: string) => {
    const notebook = createNotebook(ownerEmail ?? '', name, color)
    setNotebooks((current) => [...current, notebook])
    return notebook
  }, [ownerEmail])

  const updateNotebook = useCallback((id: string, patch: Partial<Pick<Notebook, 'name' | 'color'>>) => {
    setNotebooks((current) => current.map((item) => item.id === id ? { ...item, ...patch } : item))
    if (patch.name) {
      setNotes((current) => current.map((note) => note.notebookId === id ? { ...note, notebook: patch.name as string } : note))
    }
  }, [])

  const saveTemplate = useCallback((note: Note, name: string) => {
    const template: SavedTemplate = {
      id: `tpl-${Date.now()}`,
      ownerEmail: ownerEmail ?? '',
      name: name.trim() || note.title || 'Template',
      title: note.title,
      tag: note.tag,
      notebookId: note.notebookId,
      body: note.body,
      color: note.color,
      labels: [...note.labels],
      dueAt: note.dueAt,
      dueTime: note.dueTime,
      alertMinutes: note.alertMinutes,
      createdAt: Date.now(),
    }
    setTemplates((current) => [template, ...current])
    return template
  }, [ownerEmail])

  const createFromSavedTemplate = useCallback((template: SavedTemplate) => {
    const draft = templateFromSaved(template)
    return createBlank({
      title: draft.title,
      tag: draft.tag,
      notebookId: draft.notebookId,
      body: draft.body,
      preview: draft.preview,
      color: draft.color,
      labels: draft.labels,
      dueAt: draft.dueAt,
      dueTime: draft.dueTime,
      alertMinutes: draft.alertMinutes,
    })
  }, [createBlank])

  const deleteTemplate = useCallback((id: string) => {
    setTemplates((current) => current.filter((item) => item.id !== id))
  }, [])

  const resyncReminders = useCallback(() => {
    notes.forEach(queueReminder)
  }, [notes])

  const rememberQuery = useCallback(async (query: string) => {
    if (!ownerEmail) return recents
    const next = await rememberSearch(ownerEmail, query, recents)
    setRecents(next)
  }, [ownerEmail, recents])

  const addFilesToNote = useCallback(async (note: Note, files: File[], intoBody: boolean) => {
    if (!ownerEmail || files.length === 0) return note
    let body = note.body
    const attachments = [...note.attachments]
    for (const file of files) {
      const blob = isImageMime(file.type) ? await compressImageToBlob(file) : file
      const id = `att-${note.id}-${Date.now()}-${attachments.length}`
      await putNoteBlob({
        id,
        ownerEmail,
        noteId: note.id,
        name: file.name,
        mime: blob.type || file.type || 'application/octet-stream',
        createdAt: Date.now(),
        blob,
      })
      if (intoBody && isImageMime(blob.type || file.type)) {
        body = `${body.trim() ? `${body.replace(/\s+$/, '')}\n\n` : ''}![${file.name}](${blobMarkdownSrc(id)})`
      } else {
        attachments.push({
          id,
          name: file.name,
          mime: blob.type || file.type || 'application/octet-stream',
          createdAt: Date.now(),
        })
      }
    }
    return saveNote({ ...note, body, attachments: attachments.map(attachmentMeta), preview: body.slice(0, 80) })
  }, [ownerEmail, saveNote])

  const removeAttachment = useCallback(async (note: Note, id: string) => {
    if (ownerEmail) await deleteNoteBlob(ownerEmail, id)
    const body = note.body.replace(new RegExp(`!\\[[^\\]]*\\]\\(notes-blob:${id}\\)\\n?`, 'g'), '')
    return saveNote({
      ...note,
      body,
      attachments: note.attachments.filter((item) => item.id !== id).map(attachmentMeta),
    })
  }, [ownerEmail, saveNote])

  const exportBackup = useCallback(async () => {
    if (!ownerEmail) return '[]'
    const live = notes.filter((note) => !note.trashedAt && note.ownerEmail === ownerEmail)
    const hydrated = await hydrateNotesForExport(ownerEmail, live)
    return JSON.stringify(hydrated, null, 2)
  }, [notes, ownerEmail])

  const importBackup = useCallback(async (raw: string) => {
    if (!ownerEmail) return 0
    const merged = importNotesJson(raw, notes, ownerEmail)
    const incoming = merged.filter((note) => !notes.some((item) => item.id === note.id))
    const stored = await ingestImportedAttachments(ownerEmail, incoming)
    stored.forEach((note) => saveNote(note))
    return stored.length
  }, [notes, ownerEmail, saveNote])

  return {
    ready,
    notes,
    notebooks,
    templates,
    recents,
    search,
    setSearch,
    sortKey,
    setSortKey,
    filterKey,
    setFilterKey,
    notebookId,
    setNotebookId,
    tag,
    setTag,
    label,
    setLabel,
    color,
    setColor,
    saveNote,
    createBlank,
    createFromTemplate,
    createFromSavedTemplate,
    openDailyNote,
    duplicateNote,
    moveToTrash,
    restoreTrashed,
    deleteForever,
    emptyTrash,
    togglePin,
    toggleArchive,
    toggleDone,
    reorder,
    addNotebook,
    updateNotebook,
    saveTemplate,
    deleteTemplate,
    rememberQuery,
    addFilesToNote,
    removeAttachment,
    exportBackup,
    importBackup,
    pendingCount,
    persistError,
    usageLabel,
    resyncReminders,
    dailyTitle: dailyNoteTitle(),
  }
}
