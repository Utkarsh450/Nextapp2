import { createHash, randomInt } from 'crypto'
import { isValidEmail, normalizeEmail } from './index'

type OtpRecord = {
  hash: string
  expires: number
  tries: number
}

const memory = () => {
  const globalStore = globalThis as typeof globalThis & { __notesOtpStore?: Map<string, OtpRecord> }
  if (!globalStore.__notesOtpStore) globalStore.__notesOtpStore = new Map()
  return globalStore.__notesOtpStore
}

const hashOtp = (email: string, otp: string) =>
  createHash('sha256').update(`${email}:${otp}`).digest('hex')

const generateOtp = () => String(randomInt(100000, 1000000))

type ScriptResult = { ok: boolean; error?: string }

const callAppsScript = async (payload: Record<string, string>): Promise<ScriptResult> => {
  const url = process.env.APPS_SCRIPT_URL
  const secret = process.env.APPS_SCRIPT_SECRET || process.env.AUTH_SECRET
  if (!url || !secret) {
    return { ok: false, error: 'Apps Script is not configured' }
  }

  const body = JSON.stringify({ ...payload, secret })
  const posted = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
    redirect: 'manual',
  })

  const location = posted.headers.get('location')
  const response =
    location && posted.status >= 300 && posted.status < 400
      ? await fetch(location)
      : posted

  const text = await response.text()
  try {
    return JSON.parse(text) as ScriptResult
  } catch {
    return { ok: false, error: 'Apps Script returned an invalid response. Redeploy the web app as Anyone.' }
  }
}

export const sendEmailOtp = async (rawEmail: string) => {
  const email = normalizeEmail(rawEmail)
  if (!isValidEmail(email)) return { ok: false as const, error: 'Enter a valid email address' }

  if (process.env.APPS_SCRIPT_URL) {
    const result = await callAppsScript({ action: 'send', email })
    if (!result.ok) return { ok: false as const, error: result.error || 'Could not send OTP' }
    return { ok: true as const, via: 'email' as const }
  }

  if (process.env.NODE_ENV === 'production') {
    return { ok: false as const, error: 'Apps Script URL is missing' }
  }

  const otp = generateOtp()
  memory().set(email, {
    hash: hashOtp(email, otp),
    expires: Date.now() + 10 * 60 * 1000,
    tries: 0,
  })
  console.info(`[notes otp] ${email} → ${otp} (dev only, Apps Script not configured)`)
  return { ok: true as const, via: 'terminal' as const }
}

export const verifyEmailOtp = async (rawEmail: string, rawOtp: string) => {
  const email = normalizeEmail(rawEmail)
  const otp = rawOtp.replace(/\s/g, '')
  if (!isValidEmail(email)) return { ok: false as const, error: 'Enter a valid email address' }
  if (!/^\d{6}$/.test(otp)) return { ok: false as const, error: 'Enter the 6-digit code' }

  if (process.env.APPS_SCRIPT_URL) {
    const result = await callAppsScript({ action: 'verify', email, otp })
    if (!result.ok) return { ok: false as const, error: result.error || 'Invalid or expired code' }
    return { ok: true as const, email }
  }

  if (process.env.NODE_ENV === 'production') {
    return { ok: false as const, error: 'Apps Script URL is missing' }
  }

  const record = memory().get(email)
  if (!record || record.expires < Date.now()) {
    memory().delete(email)
    return { ok: false as const, error: 'Code expired. Request a new one.' }
  }
  if (record.tries >= 5) {
    memory().delete(email)
    return { ok: false as const, error: 'Too many attempts. Request a new code.' }
  }
  record.tries += 1
  if (record.hash !== hashOtp(email, otp)) {
    return { ok: false as const, error: 'That code is incorrect' }
  }
  memory().delete(email)
  return { ok: true as const, email }
}
