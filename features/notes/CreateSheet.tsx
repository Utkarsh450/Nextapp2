"use client"

import { Mic, X } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { applyTemplate, type SavedTemplate, type TemplateKey } from '@/lib/notes'

type SpeechRecognition = {
  lang: string
  interimResults: boolean
  continuous: boolean
  onresult: ((event: { results: ArrayLike<{ 0: { transcript: string } }> }) => void) | null
  onend: (() => void) | null
  start: () => void
  stop: () => void
}

export default function CreateSheet({
  open,
  onClose,
  onCreate,
  templates,
  onUseTemplate,
}: {
  open: boolean
  onClose: () => void
  onCreate: (draft: { title: string; body: string; template?: TemplateKey }) => void
  templates: SavedTemplate[]
  onUseTemplate: (id: string) => void
}) {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [listening, setListening] = useState(false)
  const [wasOpen, setWasOpen] = useState(open)
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  if (open !== wasOpen) {
    setWasOpen(open)
    if (open) {
      setTitle('')
      setBody('')
    }
  }

  useEffect(() => {
    if (open) window.setTimeout(() => textareaRef.current?.focus(), 180)
  }, [open])

  if (!open) return null

  const save = (template?: TemplateKey) => {
    onCreate({ title, body, template })
    onClose()
  }

  const listen = () => {
    const speech = window as Window & {
      SpeechRecognition?: new () => SpeechRecognition
      webkitSpeechRecognition?: new () => SpeechRecognition
    }
    const Ctor = speech.SpeechRecognition || speech.webkitSpeechRecognition
    if (!Ctor) return
    const rec = new Ctor()
    rec.lang = 'en-US'
    rec.interimResults = false
    rec.continuous = false
    rec.onresult = (event) => {
      const spoken = event.results[0]?.[0]?.transcript
      if (spoken) setBody((current) => (current ? `${current} ${spoken}` : spoken))
    }
    rec.onend = () => setListening(false)
    setListening(true)
    rec.start()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end bg-black/25 sm:items-center sm:justify-center" onClick={onClose}>
      <form
        className="sheet-up w-full max-w-lg rounded-t-[28px] bg-[var(--paper)] p-4 shadow-[var(--shadow-card)] sm:rounded-[28px]"
        style={{ paddingBottom: 'max(1rem, env(safe-area-inset-bottom))' }}
        onClick={(event) => event.stopPropagation()}
        onSubmit={(event) => {
          event.preventDefault()
          save()
        }}
      >
        <div className="mb-3 flex items-center justify-between">
          <p className="text-[0.65rem] font-medium uppercase tracking-[0.16em] text-[var(--muted)]">Quick capture</p>
          <button type="button" aria-label="Close" onClick={onClose} className="rounded-full p-2">
            <X size={16} />
          </button>
        </div>
        <input
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Title"
          className="w-full bg-transparent text-xl font-semibold outline-none"
        />
        <textarea
          ref={textareaRef}
          value={body}
          onChange={(event) => setBody(event.target.value)}
          placeholder="What’s on your mind?"
          className="mt-2 min-h-32 w-full resize-none bg-transparent text-base leading-relaxed outline-none"
        />
        <div className="mt-3 flex flex-wrap gap-2">
          {(['meeting', 'idea', 'daily'] as TemplateKey[]).map((key) => (
            <button
              key={key}
              type="button"
              onClick={() => save(key)}
              className="chip"
            >
              {applyTemplate(key).name}
            </button>
          ))}
          {templates.map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => {
                onUseTemplate(item.id)
                onClose()
              }}
              className="chip"
            >
              {item.name}
            </button>
          ))}
          <button type="button" onClick={listen} className="chip">
            <Mic size={14} /> {listening ? 'Listening…' : 'Voice'}
          </button>
        </div>
        <button type="submit" className="mt-4 min-h-12 w-full rounded-full bg-[var(--ink)] font-semibold text-[var(--paper)]">
          Save note
        </button>
      </form>
    </div>
  )
}
