export { NOTE_COLORS, NOTEBOOK_COVERS, THEME_KEY, randomNoteColor, slugify, newId } from './types'
export type {
  Attachment,
  AccountBundle,
  AppTab,
  FilterKey,
  Note,
  Notebook,
  QueuedMutation,
  SavedTemplate,
  SortKey,
  TemplateKey,
} from './types'

export { todayISO, formatNoteTimestamp, formatRelativeTime, isDueToday, isOverdue, dueLabel } from './dates'
export {
  parseMarkdown,
  insertChecklist,
  insertImageMarkdown,
  toggleTaskLine,
  checklistProgress,
  wordCount,
  cardBodyPreview,
  highlightSegments,
} from './markdown'
export type { MarkdownBlock } from './markdown'
export { normalizeNote, belongsToOwner } from './normalize'
export {
  uniqueNotebooks,
  uniqueTags,
  uniqueLabels,
  uniqueColors,
  restoreNote,
  moveNote,
  trashNote,
  restoreFromTrash,
  visibleNotes,
  upcomingReminders,
} from './filters'
export { LABEL_PRESETS, labelTint } from './labels'
export { NOTE_TEMPLATES, applyTemplate, dailyNoteTitle, findDailyNote, templateFromSaved } from './templates'
export { createSampleNotes } from './seed'
export { DEFAULT_NOTEBOOKS, defaultNotebooksFor, ensureNotebooks, createNotebook, renameNotebook, notebookById } from './notebooks'
export { exportNotesJson, importNotesJson, exportNotesMarkdown, parseNoteIdFromSearch, sharePath } from './export'
export { compressImageFile } from './image'
export { loadAccount, persistAccount, enqueueMutation, pendingMutations, rememberSearch } from './storage'
