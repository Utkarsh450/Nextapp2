"use client"

import {
  Bell,
  BookMarked,
  CalendarDays,
  ChevronRight,
  Download,
  FileJson,
  Info,
  LogOut,
  Moon,
  NotebookPen,
  Palette,
  Pencil,
  Shield,
  Sun,
  Trash2,
} from 'lucide-react'
import Link from 'next/link'
import { useRef, useState, type ReactNode } from 'react'
import { StarSticker } from '@/components/ui/PaperStickers'
import { compressImageFile } from '@/lib/notes'
import { PAPER_SKINS, type PaperSkin } from '@/lib/theme'
import { PROFILE_HUES, initialsFromName, sanitizeProfile, type AccountUser, type UserProfile } from '@/lib/profile'

export default function AccountPanel({
  user,
  email,
  notesCount,
  notebooksCount = 0,
  reminderCount = 0,
  trashCount = 0,
  onSave,
  onLogout,
  onExportMarkdown,
  onExportJson,
  onOpenTrash,
  onOpenNotes,
  onOpenBooks,
  onOpenPlan,
  onImportJson,
  online,
  pendingCount,
  usageLabel,
  persistError,
  onEnableAlerts,
  skin = 'classic',
  onSkin,
  dark = false,
  onToggleTheme,
}: {
  user: AccountUser
  email: string
  notesCount: number
  notebooksCount?: number
  reminderCount?: number
  trashCount?: number
  onSave: (profile: UserProfile) => void
  onLogout: () => void
  onExportMarkdown: () => void
  onExportJson: () => void
  onOpenTrash: () => void
  onOpenNotes?: () => void
  onOpenBooks?: () => void
  onOpenPlan?: () => void
  onImportJson: (raw: string) => void
  online: boolean
  pendingCount: number
  usageLabel: string | null
  persistError: string | null
  onEnableAlerts?: () => void
  skin?: PaperSkin
  onSkin?: (skin: PaperSkin) => void
  dark?: boolean
  onToggleTheme?: () => void
}) {
  const [editing, setEditing] = useState(false)
  const [photoError, setPhotoError] = useState('')
  const [draft, setDraft] = useState<UserProfile>(user)
  const [source, setSource] = useState(user)
  const [paperOpen, setPaperOpen] = useState(false)
  const photoRef = useRef<HTMLInputElement>(null)
  const importRef = useRef<HTMLInputElement>(null)
  const skinLabel = PAPER_SKINS.find((item) => item.id === skin)?.label ?? 'Classic'

  if (user !== source) {
    setSource(user)
    setDraft(user)
  }

  return (
    <section className="mx-auto w-full max-w-xl px-4 pb-28 pt-1 animate-fade-up">
      <div className="flex items-start gap-4">
        <div className="relative shrink-0">
          {user.avatar ? (
            // eslint-disable-next-line @next/next/no-img-element -- local profile photo
            <img src={user.avatar} alt="" className="h-[5.6rem] w-[5.6rem] rounded-[1.7rem] object-cover" />
          ) : (
            <span
              className="inline-flex h-[5.6rem] w-[5.6rem] items-center justify-center rounded-[1.7rem] text-2xl font-bold text-white"
              style={{ backgroundColor: user.hue }}
            >
              {initialsFromName(user.name)}
            </span>
          )}
          <button
            type="button"
            aria-label={editing ? 'Close profile editor' : 'Edit profile'}
            onClick={() => setEditing((value) => !value)}
            className="absolute -right-2 -top-2 grid h-9 w-9 place-items-center"
          >
            <span className="absolute inset-0">
              <StarSticker fill="#E7A3A3" />
            </span>
            <Pencil size={13} strokeWidth={2} className="relative z-[1] text-[#2b261f]" />
          </button>
        </div>
        <div className="min-w-0 flex-1 pt-1">
          <h2 className="text-[1.7rem] font-bold leading-[1.05] tracking-[-0.04em]">{user.name}</h2>
          <div className="mt-3 grid grid-cols-3 gap-2">
            <Stat value={String(notesCount)} label="Notes" />
            <Stat value={String(notebooksCount)} label="Books" />
            <Stat value={user.handle} label="Handle" />
          </div>
        </div>
      </div>

      <div className="mt-4 flex min-h-12 items-center justify-between gap-3 rounded-full bg-[#C5CA8A] px-4 text-sm text-[#2b261f]">
        <span className="flex min-w-0 items-center gap-2 font-medium">
          <Info size={15} strokeWidth={1.8} />
          <span className="truncate">{email}</span>
        </span>
        <span className="shrink-0 text-[0.78rem] text-[#2b261f]/70">{online ? 'On device' : 'Offline'}</span>
      </div>

      {user.bio ? <p className="mt-4 text-sm leading-relaxed text-[var(--ink)]/75">{user.bio}</p> : null}
      {persistError && <p className="mt-3 text-sm text-red-700">{persistError}</p>}

      {editing && (
        <form
          className="mt-5 space-y-3 rounded-[28px] bg-white/75 p-4"
          onSubmit={(event) => {
            event.preventDefault()
            onSave(sanitizeProfile(draft, user))
            setEditing(false)
          }}
        >
          <input
            value={draft.name}
            onChange={(event) => setDraft({ ...draft, name: event.target.value })}
            placeholder="Name"
            className="min-h-12 w-full rounded-full bg-[var(--paper)] px-4 text-sm outline-none"
          />
          <input
            value={draft.handle}
            onChange={(event) => setDraft({ ...draft, handle: event.target.value })}
            placeholder="Handle"
            className="min-h-12 w-full rounded-full bg-[var(--paper)] px-4 text-sm outline-none"
          />
          <textarea
            value={draft.bio}
            onChange={(event) => setDraft({ ...draft, bio: event.target.value })}
            placeholder="A line about you"
            className="min-h-24 w-full rounded-[22px] bg-[var(--paper)] px-4 py-3 text-sm outline-none"
          />
          <div className="flex flex-wrap gap-2">
            {PROFILE_HUES.map((hue) => (
              <button
                key={hue}
                type="button"
                aria-label={`Color ${hue}`}
                onClick={() => setDraft({ ...draft, hue })}
                className="h-8 w-8 rounded-full"
                style={{ backgroundColor: hue, boxShadow: draft.hue === hue ? 'inset 0 0 0 2px #2b261f' : undefined }}
              />
            ))}
          </div>
          <input
            ref={photoRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={async (event) => {
              const file = event.target.files?.[0]
              if (!file) return
              if (file.size > 4 * 1024 * 1024) {
                setPhotoError('Keep photos under 4 MB.')
                return
              }
              setPhotoError('')
              const avatar = await compressImageFile(file)
              setDraft({ ...draft, avatar })
              event.target.value = ''
            }}
          />
          <div className="flex gap-2">
            <button type="button" onClick={() => photoRef.current?.click()} className="rounded-full bg-white/80 px-4 py-2 text-sm font-medium">
              Photo
            </button>
            <button type="button" onClick={() => setDraft({ ...draft, avatar: null })} className="rounded-full px-4 py-2 text-sm">
              Remove
            </button>
          </div>
          {photoError && <p className="text-sm text-red-700">{photoError}</p>}
          <button type="submit" className="min-h-12 w-full rounded-full bg-[#1a1814] text-sm font-semibold text-white">
            Save profile
          </button>
        </form>
      )}

      <h3 className="mb-3 mt-7 text-[1.15rem] font-bold tracking-[-0.03em]">Library</h3>
      <div className="overflow-hidden rounded-[28px] bg-white/70">
        <Row icon={<NotebookPen size={18} strokeWidth={1.7} />} tone="#E8C44A" label="Notes" badge={notesCount} onClick={onOpenNotes} />
        <Row icon={<BookMarked size={18} strokeWidth={1.7} />} tone="#E7A3A3" label="Notebooks" badge={notebooksCount} onClick={onOpenBooks} />
        <Row icon={<CalendarDays size={18} strokeWidth={1.7} />} tone="#A9D4C4" label="Plan" badge={reminderCount} onClick={onOpenPlan} />
        <Row icon={<Trash2 size={18} strokeWidth={1.7} />} tone="#D4C4E8" label="Trash" badge={trashCount || undefined} onClick={onOpenTrash} last />
      </div>

      <h3 className="mb-3 mt-7 text-[1.15rem] font-bold tracking-[-0.03em]">Settings</h3>
      <div className="overflow-hidden rounded-[28px] bg-white/70">
        <Row
          icon={<Palette size={18} strokeWidth={1.7} />}
          tone="#E89569"
          label="Paper"
          hint={skinLabel}
          onClick={() => setPaperOpen((value) => !value)}
        />
        {paperOpen && (
          <div className="grid grid-cols-3 gap-2 px-4 pb-4">
            {PAPER_SKINS.map((item) => (
              <button
                key={item.id}
                type="button"
                onClick={() => onSkin?.(item.id)}
                className="rounded-2xl px-2 py-3 text-center text-xs font-medium"
                style={{
                  background: item.paper,
                  color: item.ink,
                  boxShadow: skin === item.id ? 'inset 0 0 0 2px #2b261f' : undefined,
                }}
              >
                {item.label}
              </button>
            ))}
          </div>
        )}
        <Row
          icon={dark ? <Moon size={18} strokeWidth={1.7} /> : <Sun size={18} strokeWidth={1.7} />}
          tone="#BEC3BC"
          label={dark ? 'Night ink' : 'Day paper'}
          onClick={onToggleTheme}
        />
        <Row
          icon={<Bell size={18} strokeWidth={1.7} />}
          tone="#C5CA8A"
          label="Phone alerts"
          hint={onEnableAlerts ? 'Off' : 'App only'}
          onClick={onEnableAlerts}
        />
        <Row icon={<Download size={18} strokeWidth={1.7} />} tone="#E8C44A" label="Export Markdown" onClick={onExportMarkdown} />
        <Row icon={<FileJson size={18} strokeWidth={1.7} />} tone="#D4C4E8" label="Export JSON" onClick={onExportJson} />
        <Row
          icon={<FileJson size={18} strokeWidth={1.7} />}
          tone="#E7A3A3"
          label="Import backup"
          onClick={() => importRef.current?.click()}
        />
        <Row icon={<Shield size={18} strokeWidth={1.7} />} tone="#A9D4C4" label="Privacy" href="/privacy/" />
        <Row icon={<LogOut size={18} strokeWidth={1.7} />} tone="#E7A3A3" label="Sign out" danger last onClick={onLogout} />
      </div>

      <input
        ref={importRef}
        type="file"
        accept="application/json"
        className="hidden"
        onChange={async (event) => {
          const file = event.target.files?.[0]
          if (!file) return
          onImportJson(await file.text())
          event.target.value = ''
        }}
      />

      <p className="mt-6 text-center text-xs leading-relaxed text-[var(--muted)]">
        {usageLabel ? `${usageLabel} on this device. ` : ''}
        {pendingCount > 0 ? `${pendingCount} change${pendingCount === 1 ? '' : 's'} waiting. ` : ''}
        Notes stay isolated to {email}.
      </p>
    </section>
  )
}

function Stat({ value, label }: { value: string; label: string }) {
  return (
    <div className="min-w-0">
      <p className="truncate text-[1.05rem] font-bold tracking-[-0.03em]">{value}</p>
      <p className="mt-0.5 text-[0.62rem] font-medium uppercase tracking-[0.12em] text-[var(--muted)]">{label}</p>
    </div>
  )
}

function Row({
  icon,
  tone,
  label,
  badge,
  hint,
  danger,
  last,
  href,
  onClick,
}: {
  icon: ReactNode
  tone: string
  label: string
  badge?: number
  hint?: string
  danger?: boolean
  last?: boolean
  href?: string
  onClick?: () => void
}) {
  const className = `flex min-h-[3.55rem] w-full items-center gap-3 px-3.5 text-left ${
    last ? '' : 'border-b border-black/5'
  }`
  const body = (
    <>
      <span
        className="grid h-10 w-10 shrink-0 place-items-center rounded-full text-[#2b261f]"
        style={{ backgroundColor: tone }}
      >
        {icon}
      </span>
      <span className={`min-w-0 flex-1 text-[0.95rem] font-medium ${danger ? 'text-[#7a2418]' : ''}`}>{label}</span>
      {hint && <span className="text-xs text-[var(--muted)]">{hint}</span>}
      {typeof badge === 'number' && (
        <span className="rounded-md bg-[#1a1814] px-1.5 py-0.5 text-[0.7rem] font-bold text-white">{badge}</span>
      )}
      <ChevronRight size={18} strokeWidth={1.7} className="shrink-0 text-[var(--muted)]" />
    </>
  )

  if (href) {
    return (
      <Link href={href} className={className}>
        {body}
      </Link>
    )
  }

  return (
    <button type="button" onClick={onClick} className={className}>
      {body}
    </button>
  )
}
