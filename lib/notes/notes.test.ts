import assert from 'node:assert/strict'
import test from 'node:test'
import { applyTemplate, dailyNoteTitle, findDailyNote, templateFromSaved } from './templates.ts'
import { cardBodyPreview, checklistProgress, highlightSegments, insertChecklist, insertImageMarkdown, parseMarkdown, toggleTaskLine, wordCount } from './markdown.ts'
import { createNotebook } from './notebooks.ts'
import { createSampleNotes } from './seed.ts'
import { exportNotesJson, exportNotesMarkdown, importNotesJson, parseNoteIdFromSearch, sharePath } from './export.ts'
import { formatNoteTimestamp, isDueToday, isOverdue } from './dates.ts'
import { formatDueChip, reminderFields, reminderFireDate } from './reminders.ts'
import { moveNote, restoreFromTrash, restoreNote, trashNote, uniqueColors, uniqueLabels, uniqueNotebooks, uniqueTags, upcomingReminders, visibleNotes } from './filters.ts'
import { NOTE_COLORS, randomNoteColor } from './types.ts'
import { belongsToOwner, normalizeNote } from './normalize.ts'
import { LABEL_PRESETS, labelTint } from './labels.ts'
import { backlinksTo, findNoteByTitle, insertWikiLink, parseWikiLinks, wikiSegments } from './backlinks.ts'
import { blobMarkdownSrc, collectBlobIds, dataUrlToBlob } from './blobs.ts'
import { compactMutations, formatBytes, shouldEnqueue } from './queue.ts'
import { isolateBundle, isolateNotes } from './isolation.ts'

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
  assert.ok(notes.every((note) => note.labels.length > 0))
  assert.ok(notes.some((note) => note.body.includes('[[Quotes]]')))
  assert.ok(notes.some((note) => note.body.includes('[[Book ideas]]')))
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

test('calendar reminders fire before a timed event', () => {
  const lastWeek = Date.parse('2026-08-20T00:00:00')
  const tenBefore = reminderFireDate('2026-09-02', '15:00', 10, lastWeek)
  assert.equal(tenBefore?.getHours(), 14)
  assert.equal(tenBefore?.getMinutes(), 50)
  const allDay = reminderFireDate('2026-09-02', null, 0, lastWeek)
  assert.equal(allDay?.getHours(), 9)
  assert.equal(allDay?.getMinutes(), 0)
  const dayBefore = reminderFireDate('2026-09-02', '09:00', 1440, lastWeek)
  assert.equal(dayBefore?.getDate(), 1)
  assert.equal(reminderFireDate('2026-09-02', '15:00', -1, lastWeek), null)
  const fields = reminderFields({ dueAt: '2026-09-15', dueTime: '18:00', alertMinutes: 60 })
  assert.equal(fields.remindAt, '2026-09-15T17:00')
  assert.equal(formatDueChip('2026-09-15', '18:00', '2026-09-02'), 'Sep 15 · 6:00 PM')
})

test('saved templates keep labels and color', () => {
  const saved = templateFromSaved({
    id: 'tpl-1',
    ownerEmail: 'ada@notes.dev',
    name: 'Weekly recap',
    title: 'Weekly recap',
    tag: 'Work',
    notebookId: 'work',
    body: '- [ ] Ship notes',
    color: '#CDE0E8',
    labels: ['Work'],
    dueAt: '2026-09-08',
    createdAt: 1,
  })
  assert.equal(saved.color, '#CDE0E8')
  assert.deepEqual(saved.labels, ['Work'])
  assert.equal(saved.dueAt, '2026-09-08')
})

test('label and color filters keep the board personal', () => {
  const notes = [
    normalizeNote({ id: 1, title: 'Green', color: '#D9E8A8', labels: ['Work'] }, 0, 'ada@notes.dev'),
    normalizeNote({ id: 2, title: 'Pink', color: '#F9A8B6', labels: ['Life'] }, 1, 'ada@notes.dev'),
  ]
  const byLabel = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'all',
    notebookId: null,
    tag: null,
    label: 'Work',
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(byLabel.map((note) => note.id), [1])
  const byColor = visibleNotes({
    notes,
    search: '',
    sortKey: 'newest',
    filterKey: 'all',
    notebookId: null,
    tag: null,
    color: '#F9A8B6',
    ownerEmail: 'ada@notes.dev',
  })
  assert.deepEqual(byColor.map((note) => note.id), [2])
  assert.deepEqual(uniqueLabels(notes), ['Life', 'Work'])
  assert.ok(uniqueColors(notes).includes('#D9E8A8'))
  assert.ok(LABEL_PRESETS.includes('Work'))
  assert.equal(NOTE_COLORS.includes(labelTint('Work') as typeof NOTE_COLORS[number]), true)
})

