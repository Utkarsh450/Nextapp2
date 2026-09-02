"use client"

import type { ButtonHTMLAttributes, ReactNode } from 'react'

export default function IconButton({
  label,
  children,
  className = '',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { label: string; children: ReactNode }) {
  return (
    <button
      type="button"
      aria-label={label}
      className={`inline-flex h-11 w-11 items-center justify-center rounded-full text-[var(--ink)] transition duration-[var(--duration)] ease-[var(--ease-out)] hover:bg-black/5 active:scale-95 dark:hover:bg-white/10 ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}
