import { NOTE_COLORS, slugify, type Attachment, type LegacyNote, type Note } from './types.ts'

const sanitizeLabels = (labels: unknown) =>
  Array.isArray(labels)
    ? [...new Set(labels.filter((item): item is string => typeof item === 'string' && Boolean(item.trim())).map((item) => item.trim()))]
    : []

const sanitizeAttachments = (attachments: unknown): Attachment[] => {
  if (!Array.isArray(attachments)) return []
  return attachments
    .filter((item): item is Attachment =>
      Boolean(item && typeof item === 'object' && typeof (item as Attachment).dataUrl === 'string')
    )
    .map((item, index) => ({
      id: String(item.id || `att-${index}`),
      name: String(item.name || 'Attachment'),
      mime: String(item.mime || 'image/jpeg'),
      dataUrl: item.dataUrl,
      createdAt: Number(item.createdAt) || Date.now(),
    }))
}

export const normalizeNote = (item: LegacyNote, index = 0, ownerEmail = ''): Note => {
  const notebookName = (item.notebook ?? item.institute ?? 'Inbox').trim() || 'Inbox'
  const createdAt = item.createdAt ?? Date.now()
  return {
    id: item.id ?? Date.now() + index,
    ownerEmail: item.ownerEmail || ownerEmail,
    title: item.title ?? '',
    tag: item.tag ?? item.amount ?? '',
    preview: item.preview ?? item.author ?? '',
    notebookId: item.notebookId || slugify(notebookName),
    notebook: notebookName,
    logo: item.logo ?? null,
    confirmed: Boolean(item.confirmed),
    createdAt,
    updatedAt: item.updatedAt ?? createdAt,
    body: item.body ?? '',
    pinned: Boolean(item.pinned),
    archived: Boolean(item.archived),
    trashedAt: typeof item.trashedAt === 'number' ? item.trashedAt : null,
    color: item.color || NOTE_COLORS[Math.abs((item.id ?? index) % NOTE_COLORS.length)],
    dueAt: item.dueAt ?? null,
    remindAt: item.remindAt ?? item.dueAt ?? null,
    labels: sanitizeLabels(item.labels),
    attachments: sanitizeAttachments(item.attachments),
    order: typeof item.order === 'number' ? item.order : index,
  }
}

export const belongsToOwner = (note: Note, email: string) =>
  note.ownerEmail === email.trim().toLowerCase()
