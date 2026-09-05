"use client"

import type { ReactNode } from 'react'
import { AuthStickers, OnboardStickers } from '@/components/ui/PaperStickers'

export default function PaperStage({
  children,
  className = '',
  scene = 'none',
}: {
  children: ReactNode
  className?: string
  scene?: 'none' | 'auth' | 'onboard'
}) {
  return (
    <div className={`relative flex min-h-dvh flex-col overflow-hidden bg-[var(--paper)] ${className}`}>
      {scene === 'auth' && <AuthStickers />}
      {scene === 'onboard' && <OnboardStickers />}
      <div className="relative z-[1] flex min-h-dvh flex-1 flex-col">{children}</div>
    </div>
  )
}
