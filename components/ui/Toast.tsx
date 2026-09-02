"use client"

export default function Toast({
  message,
  actionLabel,
  onAction,
}: {
  message: string | null
  actionLabel?: string
  onAction?: () => void
}) {
  if (!message) return null
  return (
    <div
      className={`fixed inset-x-0 z-50 flex justify-center px-4 ${onAction ? '' : 'pointer-events-none'}`}
      style={{ bottom: 'calc(5.5rem + env(safe-area-inset-bottom))' }}
    >
      <p className="flex items-center gap-3 rounded-full bg-[var(--ink)] px-4 py-2 text-sm text-[var(--paper)] shadow-[var(--shadow-card)] animate-fade-up">
        <span>{message}</span>
        {actionLabel && onAction && (
          <button
            type="button"
            className="font-semibold underline decoration-white/40 underline-offset-2"
            onClick={onAction}
          >
            {actionLabel}
          </button>
        )}
      </p>
    </div>
  )
}
