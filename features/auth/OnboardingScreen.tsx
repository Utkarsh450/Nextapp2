"use client"

import { useState } from 'react'
import PaperStage from '@/components/ui/PaperStage'
import { CardTape } from '@/components/ui/PaperStickers'
import { PAPER_SKINS, type PaperSkin } from '@/lib/theme'
import { profileFromEmail, sanitizeProfile, type UserProfile } from '@/lib/profile'

export default function OnboardingScreen({
  email,
  skin,
  onSkin,
  onFinish,
}: {
  email: string
  skin: PaperSkin
  onSkin: (skin: PaperSkin) => void
  onFinish: (profile: UserProfile) => void
}) {
  const fallback = profileFromEmail(email)
  const [step, setStep] = useState<0 | 1>(0)
  const [name, setName] = useState(fallback.name === 'You' ? '' : fallback.name)

  const finish = (nextName = name) => {
    onFinish(sanitizeProfile({ name: nextName.trim() || fallback.name }, fallback))
  }

  return (
    <PaperStage scene="onboard">
      <div
        className="mx-auto flex w-full max-w-md flex-1 flex-col px-6 pb-[max(1.5rem,env(safe-area-inset-bottom))] pt-[max(6.4rem,calc(env(safe-area-inset-top)+5.2rem))]"
      >
        <div className="flex flex-1 flex-col justify-center">
          <p className="text-sm font-medium text-[var(--muted)]">
            Step {step + 1} of 2
          </p>
          <h1 className="mt-1 max-w-[11ch] text-[2.55rem] font-bold leading-[0.92] tracking-[-0.05em] text-[var(--ink)]">
            {step === 0 ? 'What should we call you?' : 'Pick your paper'}
          </h1>
          <p className="mt-4 max-w-[18rem] text-[1.02rem] leading-relaxed text-[var(--ink)]/70">
            {step === 0
              ? 'A first name is enough. You can change it later in You.'
              : 'Classic, monsoon, or festival. The board keeps this look.'}
          </p>

          {step === 0 ? (
            <div className="relative mt-8">
              <CardTape className="-top-3 left-8" />
              <form
                className="relative z-10 rounded-[32px] bg-[#C5CA8A] p-5 pt-6 text-[#2b261f]"
                onSubmit={(event) => {
                  event.preventDefault()
                  setStep(1)
                }}
              >
                <label className="block">
                  <span className="text-[0.78rem] font-medium text-[#2b261f]/60">Name</span>
                  <input
                    autoFocus
                    value={name}
                    onChange={(event) => setName(event.target.value)}
                    placeholder="Ada"
                    className="mt-2 min-h-14 w-full rounded-full bg-white/80 px-4 text-base outline-none placeholder:text-[#2b261f]/40"
                  />
                </label>
                <button type="submit" className="mt-5 min-h-14 w-full rounded-full bg-[#1a1814] text-base font-semibold text-white">
                  Continue
                </button>
              </form>
            </div>
          ) : (
            <div className="mt-8">
              <div className="grid grid-cols-3 gap-3">
                {PAPER_SKINS.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => onSkin(item.id)}
                    className={`rounded-[24px] p-3 text-left ring-2 ${skin === item.id ? 'ring-[var(--ink)]' : 'ring-transparent'}`}
                    style={{
                      backgroundColor: item.paper,
                      color: item.ink,
                    }}
                  >
                    <span className="mt-8 block h-8 rounded-xl" style={{ backgroundColor: item.ink, opacity: 0.18 }} />
                    <p className="mt-3 text-sm font-bold">{item.label}</p>
                  </button>
                ))}
              </div>
              <button
                type="button"
                className="mt-5 min-h-14 w-full rounded-full bg-[#1a1814] text-base font-semibold text-white"
                onClick={() => finish()}
              >
                Start writing
              </button>
            </div>
          )}

        {step === 1 ? (
          <div className="mt-4 flex items-center justify-between px-1 text-sm font-medium text-[var(--ink)]/65">
            <button type="button" onClick={() => setStep(0)}>
              Back
            </button>
            <button type="button" onClick={() => finish(name)}>
              Skip for now
            </button>
          </div>
        ) : (
          <button
            type="button"
            className="mt-4 w-full text-center text-sm font-medium text-[var(--ink)]/65"
            onClick={() => finish(name)}
          >
            Skip for now
          </button>
        )}
        </div>
      </div>
    </PaperStage>
  )
}
