"use client"

import {
  Bell,
  Bookmark,
  BookMarked,
  CalendarDays,
  Lightbulb,
  ListChecks,
  Mic,
  NotebookPen,
  Plus,
  SunMedium,
  UsersRound,
  UserRound,
} from 'lucide-react'
import { useEffect, useRef, useState, type MouseEvent, type ReactNode } from 'react'
import { tickHaptic } from '@/lib/native/haptics'
import type { AppTab, SavedTemplate } from '@/lib/notes'

export type AddAction =
  | 'note'
  | 'list'
  | 'daily'
  | 'idea'
  | 'meeting'
  | 'reminder'
  | 'capture'
  | `saved:${string}`

const ADD_ITEMS: Array<{
  action: Exclude<AddAction, `saved:${string}`>
  label: string
  tone: string
  icon: ReactNode
}> = [
  { action: 'note', label: 'Note', tone: '#C5CA8A', icon: <NotebookPen size={18} strokeWidth={1.8} /> },
  { action: 'list', label: 'Checklist', tone: '#E7A3A3', icon: <ListChecks size={18} strokeWidth={1.8} /> },
  { action: 'daily', label: 'Daily log', tone: '#A9D4C4', icon: <SunMedium size={18} strokeWidth={1.8} /> },
  { action: 'idea', label: 'Idea', tone: '#D4C4E8', icon: <Lightbulb size={18} strokeWidth={1.8} /> },
  { action: 'meeting', label: 'Meeting', tone: '#BEC3BC', icon: <UsersRound size={18} strokeWidth={1.8} /> },
  { action: 'reminder', label: 'Reminder', tone: '#E8C44A', icon: <Bell size={18} strokeWidth={1.8} /> },
  { action: 'capture', label: 'Quick capture', tone: '#E89569', icon: <Mic size={18} strokeWidth={1.8} /> },
]

const SAVED_TONES = ['#C5CA8A', '#E7A3A3', '#D4C4E8', '#A9D4C4', '#E8C44A', '#E89569']

