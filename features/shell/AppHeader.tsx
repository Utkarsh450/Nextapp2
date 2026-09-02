"use client"

import { CalendarDays, Moon, Search, Sun } from 'lucide-react'
import IconButton from '@/components/ui/IconButton'

export default function AppHeader({
  title,
  dark,
  onSearch,
  onDaily,
  onToggleTheme,
}: {
  title: string
  dark: boolean
  onSearch: () => void
  onDaily: () => void
  onToggleTheme: () => void
}) {
  return (
    <header
      className="sticky top-0 z-20 flex items-center justify-between gap-3 bg-[color:color-mix(in_srgb,var(--paper)_86%,transparent)] px-4 pb-3 backdrop-blur-md"
      style={{ paddingTop: 'max(0.85rem, env(safe-area-inset-top))' }}
    >
      <div>
        <p className="text-[0.65rem] font-medium uppercase tracking-[0.18em] text-[var(--muted)]">Notes</p>
        <h1 className="text-[1.65rem] font-semibold leading-tight tracking-tight">{title}</h1>
      </div>
      <div className="flex items-center">
        <IconButton label="Search notes" onClick={onSearch}>
          <Search size={20} />
        </IconButton>
        <IconButton label="Open daily note" onClick={onDaily}>
          <CalendarDays size={20} />
        </IconButton>
        <IconButton label={dark ? 'Use light mode' : 'Use dark mode'} onClick={onToggleTheme}>
          {dark ? <Sun size={20} /> : <Moon size={20} />}
        </IconButton>
      </div>
    </header>
  )
}
