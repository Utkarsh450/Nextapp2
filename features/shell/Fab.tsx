"use client"

import { Plus } from 'lucide-react'

export default function Fab({ onClick, hidden }: { onClick: () => void; hidden?: boolean }) {
  if (hidden) return null
  return (
    <button
      type="button"
      aria-label="Write a note"
      onClick={onClick}
      className="fab-press fixed z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[var(--ink)] text-[var(--paper)] shadow-[0_12px_28px_rgba(18,18,20,0.28)]"
      style={{
        right: 'max(1rem, env(safe-area-inset-right))',
        bottom: 'calc(5.25rem + env(safe-area-inset-bottom))',
      }}
    >
      <Plus size={28} strokeWidth={2.2} />
    </button>
  )
}
