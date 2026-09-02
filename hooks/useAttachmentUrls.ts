import { useEffect, useState } from 'react'
import { readNoteBlobUrl } from '@/lib/notes'

export const useAttachmentUrls = (ownerEmail: string | null, ids: string[]) => {
  const [urls, setUrls] = useState<Record<string, string>>({})
  const key = ids.join('|')
  const readyKey = ownerEmail && key ? `${ownerEmail}:${key}` : ''

  useEffect(() => {
    if (!readyKey || !ownerEmail) return
    const list = key.split('|')
    let cancelled = false
    const created: string[] = []
    void Promise.all(
      list.map(async (id) => {
        const url = await readNoteBlobUrl(ownerEmail, id)
        return [id, url] as const
      })
    ).then((entries) => {
      if (cancelled) {
        entries.forEach(([, url]) => {
          if (url) URL.revokeObjectURL(url)
        })
        return
      }
      const next: Record<string, string> = {}
      for (const [id, url] of entries) {
        if (!url) continue
        created.push(url)
        next[id] = url
      }
      setUrls(next)
    })
    return () => {
      cancelled = true
      created.forEach((url) => URL.revokeObjectURL(url))
    }
  }, [ownerEmail, key, readyKey])

  return readyKey ? urls : {}
}
