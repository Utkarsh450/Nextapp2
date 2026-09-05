"use client"

import { ArrowUpRight, CalendarDays, ListChecks } from 'lucide-react'
import { checklistProgress, formatDueChip, type Habit, type HabitCheck, type Note, type NoteAgenda } from '@/lib/notes'
import HabitsBoard from './HabitsBoard'

export default function PlanView({
  agenda,
  today,
  habits,
  checks,
  onOpen,
  onAddHabit,
  onRemoveHabit,
  onToggleHabit,
}: {
  agenda: NoteAgenda
  today: string
  habits: Habit[]
  checks: HabitCheck[]
  onOpen: (id: number) => void
  onAddHabit: (name: string, color?: string) => void
  onRemoveHabit: (id: string) => void
  onToggleHabit: (habitId: string, date: string) => void
}) {
  return (
    <div className="px-4 pb-28">
      <div className="mb-5">
        <p className="text-[0.92rem] font-medium text-[var(--muted)]">Your day</p>
        <h2 className="mt-1 text-[1.85rem] font-bold leading-[1.05] tracking-[-0.04em]">Plan</h2>
        <p className="mt-2 max-w-sm text-sm leading-relaxed text-[var(--ink)]/70">
          Habits fill the paper. Dates, pings, and unfinished lists wait underneath.
        </p>
      </div>

      <HabitsBoard
        habits={habits}
        checks={checks}
        today={today}
        onAdd={onAddHabit}
        onRemove={onRemoveHabit}
        onToggle={onToggleHabit}
      />

      <p className="mb-3 mt-6 text-[0.92rem] font-medium text-[var(--muted)]">What’s next</p>

      {agenda.waiting === 0 ? (
        <div className="rounded-[28px] bg-[#C5CA8A] p-5 text-[#2b261f]">
          <CalendarDays size={22} strokeWidth={1.8} />
          <p className="mt-4 text-[1.25rem] font-bold tracking-[-0.03em]">Clear for now</p>
          <p className="mt-2 text-sm leading-relaxed text-[#2b261f]/70">
            Put a date on a note, or a checklist, and it will land here.
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          <AgendaCard
            title="Overdue"
            tone="#E7A3A3"
            notes={agenda.overdue}
            today={today}
            onOpen={onOpen}
          />
          <AgendaCard
            title="Due today"
            tone="#C5CA8A"
            notes={agenda.dueToday}
            today={today}
            onOpen={onOpen}
          />
          <AgendaCard
            title="Coming up"
            tone="#E89569"
            notes={agenda.soon}
            today={today}
            onOpen={onOpen}
          />
          <AgendaCard
            title="Open lists"
            tone="#D4C4E8"
            notes={agenda.lists}
            today={today}
            onOpen={onOpen}
            lists
          />
        </div>
      )}
    </div>
  )
}

function AgendaCard({
  title,
  tone,
  notes,
  today,
  onOpen,
  lists,
}: {
  title: string
  tone: string
  notes: Note[]
  today: string
  onOpen: (id: number) => void
  lists?: boolean
}) {
  if (notes.length === 0) return null

  return (
    <section className="rounded-[28px] p-4 text-[#2b261f]" style={{ backgroundColor: tone }}>
      <div className="flex items-center justify-between gap-3">
        <p className="text-[0.78rem] font-medium text-[#2b261f]/60">{title}</p>
        <span className="text-sm font-bold">{notes.length}</span>
      </div>
      <ul className="mt-3 space-y-2">
        {notes.map((note) => {
          const tasks = checklistProgress(note.body)
          const when = formatDueChip(note.dueAt, note.dueTime, today)
          return (
            <li key={note.id}>
              <button
                type="button"
                className="flex min-h-12 w-full items-center justify-between gap-3 rounded-full bg-white/70 px-3.5 text-left"
                onClick={() => onOpen(note.id)}
              >
                <span className="min-w-0">
                  <span className="block truncate text-sm font-semibold">{note.title || 'Untitled'}</span>
                  <span className="block truncate text-[0.72rem] text-[#2b261f]/60">
                    {lists && tasks.total
                      ? `${tasks.done} of ${tasks.total} tasks`
                      : when || note.notebook}
                  </span>
                </span>
                {lists ? <ListChecks size={16} /> : <ArrowUpRight size={16} />}
              </button>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
