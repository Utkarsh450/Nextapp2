"use client"

import {
  ChevronDown,
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
import { useMemo, useRef, useState, type ReactNode } from 'react'
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
  formatDueChip,
  todayISO,
  type Note,
  type Notebook,
} from '@/lib/notes'
import { appendSpoken, speechAvailable, startDictation } from '@/lib/native/speech'
import { useAttachmentUrls } from '@/hooks/useAttachmentUrls'
import { calendarAlertsAvailable } from '@/lib/native/notifications'
import { CardTape } from '@/components/ui/PaperStickers'
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
  const [detailsOpen, setDetailsOpen] = useState(false)
  const [noteId, setNoteId] = useState(note.id)
  const imageRef = useRef<HTMLInputElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const blobIds = useMemo(() => collectBlobIds(note), [note])
  const blobUrls = useAttachmentUrls(note.ownerEmail, blobIds)
  const count = wordCount(`${note.title} ${note.body}`)
  const incoming = useMemo(() => backlinksTo(note, notes), [note, notes])
  const others = useMemo(() => linkableNotes(notes, note.id), [note.id, notes])
  const paper = note.color || '#C5CA8A'
  const summary = [
    note.notebook,
    formatDueChip(note.dueAt, note.dueTime, todayISO()),
    note.labels.length ? `${note.labels.length} label${note.labels.length === 1 ? '' : 's'}` : null,
    note.tag || null,
  ].filter(Boolean).join(' · ')

  if (note.id !== noteId) {
    setNoteId(note.id)
    setLabelDraft('')
    setLinkOpen(false)
    setPreview(false)
    setDetailsOpen(false)
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
          aria-label="Close editor"
          onClick={onClose}
          className="grid h-11 w-11 place-items-center rounded-full bg-white/70"
        >
          <X size={18} strokeWidth={1.8} />
        </button>
        <p className="text-sm font-medium text-[#2b261f]/70">{note.notebook || 'Inbox'}</p>
        <button
          type="button"
          onClick={onClose}
          className="min-h-11 rounded-full bg-[#1a1814] px-4 text-sm font-semibold text-white"
        >
          Done
        </button>
      </header>

      <div className="relative z-[1] flex-1 overflow-y-auto px-5 pb-4 pt-3">
        <input
          value={note.title}
          onChange={(event) => patch({ title: event.target.value })}
          placeholder="Title"
          className="w-full bg-transparent text-[2rem] font-bold leading-[1.05] tracking-[-0.045em] outline-none placeholder:text-[#2b261f]/35"
        />

        <div className="mt-4 flex flex-wrap gap-2">
          {NOTE_COLORS.map((color) => (
            <button
              key={color}
              type="button"
              aria-label={`Color ${color}`}
              onClick={() => patch({ color })}
              className="h-7 w-7 rounded-full"
              style={{
                backgroundColor: color,
                boxShadow: note.color === color ? 'inset 0 0 0 2px #2b261f, 0 0 0 2px rgba(255,255,255,0.9)' : 'inset 0 0 0 1px rgba(43,38,31,0.12)',
              }}
            />
          ))}
        </div>

        <div className="mt-4 flex flex-wrap gap-2">
          <ToolChip onClick={() => patch({ body: insertChecklist(note.body) })}>
            <ListChecks size={15} strokeWidth={1.8} /> Checklist
          </ToolChip>
          <ToolChip onClick={() => imageRef.current?.click()}>
            <ImagePlus size={15} strokeWidth={1.8} /> Image
          </ToolChip>
          <ToolChip onClick={() => fileRef.current?.click()}>
            <Paperclip size={15} strokeWidth={1.8} /> Attach
          </ToolChip>
          <ToolChip active={listening} onClick={listen}>
            <Mic size={15} strokeWidth={1.8} /> {listening ? 'Listening…' : 'Voice'}
          </ToolChip>
          <ToolChip
            active={linkOpen}
            onClick={() => setLinkOpen((value) => !value)}
          >
            <Link2 size={15} strokeWidth={1.8} /> Link
          </ToolChip>
          <ToolChip active={preview} onClick={() => setPreview((value) => !value)}>
            {preview ? <Pencil size={15} strokeWidth={1.8} /> : <Eye size={15} strokeWidth={1.8} />}
            {preview ? 'Edit' : 'Preview'}
          </ToolChip>
          <ToolChip onClick={() => onSaveTemplate(note)}>Template</ToolChip>
          <ToolChip onClick={onExport}>
            <Download size={15} strokeWidth={1.8} /> Export
          </ToolChip>
        </div>

        {linkOpen && (
          <div className="mt-3 rounded-[24px] bg-white/65 p-3">
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Link another note</p>
            <div className="mt-2 flex max-h-40 flex-col gap-1 overflow-y-auto">
              {others.length === 0 && (
                <p className="text-sm text-[#2b261f]/60">Give another note a title, then link it here.</p>
              )}
              {others.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className="rounded-2xl px-3 py-2.5 text-left text-sm font-medium"
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
          <div className="mt-5 min-h-72 text-[#2b261f]">
            <MarkdownPreview
              body={note.body}
              blobUrls={blobUrls}
              onToggleTask={(line) => patch({ body: toggleTaskLine(note.body, line) })}
              onOpenLink={openLink}
            />
          </div>
        ) : (
          <textarea
            value={note.body}
            onChange={(event) => patch({ body: event.target.value })}
            placeholder="Write here. Checklists use - [ ]. Link notes with [[Title]]."
            className="mt-5 min-h-72 w-full resize-y bg-transparent text-[1.08rem] leading-[1.7] outline-none placeholder:text-[#2b261f]/40"
          />
        )}

        {note.attachments.length > 0 && (
          <div className="mt-4 grid grid-cols-3 gap-2">
            {note.attachments.map((file) => {
              const src = blobUrls[file.id] || file.dataUrl
              return (
                <button
                  key={file.id}
                  type="button"
                  className="relative overflow-hidden rounded-[22px] bg-white/65 text-left"
                  onClick={() => onRemoveAttachment(file.id)}
                >
                  {src && isImageMime(file.mime) ? (
                    // eslint-disable-next-line @next/next/no-img-element -- local blob previews
                    <img src={src} alt={file.name} className="h-24 w-full object-cover" />
                  ) : (
                    <span className="flex h-24 items-center px-2 text-xs">{file.name}</span>
                  )}
                  <span className="absolute right-1.5 top-1.5 grid h-6 w-6 place-items-center rounded-full bg-white/90">
                    <X size={12} />
                  </span>
                </button>
              )
            })}
          </div>
        )}

        {incoming.length > 0 && (
          <div className="mt-4">
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Linked from</p>
            <div className="mt-2 flex flex-wrap gap-2">
              {incoming.map((item) => (
                <button key={item.id} type="button" className="chip bg-white/70" onClick={() => onOpenNote(item.id)}>
                  {item.title || 'Untitled'}
                </button>
              ))}
            </div>
          </div>
        )}

        <button
          type="button"
          className="mt-5 flex min-h-12 w-full items-center justify-between rounded-full bg-white/60 px-4 text-left text-sm"
          onClick={() => setDetailsOpen((value) => !value)}
        >
          <span className="min-w-0 truncate text-[#2b261f]/75">{summary || 'Notebook, due date, labels'}</span>
          <ChevronDown size={16} className={`shrink-0 transition-transform ${detailsOpen ? 'rotate-180' : ''}`} />
        </button>

        {detailsOpen && (
          <div className="mt-3 space-y-4 rounded-[28px] bg-white/65 p-4">
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
              <label className="block">
                <span className="text-[0.78rem] font-medium text-[#2b261f]/60">Tag</span>
                <input
                  value={note.tag}
                  onChange={(event) => patch({ tag: event.target.value })}
                  placeholder="Work, home…"
                  className="mt-1.5 min-h-12 w-full rounded-full bg-white/80 px-4 text-sm outline-none"
                />
              </label>
              <label className="block">
                <span className="text-[0.78rem] font-medium text-[#2b261f]/60">Notebook</span>
                <select
                  value={note.notebookId}
                  onChange={(event) => {
                    const notebook = notebooks.find((item) => item.id === event.target.value)
                    patch({ notebookId: event.target.value, notebook: notebook?.name ?? 'Inbox' })
                  }}
                  className="mt-1.5 min-h-12 w-full rounded-full bg-white/80 px-4 text-sm outline-none"
                >
                  {notebooks.map((item) => (
                    <option key={item.id} value={item.id}>{item.name}</option>
                  ))}
                </select>
              </label>
              <ReminderFields
                dueAt={note.dueAt}
                dueTime={note.dueTime}
                alertMinutes={note.alertMinutes}
                native={calendarAlertsAvailable()}
                onChange={(next) => patch(next)}
              />
            </div>
            <div>
              <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Labels</p>
              <div className="mt-2 flex flex-wrap gap-2">
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
                className="mt-2 flex gap-2"
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
                  className="min-h-11 flex-1 rounded-full bg-white/80 px-4 text-sm outline-none"
                />
                <button type="submit" className="chip bg-white/80">Add</button>
              </form>
              <div className="mt-2 flex flex-wrap gap-2">
                {LABEL_PRESETS.filter((item) => !note.labels.includes(item)).map((item) => (
                  <button
                    key={item}
                    type="button"
                    className="chip bg-white/70"
                    onClick={() => patch({ labels: [...note.labels, item] })}
                  >
                    {item}
                  </button>
                ))}
              </div>
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
        className="relative z-[1] flex items-center justify-between px-5 text-[0.78rem] text-[#2b261f]/60"
        style={{ paddingBottom: 'max(0.85rem, env(safe-area-inset-bottom))' }}
      >
        <span>{count} words</span>
        <span>{note.notebook}</span>
      </div>
    </aside>
  )
}

function ToolChip({
  children,
  onClick,
  active,
}: {
  children: ReactNode
  onClick: () => void
  active?: boolean
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex min-h-10 items-center gap-1.5 rounded-full px-3.5 text-[0.8rem] font-medium ${
        active ? 'bg-[#1a1814] text-white' : 'bg-white/65 text-[#2b261f]'
      }`}
    >
      {children}
    </button>
  )
}
