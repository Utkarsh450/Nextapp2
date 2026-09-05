"use client"

import { LayoutGrid, Columns2, Search } from 'lucide-react'
import IconButton from '@/components/ui/IconButton'
import type { BoardLayout } from '@/lib/theme'

export default function AppHeader({
  title,
  quiet = false,
  layout,
  showLayout = false,
  onSearch,
  onLayout,
}: {
  title: string
  quiet?: boolean
  layout: BoardLayout
  showLayout?: boolean
  onSearch: () => void
  onLayout: (layout: BoardLayout) => void
}) {
  const tools = (
    <div className="flex shrink-0 items-center rounded-full bg-white/70 p-0.5 ring-1 ring-black/5 dark:bg-white/10">
      {showLayout && (
        <IconButton
          label={layout === 'masonry' ? 'Use even grid' : 'Use masonry'}
          onClick={() => onLayout(layout === 'masonry' ? 'grid' : 'masonry')}
        >
          {layout === 'masonry' ? <LayoutGrid size={18} strokeWidth={1.8} /> : <Columns2 size={18} strokeWidth={1.8} />}
        </IconButton>
      )}
      {!quiet && (
        <IconButton label="Search notes" onClick={onSearch}>
          <Search size={18} strokeWidth={1.8} />
        </IconButton>
      )}
    </div>
  )

  return (
    <header
      className="sticky top-0 z-20 px-4"
      style={{ paddingTop: 'max(0.65rem, env(safe-area-inset-top))' }}
    >
      {quiet ? (
        <div className="flex items-center gap-2 pb-2">
          <button
            type="button"
            onClick={onSearch}
            className="flex min-h-12 min-w-0 flex-1 items-center gap-3 rounded-full bg-white/70 px-4 text-left text-sm text-[var(--muted)] ring-1 ring-black/5 dark:bg-white/10"
          >
            <Search size={18} strokeWidth={1.8} />
            Search notes
          </button>
          {showLayout ? tools : null}
        </div>
      ) : (
        <div className="flex items-center justify-between gap-3 pb-2">
          <h1 className="note-title min-w-0 truncate text-[1.55rem] font-bold tracking-[-0.04em]">{title}</h1>
          {tools}
        </div>
      )}
    </header>
  )
}
