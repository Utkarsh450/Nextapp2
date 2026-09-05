import type { AccountBundle, Habit, HabitCheck, Note, Notebook, SavedTemplate } from './types.ts'
import { belongsToOwner } from './normalize.ts'

export const isolateNotes = (notes: Note[], email: string) =>
  notes.filter((note) => belongsToOwner(note, email))

export const isolateNotebooks = (notebooks: Notebook[], email: string) => {
  const owner = email.trim().toLowerCase()
  return notebooks.filter((item) => item.ownerEmail === owner)
}

export const isolateTemplates = (templates: SavedTemplate[], email: string) => {
  const owner = email.trim().toLowerCase()
  return templates.filter((item) => item.ownerEmail === owner)
}

export const isolateHabits = (habits: Habit[], email: string) => {
  const owner = email.trim().toLowerCase()
  return habits.filter((item) => item.ownerEmail === owner)
}

export const isolateHabitChecks = (checks: HabitCheck[], email: string) => {
  const owner = email.trim().toLowerCase()
  return checks.filter((item) => item.ownerEmail === owner)
}

export const isolateBundle = (bundle: AccountBundle, email: string): AccountBundle => ({
  notes: isolateNotes(bundle.notes, email),
  notebooks: isolateNotebooks(bundle.notebooks, email),
  templates: isolateTemplates(bundle.templates, email),
  recents: bundle.recents,
})
