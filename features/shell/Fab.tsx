"use client"

import { Plus } from 'lucide-react'
import { useRef } from 'react'

export default function Fab({
  onClick,
  onLongPress,
  hidden,
}: {
  onClick: () => void
  onLongPress?: () => void
  hidden?: boolean
}) {
  const timer = useRef<number | null>(null)
  const held = useRef(false)

  const clear = () => {
    if (timer.current) window.clearTimeout(timer.current)
    timer.current = null
  }

  if (hidden) return null

  return (
    <button
      type="button"
      aria-label="Write a note. Press and hold for quick capture."
      onClick={() => {
        if (held.current) {
          held.current = false
          return
        }
        onClick()
      }}
      onContextMenu={(event) => {
        if (!onLongPress) return
        event.preventDefault()
        clear()
        onLongPress()
      }}
      onPointerDown={() => {
        if (!onLongPress) return
        held.current = false
        timer.current = window.setTimeout(() => {
          held.current = true
          onLongPress()
        }, 480)
      }}
      onPointerUp={clear}
      onPointerCancel={clear}
      onPointerLeave={clear}
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
