import { todayISO } from './dates.ts'
import { normalizeNote } from './normalize.ts'
import { NOTE_COLORS, type Note } from './types.ts'

const cover = (svg: string) => `data:image/svg+xml,${encodeURIComponent(svg)}`

const WEEKEND_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#E8B4BE" width="360" height="180"/><circle fill="#F6E3A1" cx="292" cy="44" r="30"/><path fill="#7BA17A" d="M0 118 Q90 72 180 118 T360 118 V180 H0Z"/><path fill="#5E8A62" d="M40 180 L110 92 L180 180Z"/></svg>`)
const PASTA_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#E8C56B" width="360" height="180"/><ellipse fill="#F4D78C" cx="180" cy="108" rx="118" ry="46"/><path fill="#D9A24A" d="M80 96 q40 28 80 0 q40 24 80 0 q-10 38-80 42 q-70-4-80-42z"/><circle fill="#C45C3E" cx="156" cy="100" r="7"/><circle fill="#2F6B3A" cx="204" cy="108" r="6"/></svg>`)
const TEA_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#BEC3BC" width="360" height="180"/><ellipse fill="#F3EEE4" cx="180" cy="120" rx="70" ry="18"/><path fill="#E8D5B5" d="M145 88 h70 a18 18 0 0 1 0 36 h-70a18 18 0 0 1 0-36z"/><circle fill="#C9A36A" cx="180" cy="106" r="14"/><path fill="#B8C9C4" d="M230 100 h18 a12 12 0 0 1 0 24 h-8"/></svg>`)
const RAIN_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#9BB7C8" width="360" height="180"/><ellipse fill="#D4C4E8" cx="90" cy="52" rx="54" ry="22"/><ellipse fill="#E8E4F2" cx="130" cy="58" rx="40" ry="16"/><path stroke="#E8F1F6" stroke-width="3" d="M70 90 l-6 28 M110 96 l-8 32 M160 88 l-7 30 M220 70 l-6 26 M280 84 l-8 34"/></svg>`)
const DESK_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#C5CA8A" width="360" height="180"/><rect fill="#F4F0E6" x="70" y="48" width="160" height="100" rx="8"/><rect fill="#BEC3BC" x="250" y="64" width="54" height="72" rx="6"/><circle fill="#E7A3A3" cx="120" cy="88" r="10"/></svg>`)
const NIGHT_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#2C3550" width="360" height="180"/><circle fill="#F6E3A1" cx="70" cy="46" r="16"/><circle fill="#F4F0E6" cx="140" cy="30" r="2"/><circle fill="#F4F0E6" cx="210" cy="50" r="1.5"/><circle fill="#F4F0E6" cx="280" cy="28" r="2"/><circle fill="#F4F0E6" cx="320" cy="70" r="1.5"/><path fill="#1B2236" d="M0 120 Q90 90 180 120 T360 120 V180 H0Z"/></svg>`)
const MARKET_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#E89569" width="360" height="180"/><rect fill="#E07A5F" x="40" y="70" width="70" height="80"/><rect fill="#F2CC8F" x="120" y="50" width="80" height="100"/><rect fill="#81B29A" x="210" y="64" width="70" height="86"/><rect fill="#3D405B" x="290" y="80" width="40" height="70"/><ellipse fill="#F4F0E6" cx="180" cy="40" rx="90" ry="16"/></svg>`)
const PLANT_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#A9D4C4" width="360" height="180"/><ellipse fill="#7BA17A" cx="180" cy="70" rx="40" ry="54"/><ellipse fill="#5E8A62" cx="148" cy="88" rx="22" ry="36"/><ellipse fill="#5E8A62" cx="214" cy="88" rx="22" ry="36"/><rect fill="#C45C3E" x="164" y="118" width="32" height="40" rx="4"/><ellipse fill="#E8D5B5" cx="180" cy="164" rx="70" ry="10"/></svg>`)
const SOUP_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#E8C44A" width="360" height="180"/><ellipse fill="#E07A5F" cx="180" cy="110" rx="90" ry="36"/><ellipse fill="#C45C3E" cx="180" cy="104" rx="70" ry="24"/><path fill="#F4F0E6" d="M250 86 h28 v8 h-8 v28 h-12 v-28 h-8z"/><circle fill="#C5CA8A" cx="160" cy="100" r="6"/><circle fill="#E7A3A3" cx="196" cy="108" r="5"/></svg>`)
const LIBRARY_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#D4C4E8" width="360" height="180"/><rect fill="#C45C3E" x="50" y="40" width="28" height="110"/><rect fill="#3D405B" x="86" y="50" width="24" height="100"/><rect fill="#E07A5F" x="118" y="36" width="32" height="114"/><rect fill="#81B29A" x="158" y="58" width="22" height="92"/><rect fill="#F2CC8F" x="188" y="44" width="30" height="106"/><rect fill="#BEC3BC" x="226" y="62" width="26" height="88"/><rect fill="#E7A3A3" x="260" y="40" width="34" height="110"/></svg>`)
const BIKE_COVER = cover(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 180"><rect fill="#BEC3BC" width="360" height="180"/><circle fill="none" stroke="#3D405B" stroke-width="6" cx="110" cy="120" r="34"/><circle fill="none" stroke="#3D405B" stroke-width="6" cx="250" cy="120" r="34"/><path fill="none" stroke="#3D405B" stroke-width="6" d="M110 120 L170 70 L250 120 M170 70 L150 120 M170 70 L200 70"/></svg>`)

const BOOKS = {
  inbox: { notebook: 'Inbox', notebookId: 'inbox' },
  work: { notebook: 'Work', notebookId: 'work' },
  journal: { notebook: 'Journal', notebookId: 'journal' },
  ideas: { notebook: 'Ideas', notebookId: 'ideas' },
  personal: { notebook: 'Personal', notebookId: 'personal' },
} as const

type BookKey = keyof typeof BOOKS

type SampleDraft = Partial<Note> & { title: string; body: string }

const colorAt = (index: number) => NOTE_COLORS[index % NOTE_COLORS.length]

const featured = (today: string): SampleDraft[] => [
  {
    title: 'Today',
    tag: 'Priority',
    ...BOOKS.inbox,
    color: '#C5CA8A',
    body: '- [ ] Finish the afternoon walkthrough\n- [ ] Call the dentist\n- [x] Water the fern\n- [ ] Pack the charger',
    pinned: true,
    labels: ['Today'],
  },
  {
    title: 'Weekend plans',
    tag: 'Life',
    ...BOOKS.personal,
    color: '#E7A3A3',
    body: `![Morning hike](${WEEKEND_COVER})\n\nSaturday: morning hike at Eagle Peak.\nSunday: farmers market and a slow lunch.`,
    labels: ['Personal'],
  },
  {
    title: 'To-do list',
    tag: 'Tasks',
    ...BOOKS.inbox,
    color: '#BEC3BC',
    body: '- [ ] Buy groceries\n- [x] Send the weekly recap\n- [ ] Schedule car service\n- [ ] Read chapter 4\n- [ ] Return the library books',
    dueAt: today,
    dueTime: '21:00',
    alertMinutes: 10,
    labels: ['Tasks'],
  },
  {
    title: 'Book ideas',
    tag: 'Ideas',
    ...BOOKS.ideas,
    color: '#E89569',
    body: 'A city where memories are traded like currency.\nOpening scene: a rainy bus stop, two strangers, one ticket.\n\nSee [[Quotes]].',
    pinned: true,
    labels: ['Ideas'],
  },
  {
    title: 'Pasta night',
    tag: 'Food',
    ...BOOKS.journal,
    color: '#E8C44A',
    body: `![Pasta](${PASTA_COVER})\n\nGarlic, olive oil, chili flakes, parsley.\nToss spaghetti al dente. Finish with lemon zest.`,
    labels: ['Home'],
  },
  {
    title: 'Gift list',
    tag: 'Shopping',
    ...BOOKS.personal,
    color: '#D4C4E8',
    body: '• Mom — scarf\n• Dad — cookbook\n• Sister — wireless earbuds\n• House — a good candle',
    dueAt: '2026-09-15',
    dueTime: '18:00',
    alertMinutes: 60,
    labels: ['Personal'],
  },
  {
    title: 'Quotes',
    tag: 'Inspiration',
    ...BOOKS.ideas,
    color: '#A9D4C4',
    body: '"The secret of getting ahead is getting started." — Mark Twain\n\nSmall steps every day.\n\nFrom [[Book ideas]].',
    labels: ['Ideas'],
  },
  {
    title: 'Morning routine',
    tag: 'Daily',
    ...BOOKS.journal,
    color: '#C5CA8A',
    body: 'Wake 6:30 · Stretch 10 min · Journal 5 min · No phone until breakfast.\nThen open today\'s log.',
    confirmed: true,
    labels: ['Today'],
  },
  {
    title: 'Milk',
    tag: 'Errand',
    ...BOOKS.inbox,
    color: '#BEC3BC',
    body: 'Oat milk. The blue carton.',
    labels: ['Tasks'],
  },
  {
    title: 'Monday standup',
    tag: 'Work',
    ...BOOKS.work,
    color: '#BEC3BC',
    body: '## Today\n\n- [x] Ship the reminder polish\n- [ ] Review the login copy\n- [ ] Ping design about empty states\n\n## Blockers\n\nNone. Keep it quiet.',
    labels: ['Work'],
  },
  {
    title: 'Rainy evening',
    tag: 'Journal',
    ...BOOKS.journal,
    color: '#D4C4E8',
    body: `![Rain](${RAIN_COVER})\n\nThe window fogged. Made tea. Wrote two pages and did not open the other app.`,
    labels: ['Personal'],
  },
  {
    title: 'Masala chai',
    tag: 'Food',
    ...BOOKS.journal,
    color: '#E89569',
    body: `![Chai](${TEA_COVER})\n\nCrush cardamom, ginger, a clove.\nSimmer with milk. No rush.`,
    labels: ['Home'],
  },
  {
    title: 'Desk reset',
    tag: 'Home',
    ...BOOKS.personal,
    color: '#C5CA8A',
    body: `![Desk](${DESK_COVER})\n\n- [ ] Clear the cables\n- [ ] One plant, one lamp\n- [x] Put the pens back`,
    labels: ['Home'],
  },
  {
    title: 'Goa packing',
    tag: 'Travel',
    ...BOOKS.personal,
    color: '#E7A3A3',
    body: '- [ ] Swimsuit\n- [ ] Sunscreen\n- [ ] Paperback\n- [ ] Charger\n- [ ] That linen shirt',
    dueAt: '2026-10-03',
    dueTime: '08:00',
    alertMinutes: 1440,
    labels: ['Personal'],
  },
  {
    title: 'Movies to watch',
    tag: 'Life',
    ...BOOKS.ideas,
    color: '#E8C44A',
    body: 'Perfect Days\nThe Lunchbox\nAftersun\nPast Lives',
    labels: ['Ideas'],
  },
  {
    title: 'Tiny win',
    tag: 'Daily',
    ...BOOKS.journal,
    color: '#A9D4C4',
    body: 'Left the house without the phone for a walk. That was the day.',
    labels: ['Today'],
  },
  {
    title: 'Meeting with Ama',
    tag: 'Work',
    ...BOOKS.work,
    color: '#E89569',
    body: '## Agenda\n\n- [ ] Show the paper board\n- [ ] Decide Grid vs Masonry as default\n\n## Notes\n\nShe liked the quiet editor. Keep Details tucked away.',
    labels: ['Work'],
  },
  {
    title: 'Groceries',
    tag: 'Tasks',
    ...BOOKS.inbox,
    color: '#A9D4C4',
    body: '- [ ] Tomatoes\n- [ ] Curd\n- [ ] Bananas\n- [x] Coffee\n- [ ] Bread',
    labels: ['Tasks'],
  },
]

const extras = (today: string): SampleDraft[] => {
  const rows: Array<{
    title: string
    body: string
    tag: string
    book: BookKey
    labels: string[]
    dueAt?: string
    dueTime?: string
    alertMinutes?: number
    pinned?: boolean
    confirmed?: boolean
  }> = [
    { title: 'Keys', body: 'On the hook by the door. Not in the jacket.', tag: 'Errand', book: 'inbox', labels: ['Tasks'] },
    { title: 'Wifi', body: 'Guest network: paperhouse\nPassword in the kitchen drawer.', tag: 'Home', book: 'personal', labels: ['Home'] },
    { title: 'Call Maya', body: 'Ask about Saturday. She mentioned the new bakery.', tag: 'People', book: 'inbox', labels: ['Today'], dueAt: today, dueTime: '18:30', alertMinutes: 30 },
    { title: 'Pharmacy', body: '- [ ] Vitamins\n- [ ] Bandages\n- [x] Toothpaste', tag: 'Errand', book: 'inbox', labels: ['Tasks'] },
    { title: 'Dry cleaners', body: 'Blue shirt and the grey coat. Ticket is in the wallet.', tag: 'Errand', book: 'inbox', labels: ['Tasks'], dueAt: '2026-09-04', dueTime: '17:00', alertMinutes: 60 },
    { title: 'Water bill', body: 'Due Friday. Pay before leaving for the weekend.', tag: 'Bills', book: 'inbox', labels: ['Tasks'], dueAt: '2026-09-05', dueTime: '10:00', alertMinutes: 1440 },
    { title: 'Password reset', body: 'Do the bank one from the laptop, not the phone.', tag: 'Admin', book: 'inbox', labels: ['Tasks'], confirmed: true },
    { title: 'Lunch idea', body: 'Leftover rice, fried egg, chili oil, cucumber.', tag: 'Food', book: 'inbox', labels: ['Home'] },
    { title: 'Umbrella', body: 'It is going to rain after 4. Take the black one.', tag: 'Errand', book: 'inbox', labels: ['Today'] },
    { title: 'Return parcel', body: 'The shoes did not fit. Drop at the locker near the station.', tag: 'Errand', book: 'inbox', labels: ['Tasks'], dueAt: '2026-09-07', dueTime: '19:00', alertMinutes: 120 },
    { title: 'Weekly review', body: '## Keep\n\nQuiet evenings.\n\n## Drop\n\nLate email.\n\n## Next\n\nFinish the paper board polish.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Hiring notes', body: 'Look for someone who writes clearly and ships small.\nNo jargon in the interview.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Copy tweaks', body: '- [ ] Empty state: Write your first note\n- [ ] Offline banner shorter\n- [x] OTP screen title', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Design feedback', body: 'Cards should feel like paper, not tiles.\nKeep the tick. Lose the extra chrome.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Sprint goals', body: '1. Reminders that fire on the phone\n2. Board that packs tightly\n3. Editor that stays quiet', tag: 'Work', book: 'work', labels: ['Work'], pinned: true },
    { title: 'Retro', body: 'Went well: shipping in small slices.\nFix: too many toggles in the header.', tag: 'Work', book: 'work', labels: ['Work'], confirmed: true },
    { title: 'Invoice 184', body: 'Send before Thursday. Attach the hours log.', tag: 'Work', book: 'work', labels: ['Work'], dueAt: '2026-09-04', dueTime: '11:00', alertMinutes: 60 },
    { title: '1:1 with Dev', body: '## Talk about\n\n- [ ] Time off in October\n- [ ] The Android build\n- [ ] What to cut', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Office snacks', body: 'Almonds, dark chocolate, the good tea. Not the vending machine.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Read later', body: 'That article on local-first notes. Save the PDF to this note later.', tag: 'Work', book: 'work', labels: ['Ideas'] },
    { title: 'Bug list', body: '- [ ] Seed photos crashing load\n- [x] Tick toggle\n- [ ] Search overlay scroll on iOS', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Release checklist', body: '- [ ] Version bump\n- [ ] Screenshot the board\n- [ ] Play Store notes\n- [ ] Tag the commit', tag: 'Work', book: 'work', labels: ['Work'], dueAt: '2026-09-12', dueTime: '16:00', alertMinutes: 180 },
    { title: 'Tuesday log', body: 'Slept ok. Walked 20 minutes. Wrote before opening mail.', tag: 'Daily', book: 'journal', labels: ['Today'] },
    { title: 'Wednesday log', body: 'Too much coffee. The afternoon was better after a walk.', tag: 'Daily', book: 'journal', labels: ['Today'], confirmed: true },
    { title: 'Grateful', body: 'The open window. The cheap lunch. A message from home.', tag: 'Journal', book: 'journal', labels: ['Personal'] },
    { title: 'Night walk', body: `![Night](${NIGHT_COVER})\n\nStreetlights on wet leaves. Came home quieter than I left.`, tag: 'Journal', book: 'journal', labels: ['Personal'] },
    { title: 'Soup Sunday', body: `![Soup](${SOUP_COVER})\n\nOnion, carrot, tomato, a bay leaf.\nEat with toast. Freeze two boxes.`, tag: 'Food', book: 'journal', labels: ['Home'] },
    { title: 'Plant care', body: `![Plant](${PLANT_COVER})\n\nWater the pothos on Sunday. Rotate the fern. Do not overdo it.`, tag: 'Home', book: 'personal', labels: ['Home'] },
    { title: 'Dream scrap', body: 'A train that only stopped at libraries. I missed mine on purpose.', tag: 'Journal', book: 'journal', labels: ['Ideas'] },
    { title: 'Letter I will not send', body: 'I am proud of you. I should have said it in the kitchen.', tag: 'Journal', book: 'journal', labels: ['Personal'] },
    { title: 'Sleep', body: 'Lights out 10:30. Phone in the other room. Book on the chest.', tag: 'Daily', book: 'journal', labels: ['Today'] },
    { title: 'Mood', body: 'A little grey, not heavy. Music helped. Keep the evening empty.', tag: 'Journal', book: 'journal', labels: ['Personal'] },
    { title: 'Pages', body: 'Wrote 400 words. They are not good. They exist.', tag: 'Daily', book: 'journal', labels: ['Today'], confirmed: true },
    { title: 'Sunday market', body: `![Market](${MARKET_COVER})\n\nMangoes, coriander, too much cheese. Talked to the flower stall.`, tag: 'Life', book: 'personal', labels: ['Personal'] },
    { title: 'Library haul', body: `![Books](${LIBRARY_COVER})\n\nTwo novels, one cookbook, the architecture magazine I always skip.`, tag: 'Life', book: 'personal', labels: ['Personal'] },
    { title: 'Bike loop', body: `![Bike](${BIKE_COVER})\n\nAlong the river and back before lunch. 14 km, easy gear.`, tag: 'Life', book: 'personal', labels: ['Personal'] },
    { title: 'Birthday cake', body: 'Pistachio, not chocolate. Order Thursday or bake Friday night.', tag: 'Home', book: 'personal', labels: ['Home'], dueAt: '2026-09-18', dueTime: '12:00', alertMinutes: 1440 },
    { title: 'House chores', body: '- [ ] Sheets\n- [ ] Bathroom\n- [x] Trash\n- [ ] Plants\n- [ ] Vacuum the hallway', tag: 'Home', book: 'personal', labels: ['Home'] },
    { title: 'Rent reminder', body: 'Transfer on the 1st. Keep the note in Personal so it is not with work.', tag: 'Bills', book: 'personal', labels: ['Tasks'], dueAt: '2026-10-01', dueTime: '09:00', alertMinutes: 1440 },
    { title: 'Family dinner', body: 'Bring salad and the good pickles. Leave by 6:15.', tag: 'Life', book: 'personal', labels: ['Personal'], dueAt: '2026-09-06', dueTime: '18:15', alertMinutes: 60 },
    { title: 'Doctor', body: 'Annual checkup. Fasting bloodwork. Water is fine.', tag: 'Health', book: 'personal', labels: ['Tasks'], dueAt: '2026-09-22', dueTime: '08:40', alertMinutes: 720 },
    { title: 'Haircut', body: 'Ask for the usual. Do not let them talk you into layers.', tag: 'Life', book: 'personal', labels: ['Personal'], dueAt: '2026-09-11', dueTime: '16:00', alertMinutes: 120 },
    { title: 'Neighbours', body: 'Return the pan. Take a little cake as thanks.', tag: 'Life', book: 'personal', labels: ['Home'] },
    { title: 'Wardrobe', body: 'Donate the black sweater that pills. Keep the linen shirt.', tag: 'Home', book: 'personal', labels: ['Home'] },
    { title: 'Budget September', body: 'Groceries 8k. Transit 2k. Fun 3k. Buffer for the trip.', tag: 'Money', book: 'personal', labels: ['Tasks'] },
    { title: 'App ideas', body: 'A notebook that only holds one sentence a day.\nA map of walks with weather scribbled on it.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Essay spark', body: 'On keeping a room slightly messy on purpose.\nStart with the chair that is never empty.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Name list', body: 'Paperhouse\nQuiet Desk\nInk Room\nSecond Cup', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Podcast notes', body: 'Local-first means the device is the source of truth.\nSync is a gift, not a requirement.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Short story seed', body: 'She kept other people\'s reminders and never set her own.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Color palettes', body: 'Warm paper, ink brown, monsoon blue, festival pink.\nNo pure white.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Questions', body: 'What would I write if nobody saw it?\nWhat would I keep if the phone died?', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Games to try', body: 'A short puzzle game.\nSomething with no chat.', tag: 'Life', book: 'ideas', labels: ['Ideas'] },
    { title: 'Album rotation', body: '1. Arooj Aftab\n2. Punjabi folk mix\n3. That piano record from 2018', tag: 'Life', book: 'ideas', labels: ['Personal'] },
    { title: 'Recipe: khichdi', body: 'Moong dal, rice, turmeric, ghee, cumin.\nSoft. Ginger if the weather is wet.', tag: 'Food', book: 'journal', labels: ['Home'] },
    { title: 'Recipe: eggs', body: 'Butter, low heat, chives if they are not wilted.\nToast on the side, not under.', tag: 'Food', book: 'journal', labels: ['Home'] },
    { title: 'Coffee shops', body: 'The one with the bad chairs and the good light.\nNever the one near the office.', tag: 'Life', book: 'personal', labels: ['Personal'] },
    { title: 'Train times', body: 'Local 7:42. Fast 8:05 if I skip breakfast at home.', tag: 'Errand', book: 'inbox', labels: ['Today'] },
    { title: 'Pack for overnight', body: '- [ ] Charger\n- [ ] Book\n- [ ] Shirt\n- [ ] Toothbrush\n- [x] Ticket', tag: 'Travel', book: 'personal', labels: ['Personal'] },
    { title: 'Jaipur someday', body: 'Pink light in the late afternoon. A courtyard breakfast. No schedule.', tag: 'Travel', book: 'personal', labels: ['Personal'] },
    { title: 'Camera roll', body: 'Print the river photo. Delete the rest of the screenshots.', tag: 'Life', book: 'personal', labels: ['Personal'] },
    { title: 'Subscriptions', body: '- [ ] Cancel the one I forgot\n- [x] Keep music\n- [ ] Ask about family plan', tag: 'Money', book: 'inbox', labels: ['Tasks'] },
    { title: 'Dentist follow-up', body: 'Book the cleaning for October. Ask about the sensitive tooth.', tag: 'Health', book: 'personal', labels: ['Tasks'], dueAt: '2026-10-08', dueTime: '09:30', alertMinutes: 1440 },
    { title: 'Stretch', body: 'Hips and shoulders. Five minutes is still a stretch.', tag: 'Health', book: 'journal', labels: ['Today'] },
    { title: 'No-spend day', body: 'Cook what is in the fridge. Walk instead of a cafe.', tag: 'Money', book: 'inbox', labels: ['Today'], confirmed: true },
    { title: 'Meeting rooms', body: 'Book the small one. The glass room makes people perform.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Onboarding notes', body: 'Show them the board first, then the editor.\nDo not start with settings.', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Friday shutdown', body: '- [ ] Inbox to zero-ish\n- [ ] Write Monday\'s top 3\n- [x] Close the laptop before 7', tag: 'Work', book: 'work', labels: ['Work'] },
    { title: 'Thank-you note', body: 'Write to the teacher who mailed the book. Keep it short.', tag: 'People', book: 'inbox', labels: ['Personal'] },
    { title: 'Backup', body: 'Export JSON this month. Put it next to the photos backup.', tag: 'Admin', book: 'inbox', labels: ['Tasks'], dueAt: '2026-09-30', dueTime: '20:00', alertMinutes: 180 },
    { title: 'Rainy reading', body: 'Finish the novel on the chair by the window. Tea, not a screen.', tag: 'Life', book: 'journal', labels: ['Personal'] },
    { title: 'Open loops', body: '- [ ] Reply to Sam\n- [ ] Book tickets\n- [ ] Fix the leaky bottle\n- [ ] Print the form', tag: 'Tasks', book: 'inbox', labels: ['Tasks'] },
    { title: 'One sentence', body: 'I do not have to finish the day for the day to count.', tag: 'Daily', book: 'journal', labels: ['Today'] },
    { title: 'Shop list extra', body: '- [ ] Olive oil\n- [ ] Lemons\n- [ ] Yogurt\n- [ ] Rice\n- [ ] Ginger\n- [x] Salt', tag: 'Tasks', book: 'inbox', labels: ['Tasks'] },
    { title: 'Podcast guests', body: 'Someone who still writes on paper.\nSomeone who ships boring software well.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Wallpaper', body: 'A photo of a desk with one plant. No icons on the home screen.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Evening reset', body: 'Dishes, tomorrow\'s clothes, a glass of water by the bed.', tag: 'Daily', book: 'journal', labels: ['Home'] },
    { title: 'Win from last week', body: 'Shipped the reminders. Did not open the other notes app.', tag: 'Daily', book: 'journal', labels: ['Today'], confirmed: true },
    { title: 'Parking', body: 'The side street is free after 8. Not the one with the bakery.', tag: 'Errand', book: 'inbox', labels: ['Tasks'] },
    { title: 'Gift wrapping', body: 'Brown paper, twine, a sprig of something green. No plastic bows.', tag: 'Home', book: 'personal', labels: ['Home'] },
    { title: 'Language bits', body: 'raat — night\ndheere — slowly\nchup — quiet', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
    { title: 'Tea order', body: 'Assam for mornings. Something floral for late day. No dust tea.', tag: 'Food', book: 'personal', labels: ['Home'] },
    { title: 'Show ideas', body: 'A quiet documentary about shops that still wrap things in paper.', tag: 'Ideas', book: 'ideas', labels: ['Ideas'] },
  ]

  return rows.map((row, index) => ({
    title: row.title,
    tag: row.tag,
    ...BOOKS[row.book],
    color: colorAt(index + 3),
    body: row.body,
    labels: row.labels,
    dueAt: row.dueAt,
    dueTime: row.dueTime,
    alertMinutes: row.alertMinutes,
    pinned: row.pinned,
    confirmed: row.confirmed,
  }))
}

export const createSampleNotes = (ownerEmail: string, now = Date.now()): Note[] => {
  const hour = 60 * 60 * 1000
  const day = 24 * hour
  const today = todayISO(new Date(now))
  const seeds = [...featured(today), ...extras(today)]

  return seeds.map((item, index) =>
    normalizeNote(
      {
        ...item,
        ownerEmail,
        id: 10_000 + index,
        preview: item.body.replace(/!\[[^\]]*\]\([^)]+\)/g, '').trim().slice(0, 80),
        createdAt: now - index * (day * 0.18) - index * hour,
        order: index,
      },
      index,
      ownerEmail
    )
  )
}
