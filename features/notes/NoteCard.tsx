"use client"

import { memo, useState, type ReactNode } from 'react'
import { Archive, Bookmark, Copy, MoreHorizontal, Pin, RotateCcw, Trash2 } from 'lucide-react'
import PaytmTick from '@/components/ui/PaytmTick'
import { cardBodyPreview, checklistProgress, dueLabel, highlightSegments, labelTint, type Note } from '@/lib/notes'

function NoteCard({
  note,
  query,
  onOpen,
  onToggleDone,
  onPin,
  onArchive,
  onDuplicate,
  onTrash,
  onRestore,
  onDeleteForever,
}: {
  note: Note
  query?: string
  onOpen: (id: number) => void
  onToggleDone: (id: number) => void
  onPin: (id: number) => void
  onArchive: (id: number) => void
  onDuplicate: (id: number) => void
  onTrash: (id: number) => void
  onRestore?: (id: number) => void
  onDeleteForever?: (id: number) => void
}) {
  const [menu, setMenu] = useState(false)
  const preview = cardBodyPreview(note.body, note.preview)
  const tasks = checklistProgress(note.body)
  const due = dueLabel(note.dueAt)

  return (
    <article
      className="note-card group relative flex min-h-[240px] w-full cursor-pointer flex-col rounded-[var(--radius-card)] p-4 text-zinc-800 shadow-[var(--shadow-card)] ring-1 ring-black/5 sm:min-h-[260px] sm:p-5"
      style={{ backgroundColor: note.color || '#F9D368' }}
      onClick={() => onOpen(note.id)}
    >
      {note.pinned && !note.trashedAt && (
        <span className="pin-fold" aria-label="Pinned" />
      )}
      <div className="flex items-start justify-between gap-2">
        <PaytmTick active={note.confirmed} onToggle={() => onToggleDone(note.id)} />
        <button
          type="button"
          aria-label="Note actions"
          onClick={(event) => {
            event.stopPropagation()
            setMenu((value) => !value)
          }}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-white/55 text-zinc-700"
        >
          <MoreHorizontal size={16} />
        </button>
      </div>
      <h2 className="mt-3 text-[1.2rem] font-semibold leading-tight tracking-tight">
        {highlightSegments(note.title || 'Untitled', query ?? '').map((part, index) => (
          <span key={index} className={part.match ? 'bg-white/70' : undefined}>{part.text}</span>
        ))}
      </h2>
      <p className="mt-2 line-clamp-6 flex-1 text-[15px] leading-relaxed text-zinc-800/80">
        {highlightSegments(preview || 'Empty note', query ?? '').map((part, index) => (
          <span key={index} className={part.match ? 'bg-white/70' : undefined}>{part.text}</span>
        ))}
      </p>
      <div className="mt-auto flex flex-wrap items-center gap-2 pt-4 text-[0.7rem] text-zinc-700/80">
        {note.notebook && <span className="rounded-full bg-white/50 px-2 py-0.5">{note.notebook}</span>}
        {tasks.total > 0 && (
          <span className="rounded-full bg-white/50 px-2 py-0.5">{tasks.done}/{tasks.total} done</span>
        )}
        {due && (
          <span
            className={`rounded-full px-2 py-0.5 ${due === 'Overdue' ? 'bg-red-500/25 text-red-900' : 'bg-white/50'}`}
          >
            {due}
          </span>
        )}
        {note.labels.slice(0, 3).map((item) => (
          <span key={item} className="rounded-full px-2 py-0.5" style={{ backgroundColor: `${labelTint(item)}99` }}>{item}</span>
        ))}
      </div>
      {menu && (
        <div className="absolute right-3 top-14 z-10 min-w-40 overflow-hidden rounded-2xl bg-white/95 py-1 text-sm shadow-[var(--shadow-card)]">
          {note.trashedAt ? (
            <>
              <MenuItem icon={<RotateCcw size={14} />} label="Restore" onClick={() => onRestore?.(note.id)} />
              <MenuItem icon={<Trash2 size={14} />} label="Delete forever" onClick={() => onDeleteForever?.(note.id)} />
            </>
          ) : (
            <>
              <MenuItem icon={<Pin size={14} />} label={note.pinned ? 'Unpin' : 'Pin'} onClick={() => onPin(note.id)} />
              <MenuItem icon={<Archive size={14} />} label={note.archived ? 'Unarchive' : 'Archive'} onClick={() => onArchive(note.id)} />
              <MenuItem icon={<Copy size={14} />} label="Duplicate" onClick={() => onDuplicate(note.id)} />
              <MenuItem icon={<Bookmark size={14} />} label="Open" onClick={() => onOpen(note.id)} />
              <MenuItem icon={<Trash2 size={14} />} label="Move to trash" onClick={() => onTrash(note.id)} />
            </>
          )}
        </div>
      )}
      {query ? <span className="sr-only">Matches {query}</span> : null}
    </article>
  )
}

function MenuItem({
  icon,
  label,
  onClick,
}: {
  icon: ReactNode
  label: string
  onClick: () => void
}) {
  return (
    <button
      type="button"
      className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-zinc-800 hover:bg-zinc-100"
      onClick={(event) => {
        event.stopPropagation()
        onClick()
      }}
    >
      {icon}
      {label}
    </button>
  )
}

export default memo(NoteCard)
