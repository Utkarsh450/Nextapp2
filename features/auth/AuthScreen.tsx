"use client"

import { useState } from 'react'
import OtpBoxes from '@/components/ui/OtpBoxes'
import type { AuthSession } from '@/lib/auth'

export default function AuthScreen({
  sendOtp,
  verifyOtp,
}: {
  sendOtp: (email: string) => Promise<{ ok?: boolean; error?: string; via?: string }>
  verifyOtp: (email: string, otp: string) => Promise<{ ok?: boolean; error?: string; session?: AuthSession }>
}) {
  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [sent, setSent] = useState(false)
  const [viaTerminal, setViaTerminal] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const sendCode = async () => {
    setBusy(true)
    setError('')
    try {
      const data = await sendOtp(email)
      if (!data.ok) {
        setError(data.error || 'Could not send the code')
        return
      }
      setViaTerminal(data.via === 'terminal')
      setSent(true)
    } catch {
      setError('Network error. Try again.')
    } finally {
      setBusy(false)
    }
  }

  const verifyCode = async () => {
    setBusy(true)
    setError('')
    try {
      const data = await verifyOtp(email, otp)
      if (!data.ok || !data.session) {
        setError(data.error || 'Could not verify the code')
      }
    } catch {
      setError('Network error. Try again.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="relative flex min-h-dvh flex-col justify-end overflow-hidden bg-[#D9E8A8] px-5 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-[max(2rem,env(safe-area-inset-top))] sm:justify-center">
      <div className="pointer-events-none absolute -left-16 top-10 h-56 w-56 rounded-full bg-[#F9A8B6]/80 blur-2xl" />
      <div className="pointer-events-none absolute right-0 top-32 h-64 w-64 rounded-full bg-[#CDE0E8] blur-2xl" />
      <div className="pointer-events-none absolute bottom-24 left-10 h-40 w-40 rounded-full bg-[#F9D368]/90 blur-xl" />

      <div className="relative mx-auto w-full max-w-md animate-fade-up">
        <p className="text-[0.7rem] font-medium uppercase tracking-[0.22em] text-zinc-700/70">Personal notes</p>
        <h1 className="mt-3 max-w-[12ch] text-5xl font-semibold leading-[0.95] tracking-tight text-zinc-900 sm:text-6xl">
          Write it down.
        </h1>
        <p className="mt-4 max-w-sm text-base leading-relaxed text-zinc-700/85">
          {viaTerminal
            ? 'The 6-digit code is printed in the terminal running the app.'
            : sent
              ? 'Check your inbox for a 6-digit code. It expires in 10 minutes.'
              : 'A quiet place for lists, ideas, and reminders. Sign in with email — no password.'}
        </p>

        <form
          className="mt-8"
          onSubmit={(event) => {
            event.preventDefault()
            if (sent) void verifyCode()
            else void sendCode()
          }}
        >
          <label className="block text-[0.7rem] font-medium uppercase tracking-wide text-zinc-700/70">
            Email
            <input
              type="email"
              required
              autoFocus={!sent}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@email.com"
              className="mt-2 min-h-14 w-full rounded-2xl bg-white/75 px-4 text-base outline-none ring-1 ring-black/5 placeholder:text-zinc-500"
            />
          </label>

          {sent && viaTerminal && (
            <p className="mt-4 rounded-2xl bg-white/70 px-4 py-3 text-sm leading-relaxed text-zinc-700">
              Look in the terminal for a line like
              {' '}
              <span className="font-mono text-[0.75rem]">[notes otp] you@email.com → 123456</span>.
            </p>
          )}

          {sent && (
            <div className="mt-5">
              <p className="text-[0.7rem] font-medium uppercase tracking-wide text-zinc-700/70">Code</p>
              <OtpBoxes value={otp} onChange={setOtp} />
            </div>
          )}

          {error && <p className="mt-4 text-sm text-red-700">{error}</p>}

          <button
            type="submit"
            disabled={busy || (sent && otp.length !== 6)}
            className="mt-6 min-h-14 w-full rounded-full bg-zinc-900 text-base font-semibold text-white disabled:opacity-50"
          >
            {busy ? 'Please wait…' : sent ? 'Continue' : 'Send code'}
          </button>

          {sent && (
            <button
              type="button"
              disabled={busy}
              onClick={() => void sendCode()}
              className="mt-3 w-full text-center text-sm font-medium text-zinc-700"
            >
              Resend code
            </button>
          )}
        </form>
      </div>
    </div>
  )
}
