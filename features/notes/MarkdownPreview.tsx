"use client"

import { parseMarkdown } from '@/lib/notes'

export default function MarkdownPreview({
  body,
  onToggleTask,
}: {
  body: string
  onToggleTask: (line: number) => void
}) {
  const blocks = parseMarkdown(body)
  if (blocks.length === 0) {
    return <p className="text-[15px] text-[var(--muted)]">Start writing…</p>
  }

  return (
    <div className="space-y-2 text-[15px] leading-relaxed">
      {blocks.map((block, index) => {
        if (block.type === 'heading') {
          const Tag = (`h${block.level}` as 'h1' | 'h2' | 'h3')
          return (
            <Tag key={index} className="font-semibold tracking-tight">
              {block.text}
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
                {block.text}
              </span>
            </label>
          )
        }
        if (block.type === 'list') {
          return (
            <p key={index} className="pl-3">
              • {block.text}
            </p>
          )
        }
        if (block.type === 'image') {
          return (
            // eslint-disable-next-line @next/next/no-img-element -- note images are local data URLs
            <img
              key={index}
              src={block.src}
              alt={block.alt}
              className="max-h-48 rounded-2xl object-cover"
            />
          )
        }
        return <p key={index}>{block.text}</p>
      })}
    </div>
  )
}
