"use client"

import type { CSSProperties, ReactNode } from 'react'

const Sticker = ({
  children,
  className = '',
  size,
  tilt = 0,
  delay = '0s',
}: {
  children: ReactNode
  className?: string
  size: number
  tilt?: number
  delay?: string
}) => (
  <span
    className={`paper-sticker ${className}`}
    style={
      {
        width: size,
        height: size,
        '--tilt': `${tilt}deg`,
        animationDelay: delay,
      } as CSSProperties
    }
  >
    {children}
  </span>
)

export const StarSticker = ({ fill = '#E7A3A3' }: { fill?: string }) => (
  <svg viewBox="0 0 72 72" className="h-full w-full" aria-hidden="true">
    <path
      fill={fill}
      d="M36 4.5 44.2 26.4 68 28.2 50.1 43.1 55.6 66 36 53.6 16.4 66 21.9 43.1 4 28.2 27.8 26.4Z"
    />
  </svg>
)

export const SparkSticker = ({ fill = '#E8C44A' }: { fill?: string }) => (
  <svg viewBox="0 0 48 48" className="h-full w-full" aria-hidden="true">
    <path fill={fill} d="M24 2.5 27.6 19.2 45.5 24 27.6 28.8 24 45.5 20.4 28.8 2.5 24 20.4 19.2Z" />
  </svg>
)

export const FlowerSticker = () => (
  <svg viewBox="0 0 72 72" className="h-full w-full" aria-hidden="true">
    {[0, 72, 144, 216, 288].map((deg) => (
      <ellipse key={deg} cx="36" cy="18" rx="11" ry="16" fill="#D4C4E8" transform={`rotate(${deg} 36 36)`} />
    ))}
    <circle cx="36" cy="36" r="9.5" fill="#E8C44A" />
  </svg>
)

export const HeartSticker = ({ fill = '#E7A3A3' }: { fill?: string }) => (
  <svg viewBox="0 0 64 64" className="h-full w-full" aria-hidden="true">
    <path
      fill={fill}
      d="M32 56C14 42 6 32 6 20.5A13.5 13.5 0 0 1 32 18.5 13.5 13.5 0 0 1 58 20.5C58 32 50 42 32 56Z"
    />
  </svg>
)

export const SunSticker = () => (
  <svg viewBox="0 0 72 72" className="h-full w-full" aria-hidden="true">
    {[0, 45, 90, 135].map((deg) => (
      <rect
        key={deg}
        x="33"
        y="4"
        width="6"
        height="12"
        rx="3"
        fill="#E89569"
        transform={`rotate(${deg} 36 36)`}
      />
    ))}
    <circle cx="36" cy="36" r="16" fill="#E8C44A" />
  </svg>
)

export const MoonSticker = () => (
  <svg viewBox="0 0 64 64" className="h-full w-full" aria-hidden="true">
    <path fill="#D4C4E8" d="M40 8c-7 3-18 13-18 24s11 21 18 24C26 54 12 42 12 32S26 10 40 8Z" />
  </svg>
)

export const SmileSticker = () => (
  <svg viewBox="0 0 64 64" className="h-full w-full" aria-hidden="true">
    <circle cx="32" cy="32" r="22" fill="#A9D4C4" />
    <circle cx="24" cy="28" r="3.2" fill="#2b261f" />
    <circle cx="40" cy="28" r="3.2" fill="#2b261f" />
    <path d="M22 38c3.4 6 16.6 6 20 0" fill="none" stroke="#2b261f" strokeWidth="3.2" strokeLinecap="round" />
  </svg>
)

export const BlobSticker = ({ fill = '#A9D4C4' }: { fill?: string }) => (
  <svg viewBox="0 0 72 72" className="h-full w-full" aria-hidden="true">
    <path fill={fill} d="M46 8c14 3 22 16 20 28-3 16-16 28-32 26S6 48 8 32 20 5 46 8Z" />
  </svg>
)

