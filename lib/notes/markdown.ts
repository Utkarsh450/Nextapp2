export type MarkdownBlock =
  | { type: 'heading'; level: 1 | 2 | 3; text: string }
  | { type: 'task'; checked: boolean; text: string; line: number }
  | { type: 'list'; text: string }
  | { type: 'image'; src: string; alt: string }
  | { type: 'paragraph'; text: string }

export const parseMarkdown = (body: string): MarkdownBlock[] => {
  if (!body.trim()) return []
  const blocks: MarkdownBlock[] = []

  body.split('\n').forEach((line, lineIndex) => {
    if (!line.trim()) return
    const heading = /^(#{1,3})\s+(.*)$/.exec(line)
    if (heading) {
      blocks.push({
        type: 'heading',
        level: heading[1].length as 1 | 2 | 3,
        text: heading[2],
      })
      return
    }
    const image = /^!\[([^\]]*)\]\((.+)\)$/.exec(line.trim())
    if (image) {
      blocks.push({ type: 'image', src: image[2], alt: image[1] })
      return
    }
    const task = /^\s*- \[( |x|X)\]\s+(.*)$/.exec(line)
    if (task) {
      blocks.push({
        type: 'task',
        checked: task[1].toLowerCase() === 'x',
        text: task[2],
        line: lineIndex,
      })
      return
    }
    if (/^\s*-\s+/.test(line)) {
      blocks.push({ type: 'list', text: line.replace(/^\s*-\s+/, '') })
      return
    }
    blocks.push({ type: 'paragraph', text: line })
  })

  return blocks
}

export const insertChecklist = (body: string) => {
  const prefix = body.trim() ? `${body.replace(/\s+$/, '')}\n` : ''
  return `${prefix}- [ ] `
}

export const insertImageMarkdown = (body: string, src: string, alt = 'image') => {
  const prefix = body.trim() ? `${body.replace(/\s+$/, '')}\n\n` : ''
  return `${prefix}![${alt}](${src})`
}

export const toggleTaskLine = (body: string, lineIndex: number) => {
  const lines = body.split('\n')
  const line = lines[lineIndex]
  if (!line) return body
  if (line.includes('- [ ]')) lines[lineIndex] = line.replace('- [ ]', '- [x]')
  else if (line.includes('- [x]')) lines[lineIndex] = line.replace('- [x]', '- [ ]')
  else return body
  return lines.join('\n')
}

export const checklistProgress = (body: string) => {
  const tasks = body.match(/^\s*- \[[ xX]\]/gm) ?? []
  const done = body.match(/^\s*- \[[xX]\]/gm) ?? []
  return { total: tasks.length, done: done.length }
}

export const wordCount = (text: string) => {
  const words = text.trim().match(/\S+/g)
  return words ? words.length : 0
}

export const cardBodyPreview = (body: string, preview = '') => {
  const text = (body || preview || '').trim()
  return text.replace(/^#+\s+/gm, '').trim()
}

export const highlightSegments = (text: string, query: string) => {
  const q = query.trim()
  if (!q) return [{ text, match: false }]
  const escaped = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const splitter = new RegExp(`(${escaped})`, 'ig')
  return text.split(splitter).filter(Boolean).map((part) => ({
    text: part,
    match: part.toLowerCase() === q.toLowerCase(),
  }))
}
