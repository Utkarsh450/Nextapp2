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

export const collectBlobIds = (note: Pick<Note, 'body' | 'attachments'>) =>
  [...new Set([...note.attachments.map((item) => item.id), ...blobIdsInBody(note.body)])]

export const isImageMime = (mime: string) => mime.startsWith('image/')

export const attachmentMeta = (item: Attachment): Attachment => ({
  id: item.id,
  name: item.name,
  mime: item.mime,
  createdAt: item.createdAt,
})

export const dataUrlToBlob = (dataUrl: string) => {
  const comma = dataUrl.indexOf(',')
  if (comma < 0) return new Blob()
  const header = dataUrl.slice(0, comma)
  const data = dataUrl.slice(comma + 1)
  const mime = /data:([^;]+)/.exec(header)?.[1] || 'application/octet-stream'
  const binary = atob(data)
  const bytes = new Uint8Array(binary.length)
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index)
  return new Blob([bytes], { type: mime })
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
