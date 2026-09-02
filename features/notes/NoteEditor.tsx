"use client"

import {
  Download,
  Eye,
  ImagePlus,
  Link2,
  ListChecks,
  Mic,
  Paperclip,
  Pencil,
  X,
} from 'lucide-react'
import { useMemo, useRef, useState } from 'react'
import {
  NOTE_COLORS,
  LABEL_PRESETS,
  backlinksTo,
  collectBlobIds,
  findNoteByTitle,
  insertChecklist,
  insertWikiLink,
  isImageMime,
  labelTint,
  linkableNotes,
  toggleTaskLine,
  wordCount,
  type Note,
  type Notebook,
} from '@/lib/notes'
import { appendSpoken, speechAvailable, startDictation } from '@/lib/native/speech'
import { useAttachmentUrls } from '@/hooks/useAttachmentUrls'
import { calendarAlertsAvailable } from '@/lib/native/notifications'
import MarkdownPreview from './MarkdownPreview'
import ReminderFields from './ReminderFields'

export default function NoteEditor({
  note,
  notes,
  notebooks,
  onChange,
  onClose,
  onSaveTemplate,
  onAddFiles,
  onRemoveAttachment,
  onOpenNote,
  onCreateLinked,
  onExport,
  onVoiceMissing,
}: {
  note: Note
  notes: Note[]
  notebooks: Notebook[]
  onChange: (note: Note) => void
  onClose: () => void
  onSaveTemplate: (note: Note) => void
  onAddFiles: (files: File[], intoBody: boolean) => void
  onRemoveAttachment: (id: string) => void
  onOpenNote: (id: number) => void
  onCreateLinked: (title: string) => void
  onExport: () => void
  onVoiceMissing: () => void
}) {
  const [preview, setPreview] = useState(false)
  const [listening, setListening] = useState(false)
  const [labelDraft, setLabelDraft] = useState('')
  const [linkOpen, setLinkOpen] = useState(false)
  const [noteId, setNoteId] = useState(note.id)
  const imageRef = useRef<HTMLInputElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const blobIds = useMemo(() => collectBlobIds(note), [note])
  const blobUrls = useAttachmentUrls(note.ownerEmail, blobIds)
  const count = wordCount(`${note.title} ${note.body}`)
  const incoming = useMemo(() => backlinksTo(note, notes), [note, notes])
  const others = useMemo(() => linkableNotes(notes, note.id), [note.id, notes])

  if (note.id !== noteId) {
    setNoteId(note.id)
    setLabelDraft('')
    setLinkOpen(false)
    setPreview(false)
  }

  const patch = (partial: Partial<Note>) => {
    onChange({ ...note, ...partial, preview: partial.preview ?? note.preview ?? partial.body?.slice(0, 80) ?? note.body.slice(0, 80) })
  }

  const listen = () => {
    if (listening) return
    if (!speechAvailable()) {
      onVoiceMissing()
      return
    }
    setListening(true)
    startDictation({
      onText: (spoken) => patch({ body: appendSpoken(note.body, spoken) }),
      onEnd: () => setListening(false),
      onError: onVoiceMissing,
    })
  }

  const openLink = (title: string) => {
    const match = findNoteByTitle(notes, title)
    if (match) onOpenNote(match.id)
    else onCreateLinked(title)
  }

  return (
    <aside className="flex h-full max-h-[100dvh] w-full flex-col bg-[var(--paper)]">
      <div
        className="flex items-center justify-between px-4 py-3"
        style={{ paddingTop: 'max(0.75rem, env(safe-area-inset-top))' }}
      >
        <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Note</p>
        <button type="button" aria-label="Close editor" onClick={onClose} className="rounded-full p-2 text-[var(--muted)]">
          <X size={18} />
        </button>
      </div>

      <div className="flex-1 space-y-3 overflow-y-auto px-4 py-2">
        <input
          value={note.title}
          onChange={(event) => patch({ title: event.target.value })}
          placeholder="Title"
          className="w-full bg-transparent text-[1.65rem] font-semibold tracking-tight outline-none"
        />
        <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
          <input
            value={note.tag}
            onChange={(event) => patch({ tag: event.target.value })}
            placeholder="Tag"
            className="rounded-2xl bg-white/60 px-3 py-2.5 text-sm outline-none dark:bg-white/5"
          />
          <select
            value={note.notebookId}
            onChange={(event) => {
              const notebook = notebooks.find((item) => item.id === event.target.value)
              patch({ notebookId: event.target.value, notebook: notebook?.name ?? 'Inbox' })
            }}
            className="rounded-2xl bg-white/60 px-3 py-2.5 text-sm outline-none dark:bg-white/5"
          >
            {notebooks.map((item) => (
              <option key={item.id} value={item.id}>{item.name}</option>
            ))}
          </select>
          <ReminderFields
            dueAt={note.dueAt}
            dueTime={note.dueTime}
            alertMinutes={note.alertMinutes}
            native={calendarAlertsAvailable()}
            onChange={(next) => patch(next)}
          />
        </div>
        <div className="space-y-2">
          <p className="text-[0.7rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">Labels</p>
          <div className="flex flex-wrap gap-2">
            {note.labels.map((item) => (
              <button
                key={item}
                type="button"
                className="chip"
                style={{ backgroundColor: `${labelTint(item)}99` }}
                onClick={() => patch({ labels: note.labels.filter((label) => label !== item) })}
              >
                {item} ×
              </button>
            ))}
          </div>
          <form
            className="flex gap-2"
            onSubmit={(event) => {
              event.preventDefault()
              const next = labelDraft.trim()
              if (!next || note.labels.includes(next)) return
              patch({ labels: [...note.labels, next] })
              setLabelDraft('')
            }}
          >
            <input
              value={labelDraft}
              onChange={(event) => setLabelDraft(event.target.value)}
              placeholder="Add a label"
              className="min-h-11 flex-1 rounded-2xl bg-white/60 px-3 text-sm outline-none dark:bg-white/5"
            />
            <button type="submit" className="chip">Add</button>
          </form>
          <div className="flex flex-wrap gap-2">
            {LABEL_PRESETS.filter((item) => !note.labels.includes(item)).map((item) => (
              <button
                key={item}
                type="button"
                className="chip"
                onClick={() => patch({ labels: [...note.labels, item] })}
              >
                {item}
              </button>
            ))}
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          {NOTE_COLORS.map((color) => (
            <button
              key={color}
              type="button"
              aria-label={`Color ${color}`}
              onClick={() => patch({ color })}
              className="h-7 w-7 rounded-full ring-1 ring-black/5"
              style={{ backgroundColor: color, outline: note.color === color ? '2px solid var(--ink)' : undefined }}
            />
          ))}
        </div>

        <div className="flex flex-wrap gap-2">
          <button type="button" onClick={() => patch({ body: insertChecklist(note.body) })} className="chip">
            <ListChecks size={14} /> Checklist
          </button>
          <button type="button" onClick={() => imageRef.current?.click()} className="chip">
            <ImagePlus size={14} /> Image
          </button>
          <button type="button" onClick={() => fileRef.current?.click()} className="chip">
            <Paperclip size={14} /> Attach
          </button>
          <button type="button" onClick={listen} className="chip">
            <Mic size={14} /> {listening ? 'Listening…' : 'Voice'}
          </button>
          <button type="button" onClick={() => setLinkOpen((value) => !value)} className="chip">
            <Link2 size={14} /> Link note
          </button>
          <button type="button" onClick={() => setPreview((value) => !value)} className="chip">
            {preview ? <Pencil size={14} /> : <Eye size={14} />}
            {preview ? 'Edit' : 'Preview'}
          </button>
          <button type="button" onClick={() => onSaveTemplate(note)} className="chip">
            Save as template
          </button>
          <button type="button" onClick={onExport} className="chip">
            <Download size={14} /> Export
          </button>
        </div>

        {linkOpen && (
          <div className="rounded-2xl bg-white/60 p-3 dark:bg-white/5">
            <p className="text-[0.7rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">Insert [[link]]</p>
            <div className="mt-2 flex max-h-40 flex-col gap-1 overflow-y-auto">
              {others.length === 0 && (
                <p className="text-sm text-[var(--muted)]">Give another note a title, then link it here.</p>
              )}
              {others.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className="rounded-xl px-2 py-2 text-left text-sm"
                  onClick={() => {
                    patch({ body: insertWikiLink(note.body, item.title) })
                    setLinkOpen(false)
                  }}
                >
                  {item.title}
                </button>
              ))}
            </div>
          </div>
        )}

        {preview ? (
          <MarkdownPreview
            body={note.body}
            blobUrls={blobUrls}
            onToggleTask={(line) => patch({ body: toggleTaskLine(note.body, line) })}
            onOpenLink={openLink}
          />
        ) : (
          <textarea
            value={note.body}
            onChange={(event) => patch({ body: event.target.value })}
            placeholder="Write here. Checklists use - [ ]. Link notes with [[Title]]."
            className="min-h-64 w-full resize-y rounded-2xl bg-white/60 p-4 text-base leading-relaxed outline-none dark:bg-white/5"
          />
        )}

        {note.attachments.length > 0 && (
          <div className="grid grid-cols-3 gap-2">
            {note.attachments.map((file) => {
              const src = blobUrls[file.id] || file.dataUrl
              return (
                <button
                  key={file.id}
                  type="button"
                  className="relative overflow-hidden rounded-2xl bg-white/60 text-left dark:bg-white/5"
                  onClick={() => onRemoveAttachment(file.id)}
                >
                  {src && isImageMime(file.mime) ? (
                    // eslint-disable-next-line @next/next/no-img-element -- local blob previews
                    <img src={src} alt={file.name} className="h-24 w-full object-cover" />
                  ) : (
                    <span className="flex h-24 items-center px-2 text-xs">{file.name}</span>
                  )}
                  <span className="absolute right-1 top-1 rounded-full bg-white/80 px-1.5 text-[0.65rem]">×</span>
                </button>
              )
            })}
          </div>
        )}

        {(incoming.length > 0) && (
          <div>
            <p className="text-[0.7rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">Linked from</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {incoming.map((item) => (
                <button key={item.id} type="button" className="chip" onClick={() => onOpenNote(item.id)}>
                  {item.title || 'Untitled'}
                </button>
              ))}
            </div>
          </div>
        )}

        <input
          ref={imageRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(event) => {
            const files = [...(event.target.files ?? [])]
            if (files.length) onAddFiles(files, true)
            event.target.value = ''
          }}
        />
        <input
          ref={fileRef}
          type="file"
          accept="image/*,.pdf,.txt,.md,application/pdf,text/plain"
          multiple
          className="hidden"
          onChange={(event) => {
            const files = [...(event.target.files ?? [])]
            if (files.length) onAddFiles(files, false)
            event.target.value = ''
          }}
        />
      </div>

      <div
        className="flex items-center justify-between px-4 py-3 text-[0.75rem] text-[var(--muted)]"
        style={{ paddingBottom: 'max(0.75rem, env(safe-area-inset-bottom))' }}
      >
        <span>{count} words</span>
        <span>{note.notebook}</span>
      </div>
    </aside>
  )
}
