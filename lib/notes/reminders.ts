const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/
const TIME_RE = /^(\d{2}):(\d{2})$/

export const ALL_DAY_HOUR = 9

export const ALERT_OPTIONS = [
  { minutes: -1, label: 'No alert', short: 'None' },
  { minutes: 0, label: 'At time of event', short: 'At time' },
  { minutes: 5, label: '5 minutes before', short: '5 min' },
  { minutes: 10, label: '10 minutes before', short: '10 min' },
  { minutes: 30, label: '30 minutes before', short: '30 min' },
  { minutes: 60, label: '1 hour before', short: '1 hour' },
  { minutes: 1440, label: '1 day before', short: '1 day' },
] as const

export type AlertMinutes = (typeof ALERT_OPTIONS)[number]['minutes']

export type ReminderFields = {
  dueAt: string | null
  dueTime: string | null
  alertMinutes: number
  remindAt: string | null
}

const isAlertMinutes = (value: number): value is AlertMinutes =>
  ALERT_OPTIONS.some((item) => item.minutes === value)

export const dateOnly = (value: string | null | undefined) => {
  if (!value) return null
  const match = value.slice(0, 10).match(DATE_RE)
  return match ? match[0] : null
}

export const timeOnly = (value: string | null | undefined) => {
  if (!value) return null
  const match = value.match(TIME_RE)
  if (!match) return null
  const hour = Number(match[1])
  const minute = Number(match[2])
  if (hour > 23 || minute > 59) return null
  return `${match[1]}:${match[2]}`
}

const eventDate = (dueAt: string, dueTime: string | null) => {
  const date = dueAt.match(DATE_RE)
  if (!date) return null
  const time = dueTime?.match(TIME_RE)
  const hour = time ? Number(time[1]) : ALL_DAY_HOUR
  const minute = time ? Number(time[2]) : 0
  const at = new Date(Number(date[1]), Number(date[2]) - 1, Number(date[3]), hour, minute, 0, 0)
  return Number.isNaN(at.getTime()) ? null : at
}

export const toLocalDateTime = (at: Date) => {
  const year = at.getFullYear()
  const month = String(at.getMonth() + 1).padStart(2, '0')
  const day = String(at.getDate()).padStart(2, '0')
  const hour = String(at.getHours()).padStart(2, '0')
  const minute = String(at.getMinutes()).padStart(2, '0')
  return `${year}-${month}-${day}T${hour}:${minute}`
}

export const reminderFireDate = (
  dueAt: string | null | undefined,
  dueTime: string | null | undefined,
  alertMinutes: number,
  now = Date.now(),
) => {
  const date = dateOnly(dueAt ?? null)
  if (!date || alertMinutes < 0) return null
  const event = eventDate(date, timeOnly(dueTime ?? null))
  if (!event) return null
  event.setMinutes(event.getMinutes() - Math.max(0, alertMinutes))
  return event.getTime() > now ? event : null
}

export const reminderFields = (input: {
  dueAt?: string | null
  dueTime?: string | null
  alertMinutes?: number
}): ReminderFields => {
  const dueAt = dateOnly(input.dueAt ?? null)
  if (!dueAt) {
    return { dueAt: null, dueTime: null, alertMinutes: -1, remindAt: null }
  }
  const dueTime = timeOnly(input.dueTime ?? null)
  const alertMinutes = typeof input.alertMinutes === 'number' && isAlertMinutes(input.alertMinutes)
    ? input.alertMinutes
    : 0
  const fire = reminderFireDate(dueAt, dueTime, alertMinutes, 0)
  return {
    dueAt,
    dueTime,
    alertMinutes,
    remindAt: fire ? toLocalDateTime(fire) : null,
  }
}

export const formatClock = (dueTime: string | null) => {
  const time = timeOnly(dueTime)
  if (!time) return null
  const [hourText, minuteText] = time.split(':')
  const hour = Number(hourText)
  const suffix = hour >= 12 ? 'PM' : 'AM'
  const twelve = hour % 12 || 12
  return `${twelve}:${minuteText} ${suffix}`
}

export const alertLabel = (alertMinutes: number) =>
  ALERT_OPTIONS.find((item) => item.minutes === alertMinutes)?.label ?? 'At time of event'

export const formatDueChip = (
  dueAt: string | null,
  dueTime: string | null = null,
  today = '',
) => {
  const date = dateOnly(dueAt)
  if (!date) return null
  const clock = formatClock(dueTime)
  if (today && date < today) return clock ? `Overdue · ${clock}` : 'Overdue'
  if (today && date === today) return clock ?? 'Due today'
  const pretty = new Date(`${date}T12:00:00`).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
  })
  return clock ? `${pretty} · ${clock}` : pretty
}

export const reminderBody = (title: string, dueAt: string | null, dueTime: string | null, preview: string) => {
  const when = formatDueChip(dueAt, dueTime)
  const snippet = preview.trim().slice(0, 80)
  return [when, snippet || title || 'You have a note due.'].filter(Boolean).join(' · ')
}
