"use client"

import { Pencil } from 'lucide-react'
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
      className="fab-press fixed z-40 flex h-16 w-16 items-center justify-center rounded-full bg-[#1a1814] text-[#f6eee4] shadow-[0_10px_24px_rgba(26,24,20,0.28)]"
      style={{
        right: 'max(1rem, env(safe-area-inset-right))',
        bottom: 'calc(5.25rem + env(safe-area-inset-bottom))',
      }}
    >
      <Pencil size={26} strokeWidth={1.8} />
    </button>
  )
}
