"use client"

import { Check } from 'lucide-react'
import { useRef, useState } from 'react'
import { tickHaptic } from '@/lib/native/haptics'

export default function PaytmTick({
  active,
  onToggle,
}: {
  active: boolean
  onToggle: () => void
}) {
  const [playing, setPlaying] = useState(false)
  const timer = useRef<number>(0)

  return (
    <button
      type="button"
      aria-label={active ? 'Mark as open' : 'Mark as done'}
      onClick={(event) => {
        event.stopPropagation()
        onToggle()
        if (!active) {
          tickHaptic()
          setPlaying(true)
          window.clearTimeout(timer.current)
          timer.current = window.setTimeout(() => setPlaying(false), 1200)
        } else {
          setPlaying(false)
        }
      }}
      className="relative mb-1 flex h-[22px] w-[22px] shrink-0 cursor-pointer items-center justify-center overflow-visible rounded-full"
    >
      {!active ? (
        <span className="flex h-full w-full items-center justify-center rounded-full border border-zinc-300/80 bg-white/70">
          <Check size={12} color="grey" />
        </span>
      ) : (
        <span className="relative flex h-full w-full items-center justify-center">
          {playing && (
            <>
              <span className="paytm-success-ripple absolute inset-0 rounded-full bg-[var(--accent)]" />
              <span className="paytm-success-ripple paytm-success-ripple-delay absolute inset-0 rounded-full bg-[var(--accent)]" />
            </>
          )}
          <span
            className={`relative z-10 flex h-full w-full items-center justify-center rounded-full bg-[var(--accent)] shadow-[0_4px_12px_rgba(0,178,89,0.45)] ${playing ? 'paytm-success-circle' : ''}`}
          >
            <svg viewBox="0 0 52 52" className="h-3.5 w-3.5" fill="none" aria-hidden="true">
              <path
                className={playing ? 'paytm-success-check' : undefined}
                d="M14 27.5 L22.5 36 L38.5 18"
                stroke="white"
                strokeWidth="5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
        </span>
      )}
    </button>
  )
}
