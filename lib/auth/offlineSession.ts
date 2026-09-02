import { userFromEmail, type AuthSession } from './index.ts'

const decodeBase64Url = (value: string) => {
  const padded = value.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - (value.length % 4)) % 4)
  if (typeof Buffer !== 'undefined') {
    try {
      return Buffer.from(value, 'base64url').toString('utf8')
    } catch {
      return Buffer.from(padded, 'base64').toString('utf8')
    }
  }
  return atob(padded)
}

export const peekAuthToken = (token: string | null | undefined, now = Date.now()): AuthSession | null => {
  if (!token) return null
  const dot = token.lastIndexOf('.')
  if (dot < 1) return null
  try {
    const parsed = JSON.parse(decodeBase64Url(token.slice(0, dot))) as { email?: string; exp?: number }
    if (!parsed.email || typeof parsed.exp !== 'number' || parsed.exp < now) return null
    const profile = userFromEmail(parsed.email)
    return { email: parsed.email, name: profile.name, handle: profile.handle }
  } catch {
    return null
  }
}
