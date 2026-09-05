"use client"

import { useState } from 'react'
import OtpBoxes from '@/components/ui/OtpBoxes'
import PaperStage from '@/components/ui/PaperStage'
import { BlobSticker, CardTape, HeartSticker, SquiggleSticker } from '@/components/ui/PaperStickers'
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
    <PaperStage scene="auth">
      <div
        className="mx-auto flex w-full max-w-md flex-1 flex-col px-6 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-[max(6.4rem,calc(env(safe-area-inset-top)+5.2rem))]"
      >
        <div className="flex flex-1 flex-col justify-center">
          <p className="text-sm font-medium text-[var(--muted)]">{sent ? 'Almost there' : 'Your notebook'}</p>
          <h1 className="mt-1 max-w-[10ch] text-[2.85rem] font-bold leading-[0.92] tracking-[-0.05em] text-[var(--ink)] sm:text-6xl">
            {sent ? 'Enter the code' : (
              <>
                Write it
                {' '}
                <span className="relative inline-block pb-2">
                  down
                  <span className="absolute -bottom-0.5 left-0 h-4 w-full text-[#E89569]">
                    <SquiggleSticker />
                  </span>
                </span>
              </>
            )}
          </h1>
          <p className="mt-4 max-w-[18rem] text-[1.02rem] leading-relaxed text-[var(--ink)]/70">
            {viaTerminal
              ? 'The six digits are waiting in the terminal running this app.'
              : sent
                ? `We sent a short code to ${email}. It fades in 10 minutes.`
                : 'A quiet board for lists and little ideas. No password — just a code.'}
          </p>

          <div className="relative mt-8">
            <CardTape className="-top-3 left-8" />
            <span className="paper-sticker pointer-events-none absolute -bottom-5 -left-2 z-0 h-11 w-11" style={{ ['--tilt' as string]: '-18deg' }}>
              <HeartSticker />
            </span>
            <span className="paper-sticker pointer-events-none absolute -right-3 -top-7 z-0 h-12 w-12" style={{ ['--tilt' as string]: '16deg' }}>
              <BlobSticker fill={sent ? '#C5CA8A' : '#E7A3A3'} />
            </span>

            <form
              className="relative z-10 rounded-[32px] p-5 pt-6 text-[#2b261f]"
              style={{ backgroundColor: sent ? '#E7A3A3' : '#C5CA8A' }}
              onSubmit={(event) => {
                event.preventDefault()
                if (sent) void verifyCode()
                else void sendCode()
              }}
            >
              {!sent ? (
                <label className="block">
                  <span className="text-[0.78rem] font-medium text-[#2b261f]/60">Email</span>
                  <input
                    type="email"
                    required
                    autoFocus
                    value={email}
                    onChange={(event) => setEmail(event.target.value)}
                    placeholder="you@email.com"
                    className="mt-2 min-h-14 w-full rounded-full bg-white/80 px-4 text-base outline-none placeholder:text-[#2b261f]/40"
                  />
                </label>
              ) : (
                <div>
                  <p className="text-[0.78rem] font-medium text-[#2b261f]/60">Six digits</p>
                  {viaTerminal && (
                    <p className="mt-2 rounded-2xl bg-white/70 px-4 py-3 text-sm leading-relaxed">
                      Look for
                      {' '}
                      <span className="font-mono text-[0.75rem]">[notes otp] {email} → 123456</span>
                    </p>
                  )}
                  <OtpBoxes value={otp} onChange={setOtp} />
                </div>
              )}

              {error && <p className="mt-4 text-sm font-medium text-[#7a2418]">{error}</p>}

              <button
                type="submit"
                disabled={busy || (sent && otp.length !== 6)}
                className="mt-5 min-h-14 w-full rounded-full bg-[#1a1814] text-base font-semibold text-white disabled:opacity-50"
              >
                {busy ? 'One moment…' : sent ? 'Open my board' : 'Send me a code'}
              </button>
            </form>
          </div>

          {sent ? (
            <div className="mt-5 flex items-center justify-between px-1 text-sm font-medium text-[var(--ink)]/70">
              <button
                type="button"
                disabled={busy}
                onClick={() => {
                  setSent(false)
                  setOtp('')
                  setError('')
                  setViaTerminal(false)
                }}
              >
                Use another email
              </button>
              <button type="button" disabled={busy} onClick={() => void sendCode()}>
                Send again
              </button>
            </div>
          ) : (
            <p className="mt-5 px-1 text-sm text-[var(--ink)]/55">We’ll keep this board just for you.</p>
          )}
        </div>
      </div>
    </PaperStage>
  )
}
