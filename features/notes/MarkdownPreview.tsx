"use client"

import { parseMarkdown, wikiSegments, blobIdFromSrc } from '@/lib/notes'

export default function MarkdownPreview({
  body,
  blobUrls,
  onToggleTask,
  onOpenLink,
}: {
  body: string
  blobUrls?: Record<string, string>
  onToggleTask: (line: number) => void
  onOpenLink?: (title: string) => void
}) {
  const blocks = parseMarkdown(body)
  if (blocks.length === 0) {
    return <p className="text-[15px] text-[var(--muted)]">Start writing…</p>
  }

  const linked = (text: string, key: string) => (
    <span key={key}>
      {wikiSegments(text).map((part, index) =>
        part.link ? (
          <button
            key={`${key}-${index}`}
            type="button"
            className="font-medium underline decoration-[var(--ink)]/30 underline-offset-2"
            onClick={() => onOpenLink?.(part.link as string)}
          >
            {part.text}
          </button>
        ) : (
          <span key={`${key}-${index}`}>{part.text}</span>
        )
      )}
    </span>
  )

  return (
    <div className="space-y-2 text-[15px] leading-relaxed">
      {blocks.map((block, index) => {
        if (block.type === 'heading') {
          const Tag = (`h${block.level}` as 'h1' | 'h2' | 'h3')
          return (
            <Tag key={index} className="font-semibold tracking-tight">
              {linked(block.text, `h-${index}`)}
            </Tag>
          )
        }
        if (block.type === 'task') {
          return (
            <label key={index} className="flex items-start gap-2">
              <input
                type="checkbox"
                checked={block.checked}
                onChange={() => onToggleTask(block.line)}
              />
              <span className={block.checked ? 'text-[var(--muted)] line-through' : ''}>
                {linked(block.text, `t-${index}`)}
              </span>
            </label>
          )
        }
        if (block.type === 'list') {
          return (
            <p key={index} className="pl-3">
              • {linked(block.text, `l-${index}`)}
            </p>
          )
        }
        if (block.type === 'image') {
          const blobId = blobIdFromSrc(block.src)
          const src = blobId ? blobUrls?.[blobId] : block.src
          if (!src) return null
          return (
            // eslint-disable-next-line @next/next/no-img-element -- note images are local blobs or data URLs
            <img
              key={index}
              src={src}
              alt={block.alt}
              className="max-h-48 rounded-2xl object-cover"
            />
          )
        }
        return <p key={index}>{linked(block.text, `p-${index}`)}</p>
      })}
    </div>
  )
}
