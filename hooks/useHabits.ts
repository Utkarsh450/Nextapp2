import { useCallback, useEffect, useState } from 'react'
import {
  createHabit,
  deleteHabitCheck,
  deleteHabitRecord,
  loadHabits,
  putHabit,
  putHabitCheck,
  toggleHabitCheck,
  type Habit,
  type HabitCheck,
} from '@/lib/notes'

export const useHabits = (ownerEmail: string | null) => {
  const [habits, setHabits] = useState<Habit[]>([])
  const [checks, setChecks] = useState<HabitCheck[]>([])
  const [loadedFor, setLoadedFor] = useState<string | null>(null)

  if (ownerEmail !== loadedFor) {
    setLoadedFor(ownerEmail)
    setHabits([])
    setChecks([])
  }

  useEffect(() => {
    let cancelled = false
    if (!ownerEmail) return
    void loadHabits(ownerEmail).then((bundle) => {
      if (cancelled) return
      setHabits(bundle.habits)
      setChecks(bundle.checks)
    })
    return () => {
      cancelled = true
    }
  }, [ownerEmail])

  const addHabit = useCallback((name: string, color?: string) => {
    if (!ownerEmail) return null
    const habit = createHabit(ownerEmail, name, color)
    setHabits((current) => [...current, habit])
    void putHabit(habit)
    return habit
  }, [ownerEmail])

  const removeHabit = useCallback((id: string) => {
    if (!ownerEmail) return
    setHabits((current) => current.filter((item) => item.id !== id))
    setChecks((current) => current.filter((item) => item.habitId !== id))
    void deleteHabitRecord(ownerEmail, id)
  }, [ownerEmail])

  const toggleCheck = useCallback((habitId: string, date: string) => {
    if (!ownerEmail) return
    setChecks((current) => {
      const next = toggleHabitCheck(current, ownerEmail, habitId, date)
      if (next.added) {
        void putHabitCheck({ ownerEmail, habitId, date })
      } else {
        void deleteHabitCheck(ownerEmail, habitId, date)
      }
      return next.checks
    })
  }, [ownerEmail])

  return { habits, checks, addHabit, removeHabit, toggleCheck }
}
