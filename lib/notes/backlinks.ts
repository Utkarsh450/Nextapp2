import type { Note } from './types.ts'

const WIKI = /\[\[([^[\]]+)\]\]/g

export const parseWikiLinks = (body: string) => {
  const titles: string[] = []
  const seen = new Set<string>()
  for (const match of body.matchAll(WIKI)) {
    const title = match[1]?.trim()
    if (!title) continue
    const key = title.toLowerCase()
    if (seen.has(key)) continue
    seen.add(key)
    titles.push(title)
  }
  return titles
}

export const insertWikiLink = (body: string, title: string) => {
  const name = title.trim()
  if (!name) return body
  const token = `[[${name}]]`
  if (body.includes(token)) return body
  const prefix = body.trim() ? `${body.replace(/\s+$/, '')} ` : ''
  return `${prefix}${token}`
}

export const wikiSegments = (text: string) => {
  const parts: Array<{ text: string; link: string | null }> = []
  let last = 0
  for (const match of text.matchAll(WIKI)) {
    const start = match.index ?? 0
    if (start > last) parts.push({ text: text.slice(last, start), link: null })
    parts.push({ text: match[1].trim(), link: match[1].trim() })
    last = start + match[0].length
  }
  if (last < text.length) parts.push({ text: text.slice(last), link: null })
  return parts.length ? parts : [{ text, link: null }]
}

const liveNotes = (notes: Note[]) =>
  notes.filter((note) => !note.trashedAt && !note.archived)

export const findNoteByTitle = (notes: Note[], title: string) => {
  const key = title.trim().toLowerCase()
  if (!key) return null
  return liveNotes(notes).find((note) => note.title.trim().toLowerCase() === key) ?? null
}

export const outgoingLinks = (note: Note, notes: Note[]) =>
  parseWikiLinks(note.body)
    .map((title) => ({ title, note: findNoteByTitle(notes, title) }))

export const backlinksTo = (note: Note, notes: Note[]) => {
  const title = note.title.trim().toLowerCase()
  if (!title) return []
  return liveNotes(notes).filter((item) => {
    if (item.id === note.id) return false
    return parseWikiLinks(item.body).some((link) => link.toLowerCase() === title)
  })
}

export const linkableNotes = (notes: Note[], currentId: number) =>
  liveNotes(notes)
    .filter((note) => note.id !== currentId && note.title.trim())
    .slice()
    .sort((a, b) => a.title.localeCompare(b.title))
