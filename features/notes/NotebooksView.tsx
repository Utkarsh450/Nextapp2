"use client"

import { useState } from 'react'
import EmptyState from '@/components/ui/EmptyState'
import { NOTE_COLORS, type Notebook } from '@/lib/notes'

export default function NotebooksView({
  notebooks,
  counts,
  onOpen,
  onCreate,
  onRename,
  onRecolor,
}: {
  notebooks: Notebook[]
  counts: Record<string, number>
  onOpen: (id: string) => void
  onCreate: (name: string, color: string) => void
  onRename: (id: string, name: string) => void
  onRecolor: (id: string, color: string) => void
}) {
  const [name, setName] = useState('')
  const [color, setColor] = useState<string>(NOTE_COLORS[0])
  const [editing, setEditing] = useState<string | null>(null)
  const [draft, setDraft] = useState('')

  return (
    <div className="px-4 pb-28">
      <form
        className="mb-4 rounded-[24px] bg-white/70 p-4 ring-1 ring-black/5 dark:bg-white/5"
        onSubmit={(event) => {
          event.preventDefault()
          if (!name.trim()) return
          onCreate(name.trim(), color)
          setName('')
        }}
      >
        <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">New notebook</p>
        <input
          value={name}
          onChange={(event) => setName(event.target.value)}
          placeholder="Name"
          className="mt-2 min-h-11 w-full bg-transparent text-base outline-none"
        />
        <div className="mt-2 flex flex-wrap gap-2">
          {NOTE_COLORS.map((item) => (
            <button
              key={item}
              type="button"
              aria-label={`Cover ${item}`}
              onClick={() => setColor(item)}
              className="h-7 w-7 rounded-full"
              style={{ backgroundColor: item, outline: color === item ? '2px solid var(--ink)' : undefined }}
            />
          ))}
        </div>
        <button type="submit" className="mt-3 min-h-11 rounded-full bg-[var(--ink)] px-4 text-sm font-semibold text-[var(--paper)]">
          Add folder
        </button>
      </form>

      {notebooks.length === 0 ? (
        <EmptyState glyph="📒" title="Make a notebook for work, life, or anything in between." />
      ) : (
        <div className="notes-grid">
          {notebooks.map((notebook) => (
            <article
              key={notebook.id}
              className="flex min-h-[180px] flex-col rounded-[var(--radius-card)] p-4 shadow-[var(--shadow-card)]"
              style={{ backgroundColor: notebook.color }}
            >
              <button type="button" className="flex-1 text-left" onClick={() => onOpen(notebook.id)}>
                <p className="text-[0.65rem] uppercase tracking-[0.14em] text-zinc-700/70">Notebook</p>
                {editing === notebook.id ? (
                  <input
                    autoFocus
                    value={draft}
                    onClick={(event) => event.stopPropagation()}
                    onChange={(event) => setDraft(event.target.value)}
                    onBlur={() => {
                      onRename(notebook.id, draft)
                      setEditing(null)
                    }}
                    className="mt-2 w-full bg-transparent text-xl font-semibold outline-none"
                  />
                ) : (
                  <h2 className="mt-2 text-xl font-semibold tracking-tight">{notebook.name}</h2>
                )}
                <p className="mt-auto pt-6 text-sm text-zinc-700/80">{counts[notebook.id] ?? 0} notes</p>
              </button>
              <div className="mt-3 flex items-center justify-between">
                <button
                  type="button"
                  className="text-xs font-medium text-zinc-700"
                  onClick={() => {
                    setEditing(notebook.id)
                    setDraft(notebook.name)
                  }}
                >
                  Rename
                </button>
                <div className="flex gap-1">
                  {NOTE_COLORS.slice(0, 5).map((item) => (
                    <button
                      key={item}
                      type="button"
                      aria-label={`Color ${item}`}
                      onClick={() => onRecolor(notebook.id, item)}
                      className="h-4 w-4 rounded-full"
                      style={{ backgroundColor: item }}
                    />
                  ))}
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  )
}
