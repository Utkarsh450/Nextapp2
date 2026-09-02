"use client"

import { Search, X } from 'lucide-react'
import { NOTE_COLORS, highlightSegments, labelTint, type Note } from '@/lib/notes'

export default function SearchOverlay({
  open,
  value,
  recents,
  hits,
  labels,
  activeLabel,
  activeColor,
  onChange,
  onClose,
  onSubmit,
  onPickRecent,
  onPickLabel,
  onPickColor,
  onOpen,
}: {
  open: boolean
  value: string
  recents: string[]
  hits: Note[]
  labels: string[]
  activeLabel: string | null
  activeColor: string | null
  onChange: (value: string) => void
  onClose: () => void
  onSubmit: (value: string) => void
  onPickRecent: (value: string) => void
  onPickLabel: (value: string | null) => void
  onPickColor: (value: string | null) => void
  onOpen: (id: number) => void
}) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-40 overflow-y-auto bg-[var(--paper)] animate-fade-up" style={{ paddingTop: 'max(0.75rem, env(safe-area-inset-top))' }}>
      <form
        className="flex items-center gap-2 px-4"
        onSubmit={(event) => {
          event.preventDefault()
          onSubmit(value)
        }}
      >
        <Search size={18} className="text-[var(--muted)]" />
        <input
          autoFocus
          value={value}
          onChange={(event) => onChange(event.target.value)}
          placeholder="Search notes"
          className="min-h-12 flex-1 bg-transparent text-lg outline-none"
        />
        <button type="button" aria-label="Close search" onClick={onClose} className="rounded-full p-2">
          <X size={18} />
        </button>
      </form>
      <div className="px-4 pt-4 pb-28">
        <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Colors</p>
        <div className="mt-2 flex flex-wrap gap-2">
          {NOTE_COLORS.map((color) => (
            <button
              key={color}
              type="button"
              aria-label={`Filter ${color}`}
              onClick={() => onPickColor(activeColor === color ? null : color)}
              className="h-8 w-8 rounded-full ring-1 ring-black/10"
              style={{ backgroundColor: color, outline: activeColor === color ? '2px solid var(--ink)' : undefined }}
            />
          ))}
        </div>
        {labels.length > 0 && (
          <>
            <p className="mt-5 text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Labels</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {labels.map((item) => (
                <button
                  key={item}
                  type="button"
                  onClick={() => onPickLabel(activeLabel === item ? null : item)}
                  className="chip"
                  style={{ backgroundColor: `${labelTint(item)}99`, outline: activeLabel === item ? '2px solid var(--ink)' : undefined }}
                >
                  {item}
                </button>
              ))}
            </div>
          </>
        )}
        {recents.length > 0 && (
          <>
            <p className="mt-5 text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Recent</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {recents.map((item) => (
                <button key={item} type="button" onClick={() => onPickRecent(item)} className="chip">
                  {item}
                </button>
              ))}
            </div>
          </>
        )}
        {value.trim() && (
          <div className="mt-5">
            <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Matches</p>
            {hits.slice(0, 8).map((note) => (
              <button
                key={note.id}
                type="button"
                className="mt-2 block w-full rounded-2xl bg-white/60 px-3 py-2 text-left text-sm dark:bg-white/5"
                onClick={() => onOpen(note.id)}
              >
                <span className="font-medium">
                  {highlightSegments(note.title || 'Untitled', value).map((part, index) => (
                    <span key={index} className={part.match ? 'bg-[#F9D368]/80' : undefined}>{part.text}</span>
                  ))}
                </span>
                {note.body && (
                  <span className="mt-1 block line-clamp-2 text-[var(--muted)]">
                    {highlightSegments(note.body.replace(/\s+/g, ' ').slice(0, 120), value).map((part, index) => (
                      <span key={index} className={part.match ? 'bg-[#F9D368]/80 text-[var(--ink)]' : undefined}>{part.text}</span>
                    ))}
                  </span>
                )}
              </button>
            ))}
            {hits.length === 0 && (
              <p className="mt-3 text-sm text-[var(--muted)]">No notes match that search.</p>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
