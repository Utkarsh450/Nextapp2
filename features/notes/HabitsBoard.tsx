"use client"

import { Check, Plus, X } from 'lucide-react'
import { useMemo, useState } from 'react'
import { CardTape } from '@/components/ui/PaperStickers'
import { tickHaptic } from '@/lib/native/haptics'
import {
  NOTE_COLORS,
  SUGGESTED_HABITS,
  bestStreak,
  buildHeatmap,
  currentStreak,
  datesWithChecks,
  hasCheck,
  heatFill,
  heatmapMonthLabels,
  lastSevenDays,
  type Habit,
  type HabitCheck,
} from '@/lib/notes'

const WEEKDAYS = ['M', '', 'W', '', 'F', '', ''] as const

export default function HabitsBoard({
  habits,
  checks,
  today,
  onAdd,
  onRemove,
  onToggle,
}: {
  habits: Habit[]
  checks: HabitCheck[]
  today: string
  onAdd: (name: string, color?: string) => void
  onRemove: (id: string) => void
  onToggle: (habitId: string, date: string) => void
}) {
  const [selected, setSelected] = useState<string | null>(null)
  const [editing, setEditing] = useState(false)
  const [draft, setDraft] = useState('')
  const [composing, setComposing] = useState(false)

  const habit = habits.find((item) => item.id === selected) ?? null
  const accent = habit?.color ?? '#C5CA8A'
  const grid = useMemo(() => buildHeatmap(checks, today, habit?.id ?? null), [checks, habit?.id, today])
  const months = heatmapMonthLabels(grid.map((week) => week.map((day) => day.date)))
  const dates = datesWithChecks(checks, habit?.id ?? null)
  const streak = currentStreak(dates, today)
  const best = bestStreak(dates)
  const days = dates.length
  const recent = lastSevenDays(today)
  const suggestions = SUGGESTED_HABITS.filter(
    (item) => !habits.some((habitItem) => habitItem.name.toLowerCase() === item.name.toLowerCase())
  )

  const add = (name: string, color?: string) => {
    const next = name.trim()
    if (!next) return
    onAdd(next, color ?? NOTE_COLORS[habits.length % NOTE_COLORS.length])
    setDraft('')
    setComposing(false)
    tickHaptic()
  }

  const toggle = (habitId: string, date: string) => {
    if (date > today) return
    onToggle(habitId, date)
    tickHaptic()
  }

  return (
    <div className="relative mb-4">
      <CardTape className="left-7 -top-3" />
      <section className="relative rounded-[28px] bg-white/70 p-4 text-[#2b261f] ring-1 ring-black/5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-[0.78rem] font-medium text-[#2b261f]/60">
              {habit ? habit.name : 'Habits'}
            </p>
            <p className="mt-1 text-[1.15rem] font-bold tracking-[-0.03em]">
              {days ? `${days} day${days === 1 ? '' : 's'} on paper` : 'The paper is still blank'}
            </p>
            <p className="mt-1 text-sm text-[#2b261f]/65">
              {days
                ? `${streak} now · best ${best}`
                : 'Check a habit. Squares fill like a quiet garden.'}
            </p>
          </div>
          {habits.length > 0 && (
            <button
              type="button"
              className="shrink-0 rounded-full bg-[#2b261f]/8 px-3 py-1 text-[0.72rem] font-medium"
              onClick={() => setEditing((current) => !current)}
            >
              {editing ? 'Done' : 'Edit'}
            </button>
          )}
        </div>

        <div className="habit-heat mt-4" role="img" aria-label={habit ? `${habit.name} heatmap` : 'Habits heatmap'}>
          <div className="habit-heat-weekdays" aria-hidden="true">
            <span />
            {WEEKDAYS.map((label, index) => (
              <span key={`${label}-${index}`}>{label}</span>
            ))}
          </div>
          <div className="min-w-0 flex-1">
            <div className="habit-heat-months">
              {months.map((label, index) => (
                <span key={`m-${index}`}>{label}</span>
              ))}
            </div>
            <div className="habit-heat-grid">
              {grid.map((week) => (
                <div key={week[0].date} className="habit-heat-week">
                  {week.map((day) => (
                    <button
                      key={day.date}
                      type="button"
                      disabled={day.future}
                      aria-label={`${day.date}${day.count ? `, ${day.count} done` : ''}`}
                      className={`habit-heat-cell${day.date === today ? ' is-today' : ''}${day.future ? ' is-future' : ''}`}
                      style={{ backgroundColor: heatFill(day.level, accent) }}
                      onClick={() => {
                        if (habit) toggle(habit.id, day.date)
                      }}
                    />
                  ))}
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-between gap-3 text-[0.68rem] text-[#2b261f]/55">
          <span>{habit ? 'Tap a square to mark a day' : 'Tap a habit to paint this grid'}</span>
          <span className="flex items-center gap-1">
            Less
            {[0, 1, 2, 3, 4].map((level) => (
              <span
                key={level}
                className="h-2.5 w-2.5 rounded-[3px]"
                style={{ backgroundColor: heatFill(level as 0 | 1 | 2 | 3 | 4, accent) }}
              />
            ))}
            More
          </span>
        </div>

        <ul className="mt-4 space-y-2">
          {habits.map((item) => {
            const done = hasCheck(checks, item.id, today)
            const active = selected === item.id
            return (
              <li key={item.id}>
                <div
                  className={`flex min-h-12 items-center gap-2 rounded-full bg-[#2b261f]/5 px-1.5 ${
                    active ? 'ring-2 ring-[#2b261f]' : ''
                  }`}
                >
                  <button
                    type="button"
                    aria-label={done ? `Uncheck ${item.name}` : `Check ${item.name} today`}
                    className="grid h-10 w-10 shrink-0 place-items-center rounded-full"
                    style={{ backgroundColor: done ? item.color : 'rgba(43,38,31,0.08)' }}
                    onClick={() => toggle(item.id, today)}
                  >
                    {done ? <Check size={16} strokeWidth={2.2} /> : null}
                  </button>
                  <button
                    type="button"
                    className="min-w-0 flex-1 py-2 text-left"
                    onClick={() => setSelected((current) => (current === item.id ? null : item.id))}
                  >
                    <span className="block truncate text-sm font-semibold">{item.name}</span>
                    <span className="mt-1 flex gap-1">
                      {recent.map((date) => (
                        <span
                          key={date}
                          className="h-1.5 w-1.5 rounded-full"
                          style={{
                            backgroundColor: hasCheck(checks, item.id, date)
                              ? item.color
                              : 'rgba(43,38,31,0.16)',
                          }}
                        />
                      ))}
                    </span>
                  </button>
                  {editing && (
                    <button
                      type="button"
                      aria-label={`Remove ${item.name}`}
                      className="grid h-9 w-9 place-items-center rounded-full text-[#2b261f]/55"
                      onClick={() => {
                        if (selected === item.id) setSelected(null)
                        onRemove(item.id)
                      }}
                    >
                      <X size={16} />
                    </button>
                  )}
                </div>
              </li>
            )
          })}
        </ul>

        {composing ? (
          <form
            className="mt-3 flex gap-2"
            onSubmit={(event) => {
              event.preventDefault()
              add(draft)
            }}
          >
            <input
              autoFocus
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              placeholder="Write, stretch, read…"
              className="min-h-12 flex-1 rounded-full bg-[#2b261f]/6 px-4 text-sm outline-none placeholder:text-[#2b261f]/35"
            />
            <button type="submit" className="grid h-12 w-12 place-items-center rounded-full bg-[#1a1814] text-white">
              <Plus size={18} />
            </button>
          </form>
        ) : (
          <button
            type="button"
            className="mt-3 flex min-h-12 w-full items-center justify-center gap-2 rounded-full bg-[#C5CA8A] text-sm font-semibold"
            onClick={() => setComposing(true)}
          >
            <Plus size={16} /> Add a habit
          </button>
        )}

        {habits.length === 0 && suggestions.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-2">
            {suggestions.map((item) => (
              <button
                key={item.name}
                type="button"
                className="rounded-full px-3 py-2 text-[0.78rem] font-medium text-[#2b261f]"
                style={{ backgroundColor: item.color }}
                onClick={() => add(item.name, item.color)}
              >
                {item.name}
              </button>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