test('wiki links parse, insert, and resolve backlinks', () => {
  const quotes = normalizeNote({ id: 1, title: 'Quotes', body: 'Hello' }, 0, 'ada@notes.dev')
  const ideas = normalizeNote({ id: 2, title: 'Book ideas', body: 'See [[Quotes]] and [[Missing]]' }, 1, 'ada@notes.dev')
  assert.deepEqual(parseWikiLinks(ideas.body), ['Quotes', 'Missing'])
  assert.equal(findNoteByTitle([quotes, ideas], 'quotes')?.id, 1)
  assert.deepEqual(backlinksTo(quotes, [quotes, ideas]).map((note) => note.id), [2])
  assert.equal(insertWikiLink('Hello', 'Quotes'), 'Hello [[Quotes]]')
  assert.deepEqual(wikiSegments('See [[Quotes]] now').map((part) => part.link), [null, 'Quotes', null])
})

test('blob refs stay out of the note document', () => {
  const note = normalizeNote({
    id: 9,
    title: 'Photo',
    body: `![cat](${blobMarkdownSrc('att-9-1')})`,
    attachments: [{ id: 'att-9-2', name: 'scan.pdf', mime: 'application/pdf', createdAt: 1 }],
  }, 0, 'ada@notes.dev')
  assert.deepEqual(collectBlobIds(note).sort(), ['att-9-1', 'att-9-2'])
  const blob = dataUrlToBlob('data:text/plain;base64,aGk=')
  assert.equal(blob.type, 'text/plain')
  assert.equal(cardBodyPreview(note.body), '')
})

test('daily note is found by today title', () => {
  const title = dailyNoteTitle(new Date('2026-09-02T12:00:00'))
  const notes = [normalizeNote({ id: 3, title, body: 'Wins' }, 0, 'ada@notes.dev')]
  assert.equal(findDailyNote(notes, new Date('2026-09-02T18:00:00'))?.id, 3)
  assert.equal(findDailyNote(notes, new Date('2026-09-01T18:00:00')), null)
})

test('accounts never mix notes across emails', () => {
  const mixed = [
    normalizeNote({ id: 1, title: 'Ada', ownerEmail: 'ada@notes.dev' }, 0, 'ada@notes.dev'),
    normalizeNote({ id: 2, title: 'Sam', ownerEmail: 'sam@notes.dev' }, 1, 'sam@notes.dev'),
  ]
  assert.deepEqual(isolateNotes(mixed, 'ada@notes.dev').map((note) => note.id), [1])
  assert.equal(belongsToOwner(mixed[1], 'ada@notes.dev'), false)
  const bundle = isolateBundle({
    notes: mixed,
    notebooks: [
      { id: 'inbox', ownerEmail: 'ada@notes.dev', name: 'Inbox', color: '#F9D368', createdAt: 1 },
      { id: 'other', ownerEmail: 'sam@notes.dev', name: 'Other', color: '#F9A8B6', createdAt: 2 },
    ],
    templates: [],
    recents: ['milk'],
  }, 'ada@notes.dev')
  assert.deepEqual(bundle.notebooks.map((item) => item.id), ['inbox'])
})

test('mutation queue ignores noise and keeps last write', () => {
  assert.equal(shouldEnqueue('account.opened'), false)
  assert.equal(shouldEnqueue('note.saved'), true)
  const queued = compactMutations([
    { ownerEmail: 'ada@notes.dev', kind: 'account.opened', payload: {}, createdAt: 1, synced: 0, id: 1 },
    { ownerEmail: 'ada@notes.dev', kind: 'note.saved', payload: { id: 9 }, createdAt: 2, synced: 0, id: 2 },
    { ownerEmail: 'ada@notes.dev', kind: 'note.saved', payload: { id: 9 }, createdAt: 3, synced: 0, id: 3 },
    { ownerEmail: 'ada@notes.dev', kind: 'note.deleted', payload: { id: 9 }, createdAt: 4, synced: 0, id: 4 },
  ])
  assert.deepEqual(queued.map((item) => item.kind), ['note.deleted'])
  assert.equal(formatBytes(2048), '2 KB')
})
