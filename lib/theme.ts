export const THEME_KEY = 'notes-board-theme'

export type ThemeMode = 'light' | 'dark'

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
