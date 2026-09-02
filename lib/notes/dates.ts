export const todayISO = (now = new Date()) => {
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export const formatNoteTimestamp = (createdAt: number, now = new Date(createdAt)) => {
  const time = now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })
  const weekday = now.toLocaleDateString('en-US', { weekday: 'long' })
  return `${time}, ${weekday}`
}

export const formatRelativeTime = (createdAt: number, now = Date.now()) => {
  const diff = Math.max(0, now - createdAt)
  const minute = 60 * 1000
  const hour = 60 * minute
  const day = 24 * hour
  if (diff < minute) return 'just now'
  if (diff < hour) return `${Math.floor(diff / minute)}m`
  if (diff < day) return `${Math.floor(diff / hour)}h`
  if (diff < 7 * day) return `${Math.floor(diff / day)}d`
  return formatNoteTimestamp(createdAt)
}

export const isDueToday = (dueAt: string | null, today = todayISO()) =>
  Boolean(dueAt && dueAt === today)

export const isOverdue = (dueAt: string | null, today = todayISO()) =>
  Boolean(dueAt && dueAt < today)

export const dueLabel = (dueAt: string | null, today = todayISO()) => {
  if (!dueAt) return null
  if (isOverdue(dueAt, today)) return 'Overdue'
  if (isDueToday(dueAt, today)) return 'Due today'
  return dueAt
}
