import { isDueToday, isOverdue, todayISO } from './dates.ts'
import { checklistProgress } from './markdown.ts'
import type { Note, Notebook } from './types.ts'

export type WeekPoint = { day: string; count: number }

export type NoteDashboard = {
  live: number
  open: number
  done: number
  due: Note[]
  tasks: { total: number; done: number }
  percent: number
  week: WeekPoint[]
  featured: Note | null
  notebooks: Array<{ id: string; name: string; color: string; count: number }>
}

const dayMs = 24 * 60 * 60 * 1000

const liveNotes = (notes: Note[]) =>
  notes.filter((note) => !note.trashedAt && !note.archived)

export const greetingForHour = (hour: number) => {
  if (hour < 12) return 'Good morning'
  if (hour < 17) return 'Good afternoon'
  return 'Good evening'
}

export const sparkPath = (values: number[], width = 88, height = 32) => {
  if (values.length === 0) return ''
  const max = Math.max(...values, 1)
  const last = Math.max(values.length - 1, 1)
  return values
    .map((value, index) => {
      const x = (index / last) * width
      const y = height - 3 - (value / max) * (height - 6)
      return `${index === 0 ? 'M' : 'L'}${x.toFixed(1)} ${y.toFixed(1)}`
    })
    .join(' ')
}

export const noteDashboard = (
  notes: Note[],
  notebooks: Notebook[],
  today = todayISO(),
  now = Date.now()
): NoteDashboard => {
  const live = liveNotes(notes)
  const tasks = live.reduce(
    (sum, note) => {
      const progress = checklistProgress(note.body)
      return { total: sum.total + progress.total, done: sum.done + progress.done }
    },
    { total: 0, done: 0 }
  )
  const due = live.filter((note) => isDueToday(note.dueAt, today) || isOverdue(note.dueAt, today))
  const done = live.filter((note) => note.confirmed).length
  const open = live.length - done
  const percent = tasks.total
    ? Math.round((tasks.done / tasks.total) * 100)
    : live.length
      ? Math.round((done / live.length) * 100)
      : 0

  const week: WeekPoint[] = Array.from({ length: 7 }, (_, index) => {
    const date = new Date(now - (6 - index) * dayMs)
    const day = todayISO(date)
    const count = live.filter((note) => todayISO(new Date(note.updatedAt || note.createdAt)) === day).length
    return { day, count }
  })

  const featured =
    live.find((note) => note.pinned) ??
    due[0] ??
    live.find((note) => checklistProgress(note.body).total > 0) ??
    live[0] ??
    null

  const counts = live.reduce<Record<string, number>>((map, note) => {
    map[note.notebookId] = (map[note.notebookId] ?? 0) + 1
    return map
  }, {})

  return {
    live: live.length,
    open,
    done,
    due,
    tasks,
    percent,
    week,
    featured,
    notebooks: notebooks.map((item) => ({
      id: item.id,
      name: item.name,
      color: item.color,
      count: counts[item.id] ?? 0,
    })),
  }
}
