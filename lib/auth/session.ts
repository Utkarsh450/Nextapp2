import { createHmac, timingSafeEqual } from 'crypto'
import { AUTH_COOKIE, SESSION_DAYS, normalizeEmail, userFromEmail, type AuthSession } from './index'

const encoder = new TextEncoder()

const secret = () =>
  process.env.AUTH_SECRET ||
  process.env.APPS_SCRIPT_SECRET ||
  (process.env.NODE_ENV === 'production' ? '' : 'dev-notes-otp-secret')

const toBase64Url = (value: string) =>
  Buffer.from(value, 'utf8').toString('base64url')

const fromBase64Url = (value: string) =>
  Buffer.from(value, 'base64url').toString('utf8')

const sign = (payload: string) =>
  createHmac('sha256', secret()).update(payload).digest('base64url')

const safeEqual = (left: string, right: string) => {
  const a = encoder.encode(left)
  const b = encoder.encode(right)
  if (a.length !== b.length) return false
  return timingSafeEqual(a, b)
}

export const createSessionToken = (email: string, now = Date.now()) => {
  const payload = toBase64Url(JSON.stringify({
    email: normalizeEmail(email),
    exp: now + SESSION_DAYS * 24 * 60 * 60 * 1000,
  }))
  return `${payload}.${sign(payload)}`
}

export const readSessionToken = (token: string | undefined | null, now = Date.now()): AuthSession | null => {
  if (!token || !secret()) return null
  const dot = token.lastIndexOf('.')
  if (dot < 1) return null
  const payload = token.slice(0, dot)
  const signature = token.slice(dot + 1)
  if (!safeEqual(sign(payload), signature)) return null
  try {
    const parsed = JSON.parse(fromBase64Url(payload)) as { email?: string; exp?: number }
    if (!parsed.email || typeof parsed.exp !== 'number' || parsed.exp < now) return null
    const profile = userFromEmail(parsed.email)
    return { email: parsed.email, name: profile.name, handle: profile.handle }
  } catch {
    return null
  }
}

export const tokenFromRequest = (request: Request, cookieValue?: string | null) => {
  const auth = request.headers.get('authorization')
  if (auth && auth.toLowerCase().startsWith('bearer ')) return auth.slice(7).trim()
  return cookieValue || null
}

export const sessionCookieOptions = {
  name: AUTH_COOKIE,
  httpOnly: true,
  sameSite: 'lax' as const,
  secure: process.env.NODE_ENV === 'production',
  path: '/',
  maxAge: SESSION_DAYS * 24 * 60 * 60,
}
