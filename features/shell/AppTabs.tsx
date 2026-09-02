"use client"

import { BookMarked, NotebookPen, UserRound } from 'lucide-react'
import type { ReactNode } from 'react'
import type { AppTab } from '@/lib/notes'

export default function AppTabs({
  tab,
  hidden,
  onChange,
}: {
  tab: AppTab
  hidden?: boolean
  onChange: (tab: AppTab) => void
}) {
  if (hidden) return null

  const item = (id: AppTab, label: string, icon: ReactNode) => (
    <button
      type="button"
      onClick={() => onChange(id)}
      className={`flex min-h-12 min-w-0 flex-1 flex-col items-center justify-center gap-0.5 rounded-xl text-[0.7rem] font-medium transition duration-[var(--duration)] ease-[var(--ease-out)] ${
        tab === id ? 'text-[var(--ink)]' : 'text-[var(--muted)]'
      }`}
    >
      {icon}
      {label}
    </button>
  )

  return (
    <nav
      className="app-tabs fixed inset-x-0 bottom-0 z-30 border-t border-black/5 bg-[color:color-mix(in_srgb,var(--paper)_88%,white)]/90 backdrop-blur-xl dark:border-white/10"
      style={{ paddingBottom: 'max(0.4rem, env(safe-area-inset-bottom))' }}
    >
      <div className="mx-auto flex max-w-3xl items-stretch px-2 pt-1">
        {item('notes', 'Notes', <NotebookPen size={22} strokeWidth={tab === 'notes' ? 2.4 : 1.8} />)}
        {item('notebooks', 'Notebooks', <BookMarked size={22} strokeWidth={tab === 'notebooks' ? 2.4 : 1.8} />)}
        {item('you', 'You', <UserRound size={22} strokeWidth={tab === 'you' ? 2.4 : 1.8} />)}
      </div>
    </nav>
  )
}
