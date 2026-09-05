"use client"

import { useEffect, useMemo, useRef, useState } from 'react'
import EmptyState from '@/components/ui/EmptyState'
import PaperStage from '@/components/ui/PaperStage'
import Toast from '@/components/ui/Toast'
import AccountPanel from '@/features/account/AccountPanel'
import AuthScreen from '@/features/auth/AuthScreen'
import OnboardingScreen from '@/features/auth/OnboardingScreen'
import AppHeader from '@/features/shell/AppHeader'
import AppTabs, { type AddAction } from '@/features/shell/AppTabs'
import { useNotes } from '@/hooks/useNotes'
import { useHabits } from '@/hooks/useHabits'
import { useOnline } from '@/hooks/useOnline'
import { useSession, useTheme, useSkin, useLayout } from '@/hooks/useSession'
import {
  exportNotesMarkdown,
  insertWikiLink,
  labelTint,
  noteDashboard,
  uniqueColors,
  uniqueLabels,
  upcomingReminders,
  visibleNotes,
  todayISO,
  noteAgenda,
  type AppTab,
  type FilterKey,
  type Note,
} from '@/lib/notes'
import {
  calendarAlertsAvailable,
  enableCalendarAlerts,
  watchReminderOpens,
} from '@/lib/native/notifications'
import { hasFinishedOnboarding, markOnboardingDone } from '@/lib/onboarding'
import {
  profileFromEmail,
  profileToAccountUser,
  readStoredProfiles,
  saveProfileForEmail,
  type UserProfile,
} from '@/lib/profile'
import CreateSheet from './CreateSheet'
import NoteDetail from './NoteDetail'
import NoteEditor from './NoteEditor'
import NotebooksView from './NotebooksView'
import NotesGrid from './NotesGrid'
import PlanView from './PlanView'
import SearchOverlay from './SearchOverlay'
import TodayBoard from './TodayBoard'

const FILTERS: Array<{ id: FilterKey; label: string }> = [
  { id: 'all', label: 'All' },
  { id: 'open', label: 'Open' },
  { id: 'due', label: 'Due' },
  { id: 'done', label: 'Done' },
  { id: 'archived', label: 'Archive' },
  { id: 'trash', label: 'Trash' },
]

