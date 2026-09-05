import { shiftISO } from './agenda.ts'
import { NOTE_COLORS, slugify, type Habit, type HabitCheck } from './types.ts'

export const HEATMAP_WEEKS = 18

export const SUGGESTED_HABITS: Array<{ name: string; color: string }> = [
  { name: 'Write', color: '#C5CA8A' },
  { name: 'Move', color: '#E7A3A3' },
  { name: 'Read', color: '#D4C4E8' },
]

export type HeatLevel = 0 | 1 | 2 | 3 | 4

export type HeatDay = {
  date: string
  count: number
  level: HeatLevel
  future: boolean
}

const isPaperColor = (color: string): color is (typeof NOTE_COLORS)[number] =>
  (NOTE_COLORS as readonly string[]).includes(color)

export const createHabit = (
  ownerEmail: string,
  name: string,
  color?: string,
  now = Date.now()
): Habit => ({
  id: `hab-${slugify(name)}-${now}`,
  ownerEmail: ownerEmail.trim().toLowerCase(),
  name: name.trim() || 'Habit',
  color: color && isPaperColor(color) ? color : NOTE_COLORS[now % NOTE_COLORS.length],
  createdAt: now,
})

export const mondayIndex = (iso: string) => {
  const [year, month, day] = iso.split('-').map(Number)
  return (new Date(year, month - 1, day).getDay() + 6) % 7
}

export const weekEndSunday = (iso: string) => shiftISO(iso, 6 - mondayIndex(iso))

export const heatmapWeeks = (today: string, weekCount = HEATMAP_WEEKS) => {
  const last = weekEndSunday(today)
  const first = shiftISO(last, -(weekCount * 7 - 1))
  return Array.from({ length: weekCount }, (_, week) =>
    Array.from({ length: 7 }, (_, day) => shiftISO(first, week * 7 + day))
  )
}

export const heatLevel = (count: number, max: number): HeatLevel => {
  if (count <= 0 || max <= 0) return 0
  if (max === 1) return 3
  const t = count / max
  if (t <= 0.25) return 1
  if (t <= 0.5) return 2
  if (t <= 0.75) return 3
  return 4
}

export const heatFill = (level: HeatLevel, accent = '#C5CA8A') => {
  if (level <= 0) return 'rgba(43, 38, 31, 0.10)'
  if (level === 1) return `color-mix(in srgb, ${accent} 72%, white)`
  if (level === 2) return accent
  if (level === 3) return `color-mix(in srgb, ${accent} 62%, #2b261f)`
  return '#2b261f'
}

export const countsByDate = (checks: HabitCheck[], habitId?: string | null) => {
  const map: Record<string, number> = {}
  for (const check of checks) {
    if (habitId && check.habitId !== habitId) continue
    map[check.date] = (map[check.date] ?? 0) + 1
  }
  return map
}

export const datesWithChecks = (checks: HabitCheck[], habitId?: string | null) => {
  const dates = new Set<string>()
  for (const check of checks) {
    if (habitId && check.habitId !== habitId) continue
    dates.add(check.date)
  }
  return [...dates].sort()
}

export const currentStreak = (dates: string[], today: string) => {
  const set = new Set(dates)
  let cursor = set.has(today) ? today : shiftISO(today, -1)
  if (!set.has(cursor)) return 0
  let streak = 0
  while (set.has(cursor)) {
    streak += 1
    cursor = shiftISO(cursor, -1)
  }
  return streak
}

export const bestStreak = (dates: string[]) => {
  const sorted = [...new Set(dates)].sort()
  if (sorted.length === 0) return 0
  let best = 1
  let run = 1
  for (let index = 1; index < sorted.length; index += 1) {
    if (shiftISO(sorted[index - 1], 1) === sorted[index]) run += 1
    else run = 1
    if (run > best) best = run
  }
  return best
}

export const hasCheck = (checks: HabitCheck[], habitId: string, date: string) =>
  checks.some((item) => item.habitId === habitId && item.date === date)

export const toggleHabitCheck = (
  checks: HabitCheck[],
  ownerEmail: string,
  habitId: string,
  date: string
) => {
  const email = ownerEmail.trim().toLowerCase()
  if (hasCheck(checks, habitId, date)) {
    return {
      checks: checks.filter((item) => !(item.habitId === habitId && item.date === date)),
      added: false,
    }
  }
  return {
    checks: [...checks, { ownerEmail: email, habitId, date }],
    added: true,
  }
}

export const buildHeatmap = (
  checks: HabitCheck[],
  today: string,
  habitId?: string | null,
  weekCount = HEATMAP_WEEKS
): HeatDay[][] => {
  const counts = countsByDate(checks, habitId)
  const max = Math.max(0, ...Object.values(counts))
  return heatmapWeeks(today, weekCount).map((week) =>
    week.map((date) => {
      const count = counts[date] ?? 0
      return {
        date,
        count,
        level: heatLevel(count, max),
        future: date > today,
      }
    })
  )
}

export const heatmapMonthLabels = (weeks: string[][]) => {
  let last = ''
  return weeks.map((week, index) => {
    const first = week[0]
    const [year, month] = first.split('-').map(Number)
    const label = new Date(year, month - 1, 1).toLocaleString('en-US', { month: 'short' })
    const marked = index === 0 || week.some((iso) => iso.endsWith('-01'))
    if (!marked || label === last) return ''
    last = label
    return label
  })
}

export const lastSevenDays = (today: string) =>
  Array.from({ length: 7 }, (_, index) => shiftISO(today, index - 6))
