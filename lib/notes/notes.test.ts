import assert from 'node:assert/strict'
import test from 'node:test'
import {
  applyTemplate,
} from './templates.ts'
import { cardBodyPreview, checklistProgress, highlightSegments, insertChecklist, insertImageMarkdown, parseMarkdown, toggleTaskLine, wordCount } from './markdown.ts'
import { createNotebook } from './notebooks.ts'
import { createSampleNotes } from './seed.ts'
import { exportNotesJson, exportNotesMarkdown, importNotesJson, parseNoteIdFromSearch, sharePath } from './export.ts'
import { formatNoteTimestamp, isDueToday, isOverdue } from './dates.ts'
import { moveNote, restoreFromTrash, restoreNote, trashNote, uniqueLabels, uniqueNotebooks, uniqueTags, upcomingReminders, visibleNotes } from './filters.ts'
import { NOTE_COLORS, randomNoteColor } from './types.ts'
import { normalizeNote } from './normalize.ts'

test('normalize maps job-card fields onto note fields', () => {
  const note = normalizeNote({
    amount: 'Work',
    author: 'Buy milk',
    institute: 'Journal',
    title: 'Groceries',
  }, 0, 'ada@notes.dev')
  assert.equal(note.tag, 'Work')
  assert.equal(note.preview, 'Buy milk')
  assert.equal(note.notebook, 'Journal')
  assert.equal(note.notebookId, 'journal')
  assert.equal(note.ownerEmail, 'ada@notes.dev')
  assert.equal(NOTE_COLORS.includes(note.color as typeof NOTE_COLORS[number]), true)
  assert.equal(note.body, '')
  assert.equal(note.pinned, false)
  assert.equal(note.archived, false)
  assert.equal(note.trashedAt, null)
})

test('sample notes are personal, pastel, and few', () => {
  const notes = createSampleNotes('ada@notes.dev')
  assert.ok(notes.length >= 6 && notes.length <= 8)
  assert.equal(notes[0].pinned, true)
  assert.ok(notes.every((note) => note.ownerEmail === 'ada@notes.dev'))
  assert.ok(notes.some((note) => note.dueAt))
  assert.ok(notes.some((note) => NOTE_COLORS.includes(note.color as typeof NOTE_COLORS[number])))
})

test('timestamp, preview, and random pastel color', () => {
  const stamp = formatNoteTimestamp(Date.parse('2026-09-01T22:30:00'))
  assert.match(stamp, /PM/)
  assert.match(stamp, /Tuesday|Monday|Wednesday|Thursday|Friday|Saturday|Sunday/)
  assert.equal(cardBodyPreview('## Hello\nWorld', 'fallback'), 'Hello\nWorld')
  assert.equal(NOTE_COLORS.includes(randomNoteColor()), true)
})

test('word count ignores extra whitespace', () => {
  assert.equal(wordCount('  hello   markdown world  '), 3)
  assert.equal(wordCount(''), 0)
})

test('due date helpers', () => {
  assert.equal(isDueToday('2026-09-01', '2026-09-01'), true)
  assert.equal(isDueToday('2026-09-02', '2026-09-01'), false)
  assert.equal(isOverdue('2026-08-31', '2026-09-01'), true)
  assert.equal(isOverdue(null, '2026-09-01'), false)
})

test('templates fill note-shaped content', () => {
  const meeting = applyTemplate('meeting')
  assert.match(meeting.body, /- \[ \]/)
  assert.equal(meeting.notebook, 'Work')
  const daily = applyTemplate('daily', new Date('2026-09-01T12:00:00'))
  assert.match(daily.title, /2026-09-01/)
})

test('checklist and image inserts', () => {
  assert.equal(insertChecklist(''), '- [ ] ')
  assert.equal(insertChecklist('Hello'), 'Hello\n- [ ] ')
  assert.equal(insertImageMarkdown('Body', 'data:image/png;base64,abc'), 'Body\n\n![image](data:image/png;base64,abc)')
})

test('toggle markdown task lines and progress', () => {
  const body = 'Intro\n- [ ] Write tests\n- [x] Done'
  assert.equal(toggleTaskLine(body, 1), 'Intro\n- [x] Write tests\n- [x] Done')
  assert.equal(toggleTaskLine(body, 2), 'Intro\n- [ ] Write tests\n- [ ] Done')
  assert.equal(toggleTaskLine(body, 0), body)
  assert.deepEqual(checklistProgress(body), { total: 2, done: 1 })
})

test('share link parsing', () => {
  assert.equal(parseNoteIdFromSearch('?note=42'), 42)
  assert.equal(parseNoteIdFromSearch('note=42'), 42)
  assert.equal(parseNoteIdFromSearch('?foo=1'), null)
  assert.equal(sharePath(42), '?note=42')
})

