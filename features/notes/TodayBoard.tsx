"use client"

import { ArrowUpRight, CalendarDays, CheckCircle2, ListChecks, Notebook } from 'lucide-react'
import { useEffect, useState, type ReactNode } from 'react'
import { CardTape, HeartSticker, SquiggleSticker, TodayStickers } from '@/components/ui/PaperStickers'
import { checklistProgress, greetingForHour, sparkPath, type NoteDashboard } from '@/lib/notes'

export default function TodayBoard({
  name,
  dash,
  onOpen,
  onDue,
  onNotebook,
  onOpenLists,
  onDone,
}: {
  name: string
  dash: NoteDashboard
  onOpen: (id: number) => void
  onDue: () => void
  onNotebook: (id: string) => void
  onOpenLists: () => void
  onDone: () => void
}) {
  const first = name.trim().split(/\s+/)[0] || 'there'
  const [hello, setHello] = useState('Hello')
  const ring = 2 * Math.PI * 46
  const offset = ring * (1 - dash.percent / 100)
  const spark = sparkPath(dash.week.map((item) => item.count))
  const tiles = dash.notebooks.slice(0, 4)

  useEffect(() => {
    setHello(greetingForHour(new Date().getHours()))
  }, [])

  return (
    <section className="relative mb-5 px-4">
      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0 pt-0.5">
          <p className="text-[0.92rem] font-medium text-[var(--muted)]">{hello}, {first}</p>
          <h2 className="relative mt-1 max-w-[12.5rem] pb-3 text-[1.85rem] font-bold leading-[1.05] tracking-[-0.04em]">
            Discover, create, enjoy
            <span className="absolute bottom-0 left-0 h-3.5 w-[7.2rem] text-[#E89569]">
              <SquiggleSticker />
            </span>
          </h2>
        </div>
        <TodayStickers />
      </div>

      <div className="relative mt-7">
        <CardTape className="left-7 -top-3" />
        <button
          type="button"
          className="relative w-full overflow-hidden rounded-[28px] bg-[#C5CA8A] p-5 text-left text-[#2b261f]"
          onClick={() => {
            if (dash.featured) onOpen(dash.featured.id)
            else onOpenLists()
          }}
        >
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0">
              <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Your progress</p>
              <p className="mt-2 text-[1.35rem] font-bold leading-tight tracking-[-0.03em]">
                {dash.tasks.total ? `${dash.tasks.done} of ${dash.tasks.total} tasks` : `${dash.done} notes done`}
              </p>
              <p className="mt-1 text-sm text-[#2b261f]/70">
                {dash.open} open · {dash.due.length} due
              </p>
              {spark && (
                <svg viewBox="0 0 88 32" className="mt-4 h-8 w-24" aria-hidden="true">
                  <path d={spark} fill="none" stroke="#2b261f" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              )}
            </div>
            <div className="relative h-[5.5rem] w-[5.5rem] shrink-0">
              <svg viewBox="0 0 120 120" className="h-full w-full -rotate-90">
                <circle cx="60" cy="60" r="46" fill="none" stroke="rgba(43,38,31,0.16)" strokeWidth="10" />
                <circle
                  cx="60"
                  cy="60"
                  r="46"
                  fill="none"
                  stroke="#2b261f"
                  strokeWidth="10"
                  strokeLinecap="round"
                  strokeDasharray={ring}
                  strokeDashoffset={offset}
                />
              </svg>
              <span className="absolute inset-0 grid place-items-center text-[1.15rem] font-bold">{dash.percent}%</span>
            </div>
          </div>
          {dash.featured && (
            <p className="mt-4 truncate text-sm font-medium text-[#2b261f]/80">
              Next up · {dash.featured.title || 'Untitled'}
              {(() => {
                const tasks = checklistProgress(dash.featured.body)
                return tasks.total ? ` · ${tasks.done}/${tasks.total}` : ''
              })()}
            </p>
          )}
        </button>
      </div>

      {dash.due.length > 0 && (
        <div className="relative mt-3 rounded-[28px] bg-[#E7A3A3] p-4 text-[#2b261f]">
          <div className="flex items-center justify-between gap-3">
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Due with you</p>
            <span className="paper-sticker h-7 w-7 shrink-0" style={{ ['--tilt' as string]: '8deg' }}>
              <HeartSticker />
            </span>
          </div>
          <ul className="mt-3 space-y-2">
            {dash.due.slice(0, 3).map((note) => (
              <li key={note.id}>
                <button
                  type="button"
                  className="flex min-h-11 w-full items-center justify-between rounded-full bg-white/70 px-3.5 text-left text-sm font-medium"
                  onClick={() => onOpen(note.id)}
                >
                  <span className="truncate">{note.title || 'Untitled'}</span>
                  <ArrowUpRight size={16} />
                </button>
              </li>
            ))}
          </ul>
          {dash.due.length > 3 && (
            <button type="button" className="mt-3 text-sm font-semibold" onClick={onDue}>
              See all due →
            </button>
          )}
        </div>
      )}

      <div className="mt-3 grid grid-cols-2 gap-3">
        {tiles.map((item, index) => (
          <button
            key={item.id}
            type="button"
            className="min-h-[7.4rem] rounded-[26px] p-4 text-left text-[#2b261f]"
            style={{ backgroundColor: item.color, transform: index === 1 ? 'rotate(-1.5deg)' : index === 2 ? 'rotate(1.2deg)' : undefined }}
            onClick={() => onNotebook(item.id)}
          >
            <Notebook size={18} strokeWidth={1.8} />
            <p className="mt-5 text-[1.05rem] font-bold tracking-[-0.03em]">{item.name}</p>
            <p className="mt-1 text-sm text-[#2b261f]/70">{item.count} notes</p>
            <p className="mt-3 text-sm font-semibold">Check →</p>
          </button>
        ))}
      </div>

      <div className="mt-3 flex gap-3 overflow-x-auto notes-scrollbar-hide">
        <MetricChip icon={<ListChecks size={16} />} label="Open lists" value={String(dash.open)} onClick={onOpenLists} tone="#BEC3BC" />
        <MetricChip icon={<CalendarDays size={16} />} label="Due today" value={String(dash.due.length)} onClick={onDue} tone="#E89569" />
        <MetricChip icon={<CheckCircle2 size={16} />} label="Finished" value={String(dash.done)} onClick={onDone} tone="#A9D4C4" />
      </div>
    </section>
  )
}

function MetricChip({
  icon,
  label,
  value,
  tone,
  onClick,
}: {
  icon: ReactNode
  label: string
  value: string
  tone: string
  onClick: () => void
}) {
  return (
    <button
      type="button"
      className="min-w-[8.5rem] rounded-[22px] px-4 py-3 text-left text-[#2b261f]"
      style={{ backgroundColor: tone }}
      onClick={onClick}
    >
      {icon}
      <p className="mt-3 text-[1.2rem] font-bold tracking-[-0.03em]">{value}</p>
      <p className="text-xs font-medium text-[#2b261f]/70">{label}</p>
    </button>
  )
}