const download = (filename: string, text: string, type: string) => {
  const blob = new Blob([text], { type })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

export default function NotesApp() {
  const { session, loading, sendOtp, verifyOtp, logout } = useSession()
  const { theme, toggle } = useTheme()
  const { skin, setPaperSkin } = useSkin()
  const { layout, setBoardLayout } = useLayout()
  const online = useOnline()
  const email = session?.email ?? ''
  const board = useNotes(session?.email ?? null)
  const habits = useHabits(session?.email ?? null)
  const [tab, setTab] = useState<AppTab>('notes')
  const [searchOpen, setSearchOpen] = useState(false)
  const [createOpen, setCreateOpen] = useState(false)
  const [openId, setOpenId] = useState<number | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [toast, setToast] = useState<{ message: string; actionLabel?: string; onAction?: () => void } | null>(null)
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [templateDraft, setTemplateDraft] = useState('')
  const [savingTemplate, setSavingTemplate] = useState<Note | null>(null)
  const [emptyingTrash, setEmptyingTrash] = useState(false)
  const [onboarded, setOnboarded] = useState<boolean | null>(null)
  const pendingOpen = useRef<number | null>(null)

  useEffect(() => {
    return watchReminderOpens((id) => {
      pendingOpen.current = id
      setTab('notes')
      setOpenId(id)
      setIsEditing(false)
    })
  }, [])

  useEffect(() => {
    if (!session?.email) {
      setOnboarded(null)
      return
    }
    setOnboarded(hasFinishedOnboarding(session.email))
  }, [session?.email])

  useEffect(() => {
    if (!board.ready || !email || pendingOpen.current == null) return
    const id = pendingOpen.current
    if (board.notes.some((note) => note.id === id)) {
      pendingOpen.current = null
      setOpenId(id)
      setIsEditing(false)
      setTab('notes')
    }
  }, [board.notes, board.ready, email])

  const account = profileToAccountUser(
    profile ?? (email ? (readStoredProfiles()[email] ?? profileFromEmail(email)) : profileFromEmail('you@notes.dev')),
    email || 'you@notes.dev'
  )
  const today = todayISO()

  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(null), toast.onAction ? 4600 : 2200)
    return () => window.clearTimeout(timer)
  }, [toast])

  const shown = useMemo(
    () => visibleNotes({
      notes: board.notes,
      search: board.search,
      sortKey: board.sortKey,
      filterKey: board.filterKey,
      notebookId: board.notebookId,
      tag: board.tag,
      label: board.label,
      color: board.color,
      today,
      ownerEmail: email,
    }),
    [board.color, board.filterKey, board.label, board.notebookId, board.notes, board.search, board.sortKey, board.tag, email, today]
  )

  const searchHits = useMemo(
    () => visibleNotes({
      notes: board.notes,
      search: board.search,
      sortKey: 'newest',
      filterKey: 'all',
      notebookId: null,
      tag: null,
      label: board.label,
      color: board.color,
      today,
      ownerEmail: email,
    }),
    [board.color, board.label, board.notes, board.search, email, today]
  )

  const reminders = useMemo(
    () => upcomingReminders(board.notes.filter((note) => note.ownerEmail === email), today),
    [board.notes, email, today]
  )

  const notebookCounts = useMemo(() => {
    const counts: Record<string, number> = {}
    for (const note of board.notes) {
      if (note.trashedAt || note.archived) continue
      counts[note.notebookId] = (counts[note.notebookId] ?? 0) + 1
    }
    return counts
  }, [board.notes])

  const dash = useMemo(
    () => noteDashboard(board.notes.filter((note) => note.ownerEmail === email), board.notebooks, today),
    [board.notebooks, board.notes, email, today]
  )
  const agenda = useMemo(
    () => noteAgenda(board.notes.filter((note) => note.ownerEmail === email), today),
    [board.notes, email, today]
  )
  const showToday =
    tab === 'notes' &&
    board.filterKey === 'all' &&
    !board.notebookId &&
    !board.search.trim() &&
    !board.label &&
    !board.color
  const labels = useMemo(() => uniqueLabels(board.notes.filter((note) => note.ownerEmail === email)), [board.notes, email])
  const colors = useMemo(() => uniqueColors(board.notes.filter((note) => note.ownerEmail === email)), [board.notes, email])
  const opened = board.notes.find((note) => note.id === openId) ?? null
  const liveNotes = board.notes.filter((note) => !note.trashedAt && !note.archived && note.ownerEmail === email)
  const ping = (message: string, actionLabel?: string, onAction?: () => void) =>
    setToast({ message, actionLabel, onAction })

  if (loading || (session && onboarded === null)) {
    return (
      <PaperStage>
        <div className="grid min-h-dvh place-items-center text-[var(--muted)]">Opening notes…</div>
      </PaperStage>
    )
  }

  if (!session) {
    return <AuthScreen sendOtp={sendOtp} verifyOtp={verifyOtp} />
  }

  if (!onboarded) {
    return (
      <OnboardingScreen
        email={email}
        skin={skin}
        onSkin={setPaperSkin}
        onFinish={(next) => {
          saveProfileForEmail(email, next)
          setProfile(next)
          markOnboardingDone(email)
          setOnboarded(true)
        }}
      />
    )
  }

  const openNote = (id: number) => {
    setOpenId(id)
    setIsEditing(false)
  }
  const editNote = (id: number) => {
    setOpenId(id)
    setIsEditing(true)
  }
  const closeOpened = () => {
    setOpenId(null)
    setIsEditing(false)
  }
  const handleAdd = (action: AddAction) => {
    if (action === 'capture') {
      setCreateOpen(true)
      return
    }
    if (action.startsWith('saved:')) {
      const template = board.templates.find((item) => item.id === action.slice(6))
      if (!template) return
      setTab('notes')
      editNote(board.createFromSavedTemplate(template).id)
      return
    }
    setTab('notes')
    if (action === 'note') editNote(board.createBlank().id)
    else if (action === 'list') editNote(board.createBlank({ body: '- [ ] \n- [ ] \n- [ ] ' }).id)
    else if (action === 'daily') editNote(board.openDailyNote().id)
    else if (action === 'idea') editNote(board.createFromTemplate('idea').id)
    else if (action === 'meeting') editNote(board.createFromTemplate('meeting').id)
    else if (action === 'reminder') editNote(board.createBlank({ dueAt: todayISO() }).id)
  }
  const duplicate = (id: number) => {
    const note = board.notes.find((item) => item.id === id)
    if (note) board.duplicateNote(note)
  }

  const saveProfile = (next: UserProfile) => {
    saveProfileForEmail(email, next)
    setProfile(next)
    ping('Profile saved')
  }

  return (
    <div className="notes-board min-h-dvh">
      <AppHeader
        title={board.notebookId ? (board.notebooks.find((item) => item.id === board.notebookId)?.name ?? 'Notes') : 'Notes'}
        quiet={tab !== 'notes' || showToday}
        layout={layout}
        showLayout={tab === 'notes'}
        onSearch={() => setSearchOpen(true)}
        onLayout={setBoardLayout}
      />

      {!online && (
        <p className="mx-4 mb-3 rounded-2xl bg-white/70 px-4 py-3 text-sm text-[var(--ink)] ring-1 ring-black/5 dark:bg-white/5">
          Offline · notes still save on this device
        </p>
      )}

      {showToday && (
        <TodayBoard
          name={account.name}
          dash={dash}
          onOpen={openNote}
          onDue={() => {
            board.setFilterKey('due')
            board.setLabel(null)
            board.setColor(null)
          }}
          onNotebook={(id) => {
            board.setNotebookId(id)
            board.setFilterKey('all')
            setTab('notes')
          }}
          onOpenLists={() => {
            board.setFilterKey('open')
            board.setLabel(null)
            board.setColor(null)
          }}
          onDone={() => {
            board.setFilterKey('done')
            board.setLabel(null)
            board.setColor(null)
          }}
        />
      )}

      {tab === 'notes' && !showToday && reminders.length > 0 && board.filterKey !== 'trash' && (
        <button
          type="button"
          className="mx-4 mb-3 w-[calc(100%-2rem)] rounded-[22px] bg-[#F9D368]/85 px-4 py-3.5 text-left text-sm text-zinc-800 shadow-[var(--shadow-card)]"
          onClick={() => {
            board.setFilterKey('due')
            board.setLabel(null)
            board.setColor(null)
            setTab('notes')
          }}
        >
          <p className="note-title text-[1.05rem] font-semibold leading-tight">
            {reminders.length} reminder{reminders.length === 1 ? '' : 's'} due today
          </p>
          <p className="mt-1 line-clamp-2 text-zinc-700/80">
            {reminders.slice(0, 3).map((note) => note.title || 'Untitled').join(' · ')}
          </p>
        </button>
      )}

      {tab === 'notes' && (
        <div className="mb-3 flex gap-2 overflow-x-auto px-4 notes-scrollbar-hide">
          {FILTERS.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                board.setFilterKey(item.id)
                if (item.id !== 'trash') setEmptyingTrash(false)
              }}
              className={`chip whitespace-nowrap ${board.filterKey === item.id ? 'bg-[var(--ink)] text-[var(--paper)]' : ''}`}
            >
              {item.label}
            </button>
          ))}
          {board.notebookId && (
            <button type="button" className="chip" onClick={() => board.setNotebookId(null)}>
              All notebooks
            </button>
          )}
          {board.filterKey !== 'trash' && (
            <button
              type="button"
              className="chip whitespace-nowrap"
              onClick={() => {
                const note = board.openDailyNote()
                editNote(note.id)
              }}
            >
              Today&apos;s log
            </button>
          )}
          {colors.map((item) => (
            <button
              key={item}
              type="button"
              aria-label={`Color ${item}`}
              onClick={() => board.setColor(board.color === item ? null : item)}
              className="h-7 w-7 shrink-0 rounded-full ring-1 ring-black/10"
              style={{ backgroundColor: item, outline: board.color === item ? '2px solid var(--ink)' : undefined }}
            />
          ))}
          {(board.color || board.label) && (
            <button
              type="button"
              className="chip"
              onClick={() => {
                board.setColor(null)
                board.setLabel(null)
              }}
            >
              Clear filters
            </button>
          )}
        </div>
      )}

      {tab === 'notes' && labels.length > 0 && board.filterKey !== 'trash' && (
        <div className="mb-3 flex gap-2 overflow-x-auto px-4 notes-scrollbar-hide">
          {labels.map((item) => (
            <button
              key={item}
              type="button"
              onClick={() => board.setLabel(board.label === item ? null : item)}
              className="chip whitespace-nowrap"
              style={{
                backgroundColor: `${labelTint(item)}99`,
                outline: board.label === item ? '2px solid var(--ink)' : undefined,
              }}
            >
              {item}
            </button>
          ))}
        </div>
      )}

      {tab === 'notes' && board.templates.length > 0 && board.filterKey === 'all' && (
        <div className="mb-3 flex gap-2 overflow-x-auto px-4 notes-scrollbar-hide">
          {board.templates.map((item) => (
            <TemplateChip
              key={item.id}
              name={item.name}
              onUse={() => {
                const note = board.createFromSavedTemplate(item)
                editNote(note.id)
              }}
              onRemove={() => {
                board.deleteTemplate(item.id)
                ping('Template removed')
              }}
            />
          ))}
        </div>
      )}

      {tab === 'notes' && showToday && shown.length > 0 && (
        <p className="mb-3 px-4 text-[0.72rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Your notes</p>
      )}

      {tab === 'notes' && shown.length === 0 && (
        <EmptyState
          glyph={board.filterKey === 'trash' ? '🗑️' : board.filterKey === 'due' ? '⏰' : '✎'}
          title={
            board.filterKey === 'trash'
              ? 'Trash is empty. Deleted notes wait here for 30 days.'
              : board.filterKey === 'due'
                ? 'Nothing due today.'
                : board.label
                  ? `No notes labeled ${board.label}.`
                  : 'Write your first note'
          }
          action={board.filterKey === 'trash' ? undefined : 'Write your first note'}
          onAction={board.filterKey === 'trash' ? undefined : () => setCreateOpen(true)}
        />
      )}

      {tab === 'notes' && shown.length > 0 && (
        <NotesGrid
          notes={shown}
          query={board.search}
          onOpen={openNote}
          onToggleTask={board.toggleTask}
          onPin={board.togglePin}
          onArchive={board.toggleArchive}
          onDuplicate={duplicate}
          onTrash={(id) => {
            board.moveToTrash(id)
            ping('Moved to trash', 'Undo', () => {
              board.restoreTrashed(id)
              ping('Restored')
            })
          }}
          onRestore={(id) => {
            board.restoreTrashed(id)
            ping('Restored')
          }}
          onDeleteForever={board.deleteForever}
        />
      )}

      {tab === 'notes' && board.filterKey === 'trash' && shown.length > 0 && (
        <div className="mt-4 flex justify-center px-4">
          {emptyingTrash ? (
            <button
              type="button"
              onClick={() => {
                board.emptyTrash()
                setEmptyingTrash(false)
                ping('Trash emptied')
              }}
              className="text-sm font-semibold text-red-700"
            >
              Empty now
            </button>
          ) : (
            <button type="button" onClick={() => setEmptyingTrash(true)} className="text-sm text-red-700">
              Empty trash
            </button>
          )}
        </div>
      )}

      {tab === 'plan' && (
        <PlanView
          agenda={agenda}
          today={today}
          habits={habits.habits}
          checks={habits.checks}
          onOpen={openNote}
          onAddHabit={habits.addHabit}
          onRemoveHabit={habits.removeHabit}
          onToggleHabit={habits.toggleCheck}
        />
      )}

      {tab === 'notebooks' && (
        <NotebooksView
          notebooks={board.notebooks}
          counts={notebookCounts}
          onOpen={(id) => {
            board.setNotebookId(id)
            board.setFilterKey('all')
            setTab('notes')
          }}
          onCreate={(name, color) => board.addNotebook(name, color)}
          onRename={(id, name) => board.updateNotebook(id, { name })}
          onRecolor={(id, color) => board.updateNotebook(id, { color })}
        />
      )}

      {tab === 'you' && (
        <AccountPanel
          user={account}
          email={email}
          notesCount={liveNotes.length}
          notebooksCount={board.notebooks.length}
          reminderCount={agenda.waiting}
          trashCount={board.notes.filter((note) => note.trashedAt && note.ownerEmail === email).length}
          onSave={saveProfile}
          onLogout={() => void logout()}
          onExportMarkdown={() => download('notes.md', exportNotesMarkdown(liveNotes), 'text/markdown')}
          onExportJson={() => {
            void board.exportBackup().then((raw) => download('notes.json', raw, 'application/json'))
          }}
          onOpenTrash={() => {
            board.setFilterKey('trash')
            setTab('notes')
          }}
          onOpenNotes={() => {
            board.setFilterKey('all')
            board.setNotebookId(null)
            setTab('notes')
          }}
          onOpenBooks={() => setTab('notebooks')}
          onOpenPlan={() => setTab('plan')}
          onImportJson={(raw) => {
            void board.importBackup(raw).then((count) => {
              ping(count ? `Imported ${count} notes` : 'Nothing new to import')
            }).catch(() => ping('Could not import that file'))
          }}
          online={online}
          pendingCount={board.pendingCount}
          usageLabel={board.usageLabel}
          persistError={board.persistError}
          skin={skin}
          onSkin={setPaperSkin}
          dark={theme === 'dark'}
          onToggleTheme={toggle}
          onEnableAlerts={
            calendarAlertsAvailable()
              ? () => {
                  void enableCalendarAlerts().then((result) => {
                    board.resyncReminders()
                    ping(
                      result.ok
                        ? 'Phone alerts are on. Timed notes will ping like Calendar.'
                        : result.reason === 'denied'
                          ? 'Notifications are off. Allow them in Android settings.'
                          : 'Alerts need the Android app.'
                    )
                  })
                }
              : undefined
          }
        />
      )}

      <AppTabs
        tab={tab}
        hidden={Boolean(opened) || searchOpen}
        planAlert={agenda.overdue.length + agenda.dueToday.length > 0}
        templates={board.templates}
        onChange={(next) => {
          setTab(next)
          if (next !== 'notes') {
            board.setFilterKey('all')
            setEmptyingTrash(false)
          }
        }}
        onAdd={handleAdd}
        onWriteHold={() => setCreateOpen(true)}
      />
      <Toast message={toast?.message ?? null} actionLabel={toast?.actionLabel} onAction={toast?.onAction} />

      <SearchOverlay
        open={searchOpen}
        value={board.search}
        recents={board.recents}
        hits={searchHits}
        labels={labels}
        activeLabel={board.label}
        activeColor={board.color}
        onChange={board.setSearch}
        onClose={() => setSearchOpen(false)}
        onSubmit={(value) => {
          if (value.trim()) void board.rememberQuery(value.trim())
          board.setFilterKey('all')
          setSearchOpen(false)
          setTab('notes')
        }}
        onPickRecent={(value) => {
          board.setSearch(value)
          void board.rememberQuery(value)
          setSearchOpen(false)
          setTab('notes')
        }}
        onPickLabel={(value) => {
          board.setLabel(value)
          board.setFilterKey('all')
          setSearchOpen(false)
          setTab('notes')
        }}
        onPickColor={(value) => {
          board.setColor(value)
          board.setFilterKey('all')
          setSearchOpen(false)
          setTab('notes')
        }}
        onOpen={(id) => {
          setSearchOpen(false)
          setTab('notes')
          openNote(id)
        }}
      />

      <CreateSheet
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        templates={board.templates}
        onVoiceMissing={() => ping('Voice is not available in this browser')}
        onUseTemplate={(id) => {
          const template = board.templates.find((item) => item.id === id)
          if (!template) return
          const note = board.createFromSavedTemplate(template)
          editNote(note.id)
          setTab('notes')
        }}
        onCreate={({ title, body, template }) => {
          const note = template ? board.createFromTemplate(template) : board.createBlank({ title, body })
          if (!template && (title || body)) board.saveNote({ ...note, title, body, preview: body.slice(0, 80) })
          editNote(note.id)
          setTab('notes')
        }}
      />

      {opened && !isEditing && (
        <div className="fixed inset-0 z-50">
          <NoteDetail
            note={opened}
            notes={board.notes}
            onClose={closeOpened}
            onEdit={() => setIsEditing(true)}
            onChange={(note) => board.saveNote(note)}
            onOpenNote={openNote}
            onRestore={() => {
              board.restoreTrashed(opened.id)
              ping('Restored')
            }}
            onDelete={() => {
              const id = opened.id
              board.moveToTrash(id)
              closeOpened()
              ping('Moved to trash', 'Undo', () => {
                board.restoreTrashed(id)
                ping('Restored')
              })
            }}
            onDeleteForever={() => {
              board.deleteForever(opened.id)
              closeOpened()
              ping('Deleted')
            }}
          />
        </div>
      )}

      {opened && isEditing && (
        <div className="fixed inset-0 z-50 bg-[var(--paper)]">
          <NoteEditor
            note={opened}
            notes={board.notes}
            notebooks={board.notebooks}
            onChange={(note: Note) => board.saveNote(note)}
            onClose={() => setIsEditing(false)}
            onSaveTemplate={(note) => {
              setSavingTemplate(note)
              setTemplateDraft(note.title || 'Template')
            }}
            onAddFiles={(files, intoBody) => {
              void board.addFilesToNote(opened, files, intoBody)
            }}
            onRemoveAttachment={(id) => {
              void board.removeAttachment(opened, id)
            }}
            onOpenNote={(id) => openNote(id)}
            onCreateLinked={(title) => {
              board.saveNote({ ...opened, body: insertWikiLink(opened.body, title) })
              const created = board.createBlank({ title })
              editNote(created.id)
            }}
            onExport={() => download(`${opened.title || 'note'}.md`, exportNotesMarkdown([opened]), 'text/markdown')}
            onVoiceMissing={() => ping('Voice is not available in this browser')}
          />
        </div>
      )}

      {savingTemplate && (
        <div className="fixed inset-0 z-[60] flex items-end bg-black/25 sm:items-center sm:justify-center" onClick={() => setSavingTemplate(null)}>
          <form
            className="sheet-up w-full max-w-md rounded-t-[28px] bg-[var(--paper)] p-4 sm:rounded-[28px]"
            style={{ paddingBottom: 'max(1rem, env(safe-area-inset-bottom))' }}
            onClick={(event) => event.stopPropagation()}
            onSubmit={(event) => {
              event.preventDefault()
              board.saveTemplate(savingTemplate, templateDraft.trim() || savingTemplate.title || 'Template')
              setSavingTemplate(null)
              ping('Template saved')
            }}
          >
            <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Save template</p>
            <input
              autoFocus
              value={templateDraft}
              onChange={(event) => setTemplateDraft(event.target.value)}
              className="mt-3 min-h-12 w-full rounded-2xl bg-white/70 px-3 text-base outline-none dark:bg-white/5"
              placeholder="Template name"
            />
            <button type="submit" className="mt-4 min-h-12 w-full rounded-full bg-[var(--ink)] font-semibold text-[var(--paper)]">
              Save
            </button>
          </form>
        </div>
      )}
    </div>
  )
}

function TemplateChip({
  name,
  onUse,
  onRemove,
}: {
  name: string
  onUse: () => void
  onRemove: () => void
}) {
  const timer = useRef<number | null>(null)
  const removed = useRef(false)

  const clear = () => {
    if (timer.current) window.clearTimeout(timer.current)
    timer.current = null
  }

  return (
    <button
      type="button"
      className="chip"
      onClick={() => {
        if (removed.current) {
          removed.current = false
          return
        }
        onUse()
      }}
      onContextMenu={(event) => {
        event.preventDefault()
        clear()
        onRemove()
      }}
      onPointerDown={() => {
        removed.current = false
        timer.current = window.setTimeout(() => {
          removed.current = true
          onRemove()
        }, 550)
      }}
      onPointerUp={clear}
      onPointerCancel={clear}
      onPointerLeave={clear}
    >
      {name}
    </button>
  )
}
