export const AUTH_COOKIE = 'notes_otp_session'
export const SESSION_DAYS = 7

export type AuthSession = {
  email: string
  name: string
  handle: string
}

export const normalizeEmail = (value: string) => value.trim().toLowerCase()

export const isValidEmail = (value: string) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizeEmail(value))

export const userFromEmail = (email: string) => {
  const normalized = normalizeEmail(email)
  const local = normalized.split('@')[0] || 'you'
  const name = local
    .replace(/[._-]+/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
  const initials = name
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase() || 'YO'

  return {
    email: normalized,
    name: name || 'You',
    handle: `@${local.slice(0, 18)}`,
    initials,
  }
}
