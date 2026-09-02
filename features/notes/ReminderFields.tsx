"use client"

import { Bell } from 'lucide-react'
import { ALERT_OPTIONS, alertLabel, reminderFields, type ReminderFields as Fields } from '@/lib/notes'

export default function ReminderFields({
  dueAt,
  dueTime,
  alertMinutes,
  native,
  onChange,
}: {
  dueAt: string | null
  dueTime: string | null
  alertMinutes: number
  native: boolean
  onChange: (next: Fields) => void
}) {
  const patch = (partial: Partial<Fields>) => {
    onChange(reminderFields({ dueAt, dueTime, alertMinutes, ...partial }))
  }

  return (
    <div className="space-y-2 sm:col-span-2">
      <p className="mb-1 flex items-center gap-1.5 text-[0.7rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">
        <Bell size={12} /> Event · alert
      </p>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        <label className="block">
          <span className="sr-only">Date</span>
          <input
            type="date"
            value={dueAt ?? ''}
            onChange={(event) => {
              const next = event.target.value || null
              patch({
                dueAt: next,
                dueTime: next ? dueTime : null,
                alertMinutes: next ? (alertMinutes < 0 ? 0 : alertMinutes) : -1,
              })
            }}
            className="min-h-11 w-full rounded-2xl bg-white/60 px-3 py-2.5 text-sm outline-none dark:bg-white/5"
          />
        </label>
        <label className="block">
          <span className="sr-only">Time</span>
          <input
            type="time"
            value={dueTime ?? ''}
            disabled={!dueAt}
            onChange={(event) => {
              const time = event.target.value || null
              patch({
                dueTime: time,
                alertMinutes: !dueTime && time && alertMinutes <= 0 ? 10 : alertMinutes,
              })
            }}
            className="min-h-11 w-full rounded-2xl bg-white/60 px-3 py-2.5 text-sm outline-none disabled:opacity-40 dark:bg-white/5"
          />
        </label>
      </div>
      {dueAt && (
        <div className="flex flex-wrap gap-2">
          {ALERT_OPTIONS.map((item) => (
            <button
              key={item.minutes}
              type="button"
              className={`chip ${alertMinutes === item.minutes ? 'bg-[var(--ink)] text-[var(--paper)]' : ''}`}
              onClick={() => patch({ alertMinutes: item.minutes })}
            >
              {item.short}
            </button>
          ))}
        </div>
      )}
      <p className="text-xs leading-relaxed text-[var(--muted)]">
        {dueAt
          ? `${alertLabel(alertMinutes)}${dueTime ? '' : ' · all-day events alert at 9:00 AM'}. ${
              native
                ? 'The phone will ping even if Notes is closed.'
                : 'On the Android app this becomes a lock-screen alert, like Calendar.'
            }`
          : 'Add a date to get a lock-screen alert, like a calendar event.'}
      </p>
    </div>
  )
}
