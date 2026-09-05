"use client"

import { memo, useRef, useState, type ReactNode } from 'react'
import { Archive, Bookmark, Clock, Copy, Pin, RotateCcw, Trash2 } from 'lucide-react'
import {
  cardSurface,
  formatNoteTimestamp,
  highlightSegments,
  type Note,
} from '@/lib/notes'

function NoteCard({
  note,
  query,
  index = 0,
  onOpen,
  onToggleTask,
  onPin,
  onArchive,
  onDuplicate,
  onTrash,
  onRestore,
  onDeleteForever,
}: {
  note: Note
  query?: string
  index?: number
  onOpen: (id: number) => void
  onToggleTask?: (id: number, line: number) => void
  onPin: (id: number) => void
  onArchive: (id: number) => void
  onDuplicate: (id: number) => void
  onTrash: (id: number) => void
  onRestore?: (id: number) => void
  onDeleteForever?: (id: number) => void
}) {
  const [menu, setMenu] = useState(false)
  const hold = useRef<number | null>(null)
  const held = useRef(false)
  const surface = cardSurface(note.body, note.preview)
  const delay = Math.min(index, 8) * 30
  const stamp = formatNoteTimestamp(note.updatedAt || note.createdAt)
  const showTasks = surface.shownTasks.length > 0
  const showBullets = !showTasks && surface.shownBullets.length > 0

  const clearHold = () => {
    if (hold.current) window.clearTimeout(hold.current)
    hold.current = null
  }

  return (
    <article
      className="note-card note-card-enter group relative w-full cursor-pointer overflow-hidden text-[#2b261f] dark:text-[#f3eee6]"
      style={{ ['--card' as string]: note.color || '#E8C44A', animationDelay: `${delay}ms` }}
      onClick={() => {
        if (menu) {
          setMenu(false)
          return
        }
        if (held.current) {
          held.current = false
          return
        }
        onOpen(note.id)
      }}
      onContextMenu={(event) => {
        event.preventDefault()
        setMenu(true)
      }}
      onPointerDown={() => {
        held.current = false
        hold.current = window.setTimeout(() => {
          held.current = true
          setMenu(true)
        }, 480)
      }}
      onPointerUp={clearHold}
      onPointerCancel={clearHold}
      onPointerLeave={clearHold}
    >
      <div className="flex flex-col p-[1.15rem]">
        {note.title.trim() ? (
          <h2 className="text-[1.05rem] font-bold leading-snug tracking-[-0.02em]">
            {highlightSegments(note.title, query ?? '').map((part, partIndex) => (
              <span key={partIndex} className={part.match ? 'bg-white/70' : undefined}>{part.text}</span>
            ))}
          </h2>
        ) : null}
        {surface.prose && (
          <p className={`text-[0.92rem] leading-[1.55] text-[#3a322c]/90 dark:text-[#f3eee6]/80 ${note.title.trim() ? 'mt-2' : ''} ${showTasks || showBullets ? 'line-clamp-4' : 'line-clamp-8'}`}>
            {highlightSegments(surface.prose, query ?? '').map((part, partIndex) => (
              <span key={partIndex} className={part.match ? 'bg-white/70' : undefined}>{part.text}</span>
            ))}
          </p>
        )}
        {showTasks && (
          <ul className={`${note.title.trim() || surface.prose ? 'mt-3' : ''} space-y-2`}>
            {surface.shownTasks.map((task) => (
              <li key={`${task.line}-${task.text}`}>
                <button
                  type="button"
                  className="flex w-full items-start gap-2.5 text-left text-[0.92rem] leading-[1.45] text-[#3a322c] dark:text-[#f3eee6]/85"
                  onClick={(event) => {
                    event.stopPropagation()
                    onToggleTask?.(note.id, task.line)
                  }}
                >
                  <span className={`note-check ${task.checked ? 'is-done' : ''}`} aria-hidden="true" />
                  <span className={task.checked ? 'text-[#3a322c]/45 line-through' : undefined}>
                    {task.text || 'Item'}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
        {showBullets && (
          <ul className={`${note.title.trim() || surface.prose ? 'mt-3' : ''} space-y-1.5 pl-1`}>
            {surface.shownBullets.map((item, itemIndex) => (
              <li key={`${item.text}-${itemIndex}`} className="flex gap-2.5 text-[0.92rem] leading-[1.45] text-[#3a322c] dark:text-[#f3eee6]/85">
                <span className="note-bullet" aria-hidden="true" />
                <span>{item.text}</span>
              </li>
            ))}
          </ul>
        )}
        <p className="note-stamp mt-4 flex items-center gap-1.5">
          <Clock size={13} strokeWidth={1.7} />
          <span>{stamp}</span>
        </p>
      </div>
      {menu && (
        <div className="absolute right-3 top-3 z-10 min-w-40 overflow-hidden rounded-2xl bg-[#fffaf3] py-1 text-sm shadow-[0_10px_28px_rgba(48,36,24,0.14)] ring-1 ring-black/5">
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
      className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-[#2b261f] hover:bg-black/5"
      onClick={(event) => {
        event.stopPropagation()
        setMenu(false)
        onClick()
      }}
    >
      {icon}
      {label}
    </button>
  )
}

export default memo(NoteCard)
