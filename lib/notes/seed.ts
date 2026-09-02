import { todayISO } from './dates.ts'
import { normalizeNote } from './normalize.ts'
import type { Note } from './types.ts'

export const createSampleNotes = (ownerEmail: string, now = Date.now()): Note[] => {
  const hour = 60 * 60 * 1000
  const day = 24 * hour
  const today = todayISO(new Date(now))

  const seeds: Array<Partial<Note> & { title: string; body: string }> = [
    {
      title: 'Today',
      tag: 'Priority',
      notebook: 'Inbox',
      notebookId: 'inbox',
      color: '#D9E8A8',
      body: '- [ ] Finish the afternoon walkthrough\n- [ ] Call the dentist\n- [x] Water the fern',
      pinned: true,
      labels: ['today'],
    },
    {
      title: 'Weekend plans',
      tag: 'Life',
      notebook: 'Personal',
      notebookId: 'personal',
      color: '#F9A8B6',
      body: 'Saturday: morning hike at Eagle Peak.\nSunday: farmers market and a slow lunch.',
      labels: ['life'],
    },
    {
      title: 'To-do list',
      tag: 'Tasks',
      notebook: 'Inbox',
      notebookId: 'inbox',
      color: '#CDE0E8',
      body: '- [ ] Buy groceries\n- [x] Send the weekly recap\n- [ ] Schedule car service\n- [ ] Read chapter 4',
      dueAt: today,
      remindAt: today,
      labels: ['tasks'],
    },
    {
      title: 'Book ideas',
      tag: 'Ideas',
      notebook: 'Ideas',
      notebookId: 'ideas',
      color: '#F9B384',
      body: 'A city where memories are traded like currency.\nOpening scene: a rainy bus stop, two strangers, one ticket.',
      pinned: true,
      labels: ['writing'],
    },
    {
      title: 'Pasta night',
      tag: 'Food',
      notebook: 'Journal',
      notebookId: 'journal',
      color: '#F9D368',
      body: 'Garlic, olive oil, chili flakes, parsley.\nToss spaghetti al dente. Finish with lemon zest.',
      labels: ['kitchen'],
    },
    {
      title: 'Gift list',
      tag: 'Shopping',
      notebook: 'Personal',
      notebookId: 'personal',
      color: '#D4C4F0',
      body: '• Mom — scarf\n• Dad — cookbook\n• Sister — wireless earbuds',
      dueAt: '2026-09-15',
      remindAt: '2026-09-15',
      labels: ['family'],
    },
    {
      title: 'Quotes',
      tag: 'Inspiration',
      notebook: 'Ideas',
      notebookId: 'ideas',
      color: '#B8E0D2',
      body: '"The secret of getting ahead is getting started." — Mark Twain\n\nSmall steps every day.',
    },
    {
      title: 'Morning routine',
      tag: 'Daily',
      notebook: 'Journal',
      notebookId: 'journal',
      color: '#D9E8A8',
      body: 'Wake 6:30 · Stretch 10 min · Journal 5 min · No phone until breakfast.',
      confirmed: true,
      labels: ['habits'],
    },
  ]

  return seeds.map((item, index) =>
    normalizeNote(
      {
        ...item,
        ownerEmail,
        id: 10_000 + index,
        preview: item.body.slice(0, 80),
        createdAt: now - index * (day * 0.4) - index * hour,
        order: index,
      },
      index,
      ownerEmail
    )
  )
}
