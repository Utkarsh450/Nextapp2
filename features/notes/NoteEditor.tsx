"use client"

import {
  Eye,
  ImagePlus,
  ListChecks,
  Mic,
  Paperclip,
  Pencil,
  X,
} from 'lucide-react'
import { useRef, useState } from 'react'
import {
  NOTE_COLORS,
  LABEL_PRESETS,
  compressImageFile,
  insertChecklist,
  insertImageMarkdown,
  labelTint,
  toggleTaskLine,
  wordCount,
  type Note,
  type Notebook,
} from '@/lib/notes'
import MarkdownPreview from './MarkdownPreview'

const SpeechCtor = () => {
  if (typeof window === 'undefined') return null
  const speech = window as Window & {
    SpeechRecognition?: new () => SpeechRecognition
    webkitSpeechRecognition?: new () => SpeechRecognition
  }
  return speech.SpeechRecognition || speech.webkitSpeechRecognition || null
}

type SpeechRecognition = {
  lang: string
  interimResults: boolean
  continuous: boolean
  onresult: ((event: { results: ArrayLike<{ 0: { transcript: string } }> }) => void) | null
  onend: (() => void) | null
  start: () => void
  stop: () => void
}

export default function NoteEditor({
  note,
  notebooks,
  onChange,
  onClose,
  onSaveTemplate,
}: {
  note: Note
  notebooks: Notebook[]
  onChange: (note: Note) => void
  onClose: () => void
  onSaveTemplate: (note: Note) => void
}) {
  const [preview, setPreview] = useState(false)
  const [listening, setListening] = useState(false)
  const [labelDraft, setLabelDraft] = useState('')
  const [noteId, setNoteId] = useState(note.id)
  const imageRef = useRef<HTMLInputElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const count = wordCount(`${note.title} ${note.body}`)

  if (note.id !== noteId) {
    setNoteId(note.id)
    setLabelDraft('')
  }

  const patch = (partial: Partial<Note>) => {
    onChange({ ...note, ...partial, preview: partial.preview ?? note.preview ?? partial.body?.slice(0, 80) ?? note.body.slice(0, 80) })
  }

  const listen = () => {
    const Ctor = SpeechCtor()
    if (!Ctor) return
    const rec = new Ctor()
    rec.lang = 'en-US'
    rec.interimResults = false
    rec.continuous = false
    rec.onresult = (event) => {
      const spoken = event.results[0]?.[0]?.transcript
      if (spoken) patch({ body: note.body ? `${note.body} ${spoken}` : spoken })
    }
    rec.onend = () => setListening(false)
    setListening(true)
    rec.start()
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
          <div className="sm:col-span-2">
            <p className="mb-1 text-[0.7rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">Due date · reminder</p>
            <input
              type="date"
              value={note.dueAt ?? ''}
              onChange={(event) => patch({ dueAt: event.target.value || null, remindAt: event.target.value || note.remindAt })}
              className="min-h-11 w-full rounded-2xl bg-white/60 px-3 py-2.5 text-sm outline-none dark:bg-white/5"
            />
          </div>
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
          <button type="button" onClick={() => setPreview((value) => !value)} className="chip">
            {preview ? <Pencil size={14} /> : <Eye size={14} />}
            {preview ? 'Edit' : 'Preview'}
          </button>
          <button type="button" onClick={() => onSaveTemplate(note)} className="chip">
            Save as template
          </button>
        </div>

        {preview ? (
          <MarkdownPreview
            body={note.body}
            onToggleTask={(line) => patch({ body: toggleTaskLine(note.body, line) })}
          />
        ) : (
          <textarea
            value={note.body}
            onChange={(event) => patch({ body: event.target.value })}
            placeholder="Write here. Checklists use - [ ] like this."
            className="min-h-64 w-full resize-y rounded-2xl bg-white/60 p-4 text-base leading-relaxed outline-none dark:bg-white/5"
          />
        )}

        {note.attachments.length > 0 && (
          <div className="grid grid-cols-3 gap-2">
            {note.attachments.map((file) => (
              <img key={file.id} src={file.dataUrl} alt={file.name} className="h-24 w-full rounded-2xl object-cover" />
            ))}
          </div>
        )}

        <input
          ref={imageRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={async (event) => {
            const file = event.target.files?.[0]
            if (!file) return
            const src = await compressImageFile(file)
            patch({ body: insertImageMarkdown(note.body, src, file.name) })
            event.target.value = ''
          }}
        />
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={async (event) => {
            const file = event.target.files?.[0]
            if (!file) return
            const dataUrl = await compressImageFile(file)
            patch({
              attachments: [
                ...note.attachments,
                { id: `att-${Date.now()}`, name: file.name, mime: file.type, dataUrl, createdAt: Date.now() },
              ],
            })
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
