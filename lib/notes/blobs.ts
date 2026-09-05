import type { Attachment, Note } from './types.ts'

export const BLOB_SCHEME = 'notes-blob:'

export const blobMarkdownSrc = (id: string) => `${BLOB_SCHEME}${id}`

export const blobIdFromSrc = (src: string) =>
  src.startsWith(BLOB_SCHEME) ? src.slice(BLOB_SCHEME.length) : null

export const blobIdsInBody = (body: string) => {
  const ids: string[] = []
  const seen = new Set<string>()
  for (const match of body.matchAll(/notes-blob:([A-Za-z0-9._-]+)/g)) {
    const id = match[1]
    if (!id || seen.has(id)) continue
    seen.add(id)
    ids.push(id)
  }
  return ids
}

export const firstNoteCover = (note: Pick<Note, 'body' | 'attachments'>) => {
  const image = /!\[([^\]]*)\]\(([^)]+)\)/.exec(note.body)
  if (image?.[2]) {
    const blobId = blobIdFromSrc(image[2])
    if (blobId) return { blobId, src: null as string | null }
    return { blobId: null as string | null, src: image[2] }
  }
  const file = note.attachments.find((item) => isImageMime(item.mime) || Boolean(item.dataUrl))
  if (!file) return null
  if (file.dataUrl) return { blobId: null, src: file.dataUrl }
  return { blobId: file.id, src: null }
}

export const collectBlobIds = (note: Pick<Note, 'body' | 'attachments'>) =>
  [...new Set([...note.attachments.map((item) => item.id), ...blobIdsInBody(note.body)])]

export const isImageMime = (mime: string) => mime.startsWith('image/')

export const attachmentMeta = (item: Attachment): Attachment => ({
  id: item.id,
  name: item.name,
  mime: item.mime,
  createdAt: item.createdAt,
})

export const dataUrlMime = (dataUrl: string) =>
  /data:([^;,]+)/i.exec(dataUrl)?.[1] || 'application/octet-stream'

export const dataUrlToBlob = (dataUrl: string) => {
  const comma = dataUrl.indexOf(',')
  if (comma < 0) return new Blob()
  const header = dataUrl.slice(0, comma)
  const payload = dataUrl.slice(comma + 1)
  const mime = dataUrlMime(dataUrl)
  if (/;base64/i.test(header)) {
    try {
      const binary = atob(payload)
      const bytes = new Uint8Array(binary.length)
      for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index)
      return new Blob([bytes], { type: mime })
    } catch {
      return new Blob([], { type: mime })
    }
  }
  try {
    return new Blob([decodeURIComponent(payload)], { type: mime })
  } catch {
    return new Blob([payload], { type: mime })
  }
}

export const blobToDataUrl = (blob: Blob) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Could not read attachment'))
    reader.onload = () => resolve(String(reader.result || ''))
    reader.readAsDataURL(blob)
  })

export const rewriteBlobSrcs = (body: string, urls: Record<string, string>) =>
  body.replace(/notes-blob:([A-Za-z0-9._-]+)/g, (full, id: string) => urls[id] || full)

export const replaceInlineDataImages = (body: string, replace: (alt: string, dataUrl: string) => string) =>
  body.replace(/!\[([^\]]*)\]\((data:[^)]+)\)/g, (_, alt: string, dataUrl: string) => {
    const src = replace(alt, dataUrl)
    return `![${alt}](${src})`
  })
