import { isDueToday, isOverdue, todayISO } from './dates.ts'
import { checklistProgress } from './markdown.ts'
import type { Note } from './types.ts'

const liveNotes = (notes: Note[]) =>
  notes.filter((note) => !note.trashedAt && !note.archived)

export const shiftISO = (iso: string, days: number) => {
  const [year, month, day] = iso.split('-').map(Number)
  return todayISO(new Date(year, month - 1, day + days))
}

const byDue = (a: Note, b: Note) => {
  const date = (a.dueAt ?? '').localeCompare(b.dueAt ?? '')
  if (date) return date
  return (a.dueTime ?? '99:99').localeCompare(b.dueTime ?? '99:99')
}

export type NoteAgenda = {
  overdue: Note[]
  dueToday: Note[]
  soon: Note[]
  lists: Note[]
  waiting: number
}

export const noteAgenda = (notes: Note[], today = todayISO()): NoteAgenda => {
  const items = liveNotes(notes)
  const horizon = shiftISO(today, 7)
  const overdue = items.filter((note) => isOverdue(note.dueAt, today)).sort(byDue)
  const dueToday = items.filter((note) => isDueToday(note.dueAt, today)).sort(byDue)
  const soon = items
    .filter((note) => note.dueAt && note.dueAt > today && note.dueAt <= horizon)
    .sort(byDue)
  const lists = items.filter((note) => {
    const progress = checklistProgress(note.body)
    return progress.total > 0 && progress.done < progress.total && !note.dueAt
  })

  return {
    overdue,
    dueToday,
    soon,
    lists,
    waiting: overdue.length + dueToday.length + soon.length + lists.length,
  }
}