test('export and import json merge without id clashes', () => {
  const existing = [normalizeNote({ id: 1, title: 'Keep me' }, 0, 'ada@notes.dev')]
  const raw = exportNotesJson([normalizeNote({ id: 1, title: 'Imported' }, 0, 'ada@notes.dev')])
  const merged = importNotesJson(raw, existing, 'ada@notes.dev')
  assert.equal(merged.length, 2)
  assert.equal(merged[0].title, 'Keep me')
  assert.notEqual(merged[1].id, 1)
  const markdown = exportNotesMarkdown(existing)
  assert.match(markdown, /# Keep me/)
})

test('notebooks and tags ignore archived and trash', () => {
  const notes = [
    normalizeNote({ notebook: 'Work', tag: 'Focus', labels: ['work'] }, 0),
    normalizeNote({ notebook: 'Journal', tag: 'Daily', archived: true }, 1),
    normalizeNote({ notebook: 'Ideas', tag: 'Spark', trashedAt: 1 }, 2),
  ]
  assert.deepEqual(uniqueNotebooks(notes), ['Work'])
  assert.deepEqual(uniqueTags(notes), ['Focus'])
  assert.deepEqual(uniqueLabels(notes), ['work'])
})

test('undo restore puts a note back', () => {
  const note = normalizeNote({ id: 9, title: 'Gone' }, 0)
  const restored = restoreNote([], note)
  assert.equal(restored[0].id, 9)
  assert.equal(restoreNote(restored, note).length, 1)
})

test('trash and restore from trash', () => {
  const note = normalizeNote({ id: 4, title: 'Bin', pinned: true }, 0)
  const trashed = trashNote(note, 100)
  assert.equal(trashed.trashedAt, 100)
  assert.equal(trashed.pinned, false)
  assert.equal(restoreFromTrash(trashed, 200).trashedAt, null)
})

test('drag reorder updates order', () => {
  const notes = [
    normalizeNote({ id: 1, title: 'A', order: 0 }, 0),
    normalizeNote({ id: 2, title: 'B', order: 1 }, 1),
    normalizeNote({ id: 3, title: 'C', order: 2 }, 2),
  ]
  const moved = moveNote(notes, 3, 1)
  assert.deepEqual(moved.map((note) => note.id), [3, 1, 2])
  assert.deepEqual(moved.map((note) => note.order), [0, 1, 2])
})

test('visible notes pin, filter, search, hide archived, and isolate trash', () => {
  const notes = [
    normalizeNote({ id: 1, title: 'Alpha', tag: 'Work', pinned: true, createdAt: 2, ownerEmail: 'ada@notes.dev' }, 0, 'ada@notes.dev'),
    normalizeNote({ id: 2, title: 'Beta', tag: 'Home', confirmed: true, createdAt: 3, ownerEmail: 'ada@notes.dev' }, 1, 'ada@notes.dev'),
    normalizeNote({ id: 3, title: 'Gamma', archived: true, createdAt: 4, ownerEmail: 'ada@notes.dev' }, 2, 'ada@notes.dev'),
    normalizeNote({ id: 4, title: 'Due one', dueAt: '2026-09-01', createdAt: 1, ownerEmail: 'ada@notes.dev' }, 3, 'ada@notes.dev'),
    normalizeNote({ id: 5, title: 'Gone', trashedAt: 9, createdAt: 5, ownerEmail: 'ada@notes.dev' }, 4, 'ada@notes.dev'),
    normalizeNote({ id: 6, title: 'Other person', createdAt: 6, ownerEmail: 'other@notes.dev' }, 5, 'other@notes.dev'),
  ]

  const all = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'all',
    notebookId: null,
    tag: null,
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(all.map((note) => note.id), [1, 2, 4])

  const done = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'done',
    notebookId: null,
    tag: null,
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(done.map((note) => note.id), [2])

  const due = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'due',
    notebookId: null,
    tag: null,
    today: '2026-09-01',
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(due.map((note) => note.id), [4])

  const archived = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'archived',
    notebookId: null,
    tag: null,
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(archived.map((note) => note.id), [3])

  const trash = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'trash',
    notebookId: null,
    tag: null,
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(trash.map((note) => note.id), [5])

  const searched = visibleNotes({
    notes,
    search: 'alpha',
    sortKey: 'title',
    filterKey: 'all',
    notebookId: null,
    tag: null,
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(searched.map((note) => note.id), [1])
})

test('markdown parser reads headings, tasks, and images', () => {
  const blocks = parseMarkdown('# Hello\n- [x] Ship it\n![cat](http://img)\nA line')
  assert.equal(blocks[0].type, 'heading')
  assert.equal(blocks[1].type, 'task')
  if (blocks[1].type === 'task') assert.equal(blocks[1].checked, true)
  assert.equal(blocks[2].type, 'image')
  assert.equal(blocks[3].type, 'paragraph')
})

test('search highlight splits matching segments', () => {
  const parts = highlightSegments('Buy milk today', 'milk')
  assert.ok(parts.some((part) => part.match && part.text.toLowerCase() === 'milk'))
})

test('notebooks can be created with a cover color', () => {
  const notebook = createNotebook('ada@notes.dev', 'Travel', '#CDE0E8', 10)
  assert.equal(notebook.name, 'Travel')
  assert.equal(notebook.color, '#CDE0E8')
  assert.match(notebook.id, /travel-/)
})

test('upcoming reminders surface due notes', () => {
  const notes = [
    normalizeNote({ id: 1, title: 'Now', dueAt: '2026-09-01' }, 0),
    normalizeNote({ id: 2, title: 'Later', dueAt: '2026-09-20' }, 1),
  ]
  assert.deepEqual(upcomingReminders(notes, '2026-09-01').map((note) => note.id), [1])
})
