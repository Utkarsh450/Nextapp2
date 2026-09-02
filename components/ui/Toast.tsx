"use client"

export default function Toast({ message }: { message: string | null }) {
  if (!message) return null
  return (
    <div className="pointer-events-none fixed inset-x-0 z-50 flex justify-center px-4" style={{ bottom: 'calc(5.5rem + env(safe-area-inset-bottom))' }}>
      <p className="rounded-full bg-[var(--ink)] px-4 py-2 text-sm text-[var(--paper)] shadow-[var(--shadow-card)] animate-fade-up">
        {message}
      </p>
    </div>
  )
}
