export const THEME_KEY = 'notes-board-theme'
export const SKIN_KEY = 'notes-board-skin'
export const LAYOUT_KEY = 'notes-board-layout'

export type ThemeMode = 'light' | 'dark'
export type PaperSkin = 'classic' | 'monsoon' | 'festival'
export type BoardLayout = 'grid' | 'masonry'

export const PAPER_SKINS: Array<{ id: PaperSkin; label: string; paper: string; ink: string }> = [
  { id: 'classic', label: 'Classic', paper: '#f4e8dc', ink: '#2b261f' },
  { id: 'monsoon', label: 'Monsoon', paper: '#e4eee8', ink: '#1a2c24' },
  { id: 'festival', label: 'Festival', paper: '#f6ead2', ink: '#3a2414' },
]

export const readTheme = (): ThemeMode => {
  if (typeof localStorage === 'undefined') return 'light'
  return localStorage.getItem(THEME_KEY) === 'dark' ? 'dark' : 'light'
}

export const writeTheme = (theme: ThemeMode) => {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(THEME_KEY, theme)
}

export const applyThemeClass = (theme: ThemeMode) => {
  if (typeof document === 'undefined') return
  document.documentElement.classList.toggle('dark', theme === 'dark')
}

export const readSkin = (): PaperSkin => {
  if (typeof localStorage === 'undefined') return 'classic'
  const value = localStorage.getItem(SKIN_KEY)
  return value === 'monsoon' || value === 'festival' ? value : 'classic'
}

export const writeSkin = (skin: PaperSkin) => {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(SKIN_KEY, skin)
}

export const applySkinClass = (skin: PaperSkin) => {
  if (typeof document === 'undefined') return
  if (skin === 'classic') delete document.documentElement.dataset.skin
  else document.documentElement.dataset.skin = skin
}

export const readLayout = (): BoardLayout => {
  if (typeof localStorage === 'undefined') return 'masonry'
  const value = localStorage.getItem(LAYOUT_KEY)
  if (value === 'classic' || value === 'grid') return 'grid'
  return 'masonry'
}

export const writeLayout = (layout: BoardLayout) => {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(LAYOUT_KEY, layout)
}

export const applyLayoutClass = (layout: BoardLayout) => {
  if (typeof document === 'undefined') return
  document.documentElement.dataset.layout = layout
}
