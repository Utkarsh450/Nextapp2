"use client"

import { Notebook, Pencil, Plus } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { CardTape } from '@/components/ui/PaperStickers'
import { NOTE_COLORS, type Notebook as NotebookType } from '@/lib/notes'

export default function NotebooksView({
  notebooks,
  counts,
  onOpen,
  onCreate,
  onRename,
  onRecolor,
}: {
  notebooks: NotebookType[]
  counts: Record<string, number>
  onOpen: (id: string) => void
  onCreate: (name: string, color: string) => void
  onRename: (id: string, name: string) => void
  onRecolor: (id: string, color: string) => void
}) {
  const [composing, setComposing] = useState(false)
  const [name, setName] = useState('')
  const [color, setColor] = useState<string>(NOTE_COLORS[0])
  const [editing, setEditing] = useState<string | null>(null)
  const [draft, setDraft] = useState('')
  const composeRef = useRef<HTMLFormElement>(null)

  useEffect(() => {
    if (composing) composeRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }, [composing])

  const commitRename = (id: string) => {
    const next = draft.trim()
    if (next) onRename(id, next)
    setEditing(null)
  }

  const makeNotebook = () => {
    if (!name.trim()) return
    onCreate(name.trim(), color)
    setName('')
    setColor(NOTE_COLORS[0])
    setComposing(false)
  }

  return (
    <div className="px-4 pb-28">
      <div className="mb-5">
        <p className="text-[0.92rem] font-medium text-[var(--muted)]">Your library</p>
        <h2 className="mt-1 text-[1.85rem] font-bold leading-[1.05] tracking-[-0.04em]">Books to fill</h2>
        <p className="mt-2 max-w-sm text-sm leading-relaxed text-[var(--ink)]/70">
          Tap a book to open it. The pencil lets you rename and recolor.
        </p>
      </div>

      {composing && (
        <form
          ref={composeRef}
          className="relative mb-4"
          onSubmit={(event) => {
            event.preventDefault()
            makeNotebook()
          }}
        >
          <CardTape className="left-7 -top-3" />
          <div
            className="relative rounded-[28px] p-5 text-[#2b261f]"
            style={{ backgroundColor: color }}
          >
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">New notebook</p>
            <input
              autoFocus
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Work, recipes, late-night ideas…"
              className="mt-2 min-h-12 w-full bg-transparent text-[1.35rem] font-bold tracking-[-0.03em] outline-none placeholder:text-[#2b261f]/35"
            />
            <div className="mt-4 flex flex-wrap gap-2">
              {NOTE_COLORS.map((item) => (
                <button
                  key={item}
                  type="button"
                  aria-label={`Cover ${item}`}
                  onClick={() => setColor(item)}
                  className="h-8 w-8 rounded-full"
                  style={{
                    backgroundColor: item,
                    boxShadow: color === item ? 'inset 0 0 0 2px #2b261f' : 'inset 0 0 0 1px rgba(43,38,31,0.12)',
                  }}
                />
              ))}
            </div>
            <div className="mt-4 flex gap-2">
              <button
                type="submit"
                className="min-h-12 flex-1 rounded-full bg-[#1a1814] text-sm font-semibold text-white"
              >
                Make notebook
              </button>
              <button
                type="button"
                className="min-h-12 rounded-full bg-white/70 px-4 text-sm font-medium"
                onClick={() => {
                  setComposing(false)
                  setName('')
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </form>
      )}

      <div className="grid grid-cols-2 gap-3">
        {notebooks.map((notebook, index) => {
          const tilt = index % 4 === 1 ? 'rotate(-1.4deg)' : index % 4 === 2 ? 'rotate(1.1deg)' : undefined
          const total = counts[notebook.id] ?? 0
          const isEditing = editing === notebook.id

          return (
            <article
              key={notebook.id}
              className="relative flex min-h-[11.2rem] flex-col rounded-[26px] p-4 text-[#2b261f]"
              style={{ backgroundColor: notebook.color, transform: tilt }}
            >
              {isEditing ? (
                <div className="flex flex-1 flex-col">
                  <Notebook size={18} strokeWidth={1.8} />
                  <input
                    autoFocus
                    value={draft}
                    onChange={(event) => setDraft(event.target.value)}
                    onKeyDown={(event) => {
                      if (event.key === 'Enter') {
                        event.preventDefault()
                        commitRename(notebook.id)
                      }
                      if (event.key === 'Escape') setEditing(null)
                    }}
                    className="mt-5 w-full bg-transparent text-[1.05rem] font-bold tracking-[-0.03em] outline-none"
                  />
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {NOTE_COLORS.map((item) => (
                      <button
                        key={item}
                        type="button"
                        aria-label={`Color ${item}`}
                        onClick={() => onRecolor(notebook.id, item)}
                        className="h-5 w-5 rounded-full"
                        style={{
                          backgroundColor: item,
                          boxShadow: notebook.color === item ? 'inset 0 0 0 2px #2b261f' : 'inset 0 0 0 1px rgba(43,38,31,0.15)',
                        }}
                      />
                    ))}
                  </div>
                  <button
                    type="button"
                    className="mt-auto pt-3 text-left text-sm font-semibold"
                    onClick={() => commitRename(notebook.id)}
                  >
                    Save →
                  </button>
                </div>
              ) : (
                <>
                  <button type="button" className="flex flex-1 flex-col text-left" onClick={() => onOpen(notebook.id)}>
                    <Notebook size={18} strokeWidth={1.8} />
                    <h2 className="mt-5 text-[1.05rem] font-bold tracking-[-0.03em]">{notebook.name}</h2>
                    <p className="mt-1 text-sm text-[#2b261f]/70">
                      {total} {total === 1 ? 'note' : 'notes'}
                    </p>
                    <p className="mt-auto pt-3 text-sm font-semibold">Open →</p>
                  </button>
                  <button
                    type="button"
                    aria-label={`Rename ${notebook.name}`}
                    className="absolute right-2.5 top-2.5 grid h-9 w-9 place-items-center rounded-full bg-white/55 text-[#2b261f]"
                    onClick={() => {
                      setEditing(notebook.id)
                      setDraft(notebook.name)
                    }}
                  >
                    <Pencil size={14} strokeWidth={1.8} />
                  </button>
                </>
              )}
            </article>
          )
        })}

        <button
          type="button"
          onClick={() => setComposing(true)}
          className="flex min-h-[11.2rem] flex-col items-start rounded-[26px] border-[1.5px] border-dashed border-[var(--ink)]/25 bg-white/40 p-4 text-left text-[var(--ink)]"
        >
          <span className="grid h-9 w-9 place-items-center rounded-full bg-[#1a1814] text-white">
            <Plus size={18} strokeWidth={1.8} />
          </span>
          <p className="mt-5 text-[1.05rem] font-bold tracking-[-0.03em]">New notebook</p>
          <p className="mt-1 text-sm text-[var(--ink)]/65">A fresh cover for a new pile.</p>
          <p className="mt-auto pt-3 text-sm font-semibold">Add →</p>
        </button>
      </div>
    </div>
  )
}