export const SquiggleSticker = ({ stroke = 'currentColor' }: { stroke?: string }) => (
  <svg viewBox="0 0 88 28" className="h-full w-full" aria-hidden="true">
    <path
      d="M4 16C14 4 22 24 32 12s18-10 28 4 16 10 24-2"
      fill="none"
      stroke={stroke}
      strokeWidth="3.4"
      strokeLinecap="round"
    />
  </svg>
)

export const TapeSticker = () => (
  <svg viewBox="0 0 88 28" className="h-full w-full" aria-hidden="true">
    <rect x="4" y="5" width="80" height="18" rx="3" fill="rgba(232, 196, 74, 0.72)" />
    <rect x="10" y="9" width="68" height="3" rx="1.5" fill="rgba(255, 255, 255, 0.35)" />
  </svg>
)

export const CloverSticker = () => (
  <svg viewBox="0 0 72 72" className="h-full w-full" aria-hidden="true">
    {[ -32, 58, 148, 238 ].map((deg) => (
      <ellipse key={deg} cx="36" cy="20" rx="11" ry="15" fill="#A9D4C4" transform={`rotate(${deg} 36 40)`} />
    ))}
    <rect x="33.5" y="42" width="5" height="18" rx="2.5" fill="#7eae9a" />
  </svg>
)

export function AuthStickers() {
  return (
    <div className="pointer-events-none absolute inset-0 z-0" aria-hidden="true">
      <Sticker className="absolute left-5 top-[max(1.35rem,env(safe-area-inset-top))]" size={56} tilt={-14} delay="0.1s">
        <FlowerSticker />
      </Sticker>
      <Sticker className="absolute right-5 top-[max(1.1rem,env(safe-area-inset-top))]" size={70} tilt={12} delay="0.35s">
        <StarSticker />
      </Sticker>
      <Sticker
        className="absolute right-[4.75rem] top-[max(5.35rem,calc(env(safe-area-inset-top)+4.1rem))]"
        size={26}
        tilt={22}
        delay="0.7s"
      >
        <SparkSticker />
      </Sticker>
    </div>
  )
}

export function OnboardStickers() {
  return (
    <div className="pointer-events-none absolute inset-0 z-0" aria-hidden="true">
      <Sticker className="absolute left-5 top-[max(1.35rem,env(safe-area-inset-top))]" size={58} tilt={-10} delay="0.15s">
        <CloverSticker />
      </Sticker>
      <Sticker className="absolute right-6 top-[max(1.2rem,env(safe-area-inset-top))]" size={52} tilt={14} delay="0.4s">
        <MoonSticker />
      </Sticker>
      <Sticker
        className="absolute right-[4.4rem] top-[max(5.1rem,calc(env(safe-area-inset-top)+3.9rem))]"
        size={24}
        tilt={18}
        delay="0.8s"
      >
        <SparkSticker fill="#E89569" />
      </Sticker>
    </div>
  )
}

export function TodayStickers() {
  return (
    <div className="relative h-[6.6rem] w-[6.6rem] shrink-0" aria-hidden="true">
      <Sticker className="absolute right-0 top-0" size={58} tilt={8} delay="0.2s">
        <SunSticker />
      </Sticker>
      <Sticker className="absolute left-0 top-9" size={26} tilt={-18} delay="0.55s">
        <SparkSticker />
      </Sticker>
      <Sticker className="absolute bottom-0 right-1" size={34} tilt={12} delay="0.9s">
        <SmileSticker />
      </Sticker>
    </div>
  )
}

export function CardTape({ className = '' }: { className?: string }) {
  return (
    <span className={`pointer-events-none absolute z-20 ${className}`} aria-hidden="true">
      <span className="paper-sticker block h-7 w-[4.6rem]" style={{ '--tilt': '-11deg' } as CSSProperties}>
        <TapeSticker />
      </span>
    </span>
  )
}
