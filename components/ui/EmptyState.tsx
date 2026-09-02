"use client"

export default function EmptyState({
  glyph,
  title,
  action,
  onAction,
}: {
  glyph: string
  title: string
  action?: string
  onAction?: () => void
}) {
  return (
    <div className="flex min-h-[52vh] flex-col items-center justify-center px-6 text-center animate-fade-up">
      <p className="text-6xl" aria-hidden="true">{glyph}</p>
      <p className="mt-4 max-w-xs text-base leading-relaxed text-[var(--muted)]">{title}</p>
      {action && onAction && (
        <button
          type="button"
          onClick={onAction}
          className="mt-5 min-h-12 rounded-full bg-[var(--ink)] px-5 text-sm font-semibold text-[var(--paper)]"
        >
          {action}
        </button>
      )}
    </div>
  )
}
