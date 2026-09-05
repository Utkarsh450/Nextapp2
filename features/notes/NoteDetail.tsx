"use client"

import { Pencil, Trash2, X } from 'lucide-react'
import { useMemo } from 'react'
import {
  backlinksTo,
  collectBlobIds,
  findNoteByTitle,
  formatDueChip,
  formatNoteTimestamp,
  isImageMime,
  labelTint,
  todayISO,
  toggleTaskLine,
  wordCount,
  type Note,
} from '@/lib/notes'
import { CardTape } from '@/components/ui/PaperStickers'
import { useAttachmentUrls } from '@/hooks/useAttachmentUrls'
import MarkdownPreview from './MarkdownPreview'

export default function NoteDetail({
  note,
  notes,
  onClose,
  onEdit,
  onDelete,
  onRestore,
  onDeleteForever,
  onChange,
  onOpenNote,
}: {
  note: Note
  notes: Note[]
  onClose: () => void
  onEdit: () => void
  onDelete: () => void
  onRestore: () => void
  onDeleteForever: () => void
  onChange: (note: Note) => void
  onOpenNote: (id: number) => void
}) {
  const blobIds = useMemo(() => collectBlobIds(note), [note])
  const blobUrls = useAttachmentUrls(note.ownerEmail, blobIds)
  const incoming = useMemo(() => backlinksTo(note, notes), [note, notes])
  const count = wordCount(`${note.title} ${note.body}`)
  const due = formatDueChip(note.dueAt, note.dueTime, todayISO())
  const stamp = formatNoteTimestamp(note.updatedAt || note.createdAt)
  const paper = note.color || '#C5CA8A'
  const trashed = Boolean(note.trashedAt)

  const openLink = (title: string) => {
    const match = findNoteByTitle(notes, title)
    if (match) onOpenNote(match.id)
  }

  return (
    <aside
      className="relative flex h-full max-h-[100dvh] w-full flex-col overflow-hidden text-[#2b261f]"
      style={{ backgroundColor: paper }}
    >
      <CardTape className="left-1/2 top-2 -translate-x-1/2" />

      <header
        className="relative z-[1] flex items-center justify-between px-3 pb-1"
        style={{ paddingTop: 'max(0.85rem, env(safe-area-inset-top))' }}
      >
        <button
          type="button"
          aria-label="Close note"
          onClick={onClose}
          className="grid h-11 w-11 place-items-center rounded-full bg-white/70"
        >
          <X size={18} strokeWidth={1.8} />
        </button>
        <p className="truncate px-2 text-sm font-medium text-[#2b261f]/70">{note.notebook || 'Inbox'}</p>
        {trashed ? (
          <button
            type="button"
            onClick={onRestore}
            className="min-h-11 rounded-full bg-[#1a1814] px-4 text-sm font-semibold text-white"
          >
            Restore
          </button>
        ) : (
          <button
            type="button"
            onClick={onEdit}
            className="inline-flex min-h-11 items-center gap-1.5 rounded-full bg-[#1a1814] px-4 text-sm font-semibold text-white"
          >
            <Pencil size={15} strokeWidth={1.8} />
            Edit
          </button>
        )}
      </header>

      <div className="relative z-[1] flex-1 overflow-y-auto px-5 pb-4 pt-3">
        <h1 className="text-[2rem] font-bold leading-[1.05] tracking-[-0.045em]">
          {note.title.trim() || 'Untitled'}
        </h1>
        <p className="mt-2 text-sm text-[#2b261f]/55">{stamp}</p>

        {(due || note.labels.length > 0 || note.tag) && (
          <div className="mt-4 flex flex-wrap gap-2">
            {due && <span className="chip bg-white/70">{due}</span>}
            {note.tag ? <span className="chip bg-white/70">{note.tag}</span> : null}
            {note.labels.map((item) => (
              <span
                key={item}
                className="chip"
                style={{ backgroundColor: `${labelTint(item)}99` }}
              >
                {item}
              </span>
            ))}
          </div>
        )}

        <div className="mt-6 min-h-40 text-[1.08rem] leading-[1.7]">
          {note.body.trim() ? (
            <MarkdownPreview
              body={note.body}
              blobUrls={blobUrls}
              onToggleTask={(line) => onChange({ ...note, body: toggleTaskLine(note.body, line) })}
              onOpenLink={openLink}
            />
          ) : (
            <p className="text-[#2b261f]/45">This note is still empty.</p>
          )}
        </div>

        {note.attachments.length > 0 && (
          <div className="mt-5 grid grid-cols-3 gap-2">
            {note.attachments.map((file) => {
              const src = blobUrls[file.id] || file.dataUrl
              return (
                <div key={file.id} className="overflow-hidden rounded-[22px] bg-white/65">
                  {src && isImageMime(file.mime) ? (
                    // eslint-disable-next-line @next/next/no-img-element -- local blob previews
                    <img src={src} alt={file.name} className="h-24 w-full object-cover" />
                  ) : (
                    <p className="flex h-24 items-center px-2 text-xs">{file.name}</p>
                  )}
                </div>
              )
            })}
          </div>
        )}

        {incoming.length > 0 && (
          <div className="mt-6">
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Linked from</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {incoming.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className="chip bg-white/70"
                  onClick={() => onOpenNote(item.id)}
                >
                  {item.title || 'Untitled'}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      <div
        className="relative z-[1] px-4 pt-2"
        style={{ paddingBottom: 'max(0.85rem, env(safe-area-inset-bottom))' }}
      >
        <div className="flex items-center gap-2">
          {trashed ? (
            <button
              type="button"
              onClick={onDeleteForever}
              className="flex min-h-12 flex-1 items-center justify-center gap-2 rounded-full bg-white/70 text-sm font-semibold text-[#7a2418]"
            >
              <Trash2 size={16} strokeWidth={1.8} />
              Delete forever
            </button>
          ) : (
            <button
              type="button"
              onClick={onDelete}
              className="flex min-h-12 flex-1 items-center justify-center gap-2 rounded-full bg-white/70 text-sm font-semibold text-[#7a2418]"
            >
              <Trash2 size={16} strokeWidth={1.8} />
              Delete
            </button>
          )}
          <p className="shrink-0 px-2 text-[0.78rem] text-[#2b261f]/55">{count} words</p>
        </div>
      </div>
    </aside>
  )
}
