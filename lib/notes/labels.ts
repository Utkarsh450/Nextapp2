import { NOTE_COLORS } from './types.ts'

export const LABEL_PRESETS = ['Work', 'Personal', 'Ideas', 'Tasks', 'Home', 'Today'] as const

export const labelTint = (label: string) =>
  NOTE_COLORS[Math.abs([...label].reduce((sum, ch) => sum + ch.charCodeAt(0), 0)) % NOTE_COLORS.length]
