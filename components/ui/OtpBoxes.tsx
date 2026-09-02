"use client"

import { useEffect, useRef } from 'react'

export default function OtpBoxes({
  value,
  onChange,
}: {
  value: string
  onChange: (value: string) => void
}) {
  const refs = useRef<Array<HTMLInputElement | null>>([])
  const digits = Array.from({ length: 6 }, (_, index) => value[index] ?? '')

  useEffect(() => {
    refs.current[value.length]?.focus()
  }, [value.length])

  return (
    <div className="mt-4 flex justify-between gap-2">
      {digits.map((digit, index) => (
        <input
          key={index}
          ref={(node) => {
            refs.current[index] = node
          }}
          inputMode="numeric"
          autoComplete={index === 0 ? 'one-time-code' : 'off'}
          maxLength={1}
          value={digit}
          aria-label={`Digit ${index + 1}`}
          onChange={(event) => {
            const next = event.target.value.replace(/\D/g, '').slice(-1)
            const chars = value.split('')
            chars[index] = next
            onChange(chars.join('').slice(0, 6))
          }}
          onKeyDown={(event) => {
            if (event.key === 'Backspace' && !digits[index] && index > 0) {
              refs.current[index - 1]?.focus()
              onChange(value.slice(0, index - 1))
            }
          }}
          onPaste={(event) => {
            event.preventDefault()
            const pasted = event.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
            onChange(pasted)
          }}
          className="h-14 w-11 rounded-2xl bg-white/80 text-center text-xl font-semibold text-[var(--ink)] outline-none ring-1 ring-black/5 focus:ring-2 focus:ring-[var(--ink)]"
        />
      ))}
    </div>
  )
}
