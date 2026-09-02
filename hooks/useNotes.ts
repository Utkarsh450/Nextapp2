import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import {
  applyTemplate,
  createNotebook,
  templateFromSaved,
  dailyNoteTitle,
  enqueueMutation,
  findDailyNote,
  loadAccount,
  moveNote,
  newId,
  normalizeNote,
  persistAccount,
  randomNoteColor,
  rememberSearch,
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

const reminderDate = (dueAt: string | null) => {
  if (!dueAt) return null
  const at = new Date(`${dueAt}T09:00:00`)
  return Number.isNaN(at.getTime()) ? null : at
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
  const skipPersist = useRef(true)

  if (ownerEmail !== loadedFor) {
    setLoadedFor(ownerEmail)
    setNotes([])
    setNotebooks([])
    setTemplates([])
    setRecents([])
    setReady(false)
  }

  const snapshot = useMemo(
    () => ({ notes, notebooks, templates, recents }),
    [notes, notebooks, templates, recents]
  )
  const debounced = useDebouncedValue(snapshot, 400)

  useEffect(() => {
    let cancelled = false
    if (!ownerEmail) return
    void loadAccount(ownerEmail).then((bundle) => {
      if (cancelled) return
      setNotes(bundle.notes)
      setNotebooks(bundle.notebooks)
      setTemplates(bundle.templates)
      setRecents(bundle.recents)
      setReady(true)
      skipPersist.current = true
    })
    return () => {
      cancelled = true
    }
  }, [ownerEmail])

  useEffect(() => {
    if (!ready || !ownerEmail) return
    if (skipPersist.current) {
      skipPersist.current = false
      return
    }
    void persistAccount(ownerEmail, debounced)
  }, [debounced, ownerEmail, ready])

  const patchNote = useCallback((id: number, updater: (note: Note) => Note) => {
    setNotes((current) => current.map((note) => (note.id === id ? updater(note) : note)))
  }, [])

  const saveNote = useCallback((next: Note) => {
    if (!ownerEmail) return next
    const stamped = { ...next, ownerEmail, updatedAt: Date.now() }
    setNotes((current) => {
      const exists = current.some((note) => note.id === next.id)
      return exists
        ? current.map((note) => (note.id === next.id ? stamped : note))
        : [stamped, ...current]
    })
    const at = reminderDate(stamped.remindAt || stamped.dueAt)
    if (at) {
      void scheduleNoteReminder({
        id: stamped.id,
        title: stamped.title || 'Note reminder',
        body: stamped.preview || stamped.body.slice(0, 80),
        at,
      })
    } else {
      void cancelNoteReminder(stamped.id)
    }
    void enqueueMutation(ownerEmail, 'note.saved', { id: stamped.id })
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
      dueAt: partial.dueAt ?? null,
      remindAt: partial.remindAt ?? partial.dueAt ?? null,
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
    return createBlank({
      ...note,
      title: note.title ? `${note.title} copy` : 'Untitled copy',
      pinned: false,
      archived: false,
      trashedAt: null,
    })
  }, [createBlank])

  const moveToTrash = useCallback((id: number) => {
    setNotes((current) => current.map((note) => (note.id === id ? trashNote(note) : note)))
    void cancelNoteReminder(id)
    void enqueueMutation(ownerEmail ?? '', 'note.trashed', { id })
  }, [ownerEmail])

  const restoreTrashed = useCallback((id: number) => {
    setNotes((current) => {
      const next = current.map((note) => (note.id === id ? restoreFromTrash(note) : note))
      const restored = next.find((note) => note.id === id)
      const at = reminderDate(restored?.remindAt || restored?.dueAt || null)
      if (restored && at) {
        void scheduleNoteReminder({
          id: restored.id,
          title: restored.title || 'Note reminder',
          body: restored.preview || restored.body.slice(0, 80),
          at,
        })
      }
      return next
    })
  }, [])

  const deleteForever = useCallback((id: number) => {
    setNotes((current) => current.filter((note) => note.id !== id))
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
    patchNote(id, (note) => ({ ...note, archived: !note.archived, pinned: false, updatedAt: Date.now() }))
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
      remindAt: draft.dueAt,
    })
  }, [createBlank])

  const deleteTemplate = useCallback((id: string) => {
    setTemplates((current) => current.filter((item) => item.id !== id))
  }, [])

  const rememberQuery = useCallback(async (query: string) => {
    if (!ownerEmail) return recents
    const next = await rememberSearch(ownerEmail, query, recents)
    setRecents(next)
  }, [ownerEmail, recents])

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
    dailyTitle: dailyNoteTitle(),
  }
}