export default function AppTabs({
  tab,
  hidden,
  onChange,
  onAdd,
  onWriteHold,
  planAlert,
  templates = [],
}: {
  tab: AppTab
  hidden?: boolean
  onChange: (tab: AppTab) => void
  onAdd: (action: AddAction) => void
  onWriteHold?: () => void
  planAlert?: boolean
  templates?: Pick<SavedTemplate, 'id' | 'name'>[]
}) {
  const timer = useRef<number | null>(null)
  const held = useRef(false)
  const [open, setOpen] = useState(false)

  const clear = () => {
    if (timer.current) window.clearTimeout(timer.current)
    timer.current = null
  }

  const close = () => setOpen(false)

  const toggle = () => {
    setOpen((current) => {
      if (!current) tickHaptic()
      return !current
    })
  }

  const pick = (action: AddAction) => {
    setOpen(false)
    onAdd(action)
  }

  useEffect(() => {
    if (hidden) setOpen(false)
  }, [hidden])

  useEffect(() => {
    if (!open) return
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open])

  if (hidden) return null

  const item = (id: AppTab, label: string, icon: ReactNode, alert = false) => (
    <button
      type="button"
      onClick={() => {
        close()
        onChange(id)
      }}
      className={`relative flex min-h-12 min-w-0 flex-1 flex-col items-center justify-center gap-0.5 rounded-2xl text-[0.68rem] font-medium ${
        tab === id ? 'text-white' : 'text-white/55'
      }`}
    >
      <span className="relative">
        {icon}
        {alert && (
          <span className="absolute -right-1 -top-0.5 h-2 w-2 rounded-full bg-[#E7A3A3]" />
        )}
      </span>
      {label}
    </button>
  )

  const write = {
    onClick: () => {
      if (held.current) {
        held.current = false
        return
      }
      toggle()
    },
    onContextMenu: (event: MouseEvent) => {
      if (!onWriteHold) return
      event.preventDefault()
      clear()
      close()
      onWriteHold()
    },
    onPointerDown: () => {
      if (open || !onWriteHold) return
      held.current = false
      timer.current = window.setTimeout(() => {
        held.current = true
        close()
        onWriteHold()
      }, 480)
    },
    onPointerUp: clear,
    onPointerCancel: clear,
    onPointerLeave: clear,
  }

  return (
    <nav
      className="app-tabs fixed inset-x-0 bottom-0 z-30 px-3"
      style={{ paddingBottom: 'max(0.45rem, env(safe-area-inset-bottom))' }}
    >
      {open && (
        <button
          type="button"
          aria-label="Close add menu"
          className="app-add-overlay"
          onClick={close}
        />
      )}
      <div className="relative z-[1] mx-auto w-full max-w-md">
        <div className="app-dock">
          {open && (
            <div className="app-add-wrap" id="app-add-sheet">
              <div className="app-add-sheet" role="dialog" aria-modal="true" aria-labelledby="app-add-title">
                <p id="app-add-title" className="pb-2 text-center text-[1.05rem] font-medium tracking-[-0.02em] text-white">
                  Add...
                </p>
                <div className="app-add-list">
                  {ADD_ITEMS.map((row, index) => (
                    <AddRow
                      key={row.action}
                      label={row.label}
                      tone={row.tone}
                      icon={row.icon}
                      delay={index * 32}
                      onClick={() => pick(row.action)}
                    />
                  ))}
                  {templates.map((template, index) => (
                    <AddRow
                      key={template.id}
                      label={template.name}
                      tone={SAVED_TONES[index % SAVED_TONES.length]}
                      icon={<Bookmark size={18} strokeWidth={1.8} />}
                      delay={(ADD_ITEMS.length + index) * 32}
                      onClick={() => pick(`saved:${template.id}`)}
                    />
                  ))}
                </div>
              </div>
            </div>
          )}
          <div className="app-dock-bar">
            <div className="app-dock-side">
              {item('notes', 'Notes', <NotebookPen size={20} strokeWidth={tab === 'notes' ? 2.3 : 1.7} />)}
              {item('notebooks', 'Books', <BookMarked size={20} strokeWidth={tab === 'notebooks' ? 2.3 : 1.7} />)}
            </div>
            <div className="app-dock-slot" aria-hidden="true" />
            <div className="app-dock-side">
              {item('plan', 'Plan', <CalendarDays size={20} strokeWidth={tab === 'plan' ? 2.3 : 1.7} />, planAlert)}
              {item('you', 'You', <UserRound size={20} strokeWidth={tab === 'you' ? 2.3 : 1.7} />)}
            </div>
          </div>
          <div className="app-dock-fab">
            <div className="app-dock-bump" aria-hidden="true" />
            <button
              type="button"
              aria-label={open ? 'Close add menu' : 'Add a note. Press and hold for quick capture.'}
              aria-expanded={open}
              aria-controls={open ? 'app-add-sheet' : undefined}
              className={`app-dock-plus fab-press ${open ? 'is-open' : ''}`}
              {...write}
            >
              <span className="app-dock-plus-icon">
                <Plus size={22} strokeWidth={1.7} />
              </span>
            </button>
          </div>
        </div>
        <div className="app-dock-dash mx-auto" aria-hidden="true" />
      </div>
    </nav>
  )
}

function AddRow({
  label,
  tone,
  icon,
  delay,
  onClick,
}: {
  label: string
  tone: string
  icon: ReactNode
  delay: number
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="app-add-item flex min-h-[3.35rem] w-full items-center gap-3.5 rounded-2xl px-1.5 text-left active:bg-white/10"
      style={{ animationDelay: `${delay}ms` }}
    >
      <span
        className="grid h-11 w-11 shrink-0 place-items-center rounded-full text-[#2b261f]"
        style={{ backgroundColor: tone }}
      >
        {icon}
      </span>
      <span className="text-[1.02rem] font-medium tracking-[-0.02em] text-white">{label}</span>
    </button>
  )
}
