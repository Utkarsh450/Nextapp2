import type { QueuedMutation } from './types.ts'

export const QUEUE_LIMIT = 120

const NOISE = new Set(['account.opened', 'account.saved'])

export const shouldEnqueue = (kind: string) => !NOISE.has(kind)

export const mutationDedupeKey = (item: QueuedMutation) => {
  const payload = item.payload && typeof item.payload === 'object'
    ? (item.payload as { id?: number | string })
    : {}
  if (item.kind === 'note.saved' || item.kind === 'note.trashed' || item.kind === 'note.deleted') {
    return `${item.kind}:${payload.id ?? ''}`
  }
  return `${item.kind}:${item.id ?? item.createdAt}`
}

export const compactMutations = (items: QueuedMutation[]) => {
  const pending = items
    .filter((item) => item.synced === 0 && shouldEnqueue(item.kind))
    .sort((left, right) => left.createdAt - right.createdAt)

  const latest = new Map<string, QueuedMutation>()
  for (const item of pending) latest.set(mutationDedupeKey(item), item)

  const deleted = new Set(
    [...latest.values()]
      .filter((item) => item.kind === 'note.deleted')
      .map((item) => String((item.payload as { id?: number } | undefined)?.id ?? ''))
  )

  return [...latest.values()]
    .filter((item) => {
      if (item.kind !== 'note.saved' && item.kind !== 'note.trashed') return true
      const id = String((item.payload as { id?: number } | undefined)?.id ?? '')
      return !deleted.has(id)
    })
    .sort((left, right) => left.createdAt - right.createdAt)
    .slice(-QUEUE_LIMIT)
}

export const formatBytes = (bytes: number) => {
  if (bytes < 1024) return `${Math.max(0, Math.round(bytes))} B`
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
