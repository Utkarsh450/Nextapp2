"use client"

import { Download, FileJson, LogOut, Pencil, Trash2 } from 'lucide-react'
import Link from 'next/link'
import { useRef, useState } from 'react'
import { compressImageFile } from '@/lib/notes'
import { PROFILE_HUES, initialsFromName, sanitizeProfile, type AccountUser, type UserProfile } from '@/lib/profile'

export default function AccountPanel({
  user,
  email,
  notesCount,
  onSave,
  onLogout,
  onExportMarkdown,
  onExportJson,
  onOpenTrash,
  onImportJson,
}: {
  user: AccountUser
  email: string
  notesCount: number
  onSave: (profile: UserProfile) => void
  onLogout: () => void
  onExportMarkdown: () => void
  onExportJson: () => void
  onOpenTrash: () => void
  onImportJson: (raw: string) => void
}) {
  const [editing, setEditing] = useState(false)
  const [photoError, setPhotoError] = useState('')
  const [draft, setDraft] = useState<UserProfile>(user)
  const [source, setSource] = useState(user)
  const photoRef = useRef<HTMLInputElement>(null)
  const importRef = useRef<HTMLInputElement>(null)

  if (user !== source) {
    setSource(user)
    setDraft(user)
  }

  return (
    <section className="mx-auto w-full max-w-xl px-4 pb-28 pt-2 animate-fade-up">
      <div className="rounded-[28px] bg-white/70 p-5 shadow-[var(--shadow-card)] ring-1 ring-black/5 dark:bg-white/5">
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            {user.avatar ? (
              <img src={user.avatar} alt="" className="h-16 w-16 rounded-full object-cover" />
            ) : (
              <span
                className="inline-flex h-16 w-16 items-center justify-center rounded-full text-lg font-semibold text-white"
                style={{ backgroundColor: user.hue }}
              >
                {initialsFromName(user.name)}
              </span>
            )}
            <div>
              <h2 className="text-xl font-semibold tracking-tight">{user.name}</h2>
              <p className="text-sm text-[var(--muted)]">{user.handle}</p>
              <p className="mt-1 text-xs text-[var(--muted)]">{email}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setEditing((value) => !value)}
            className="inline-flex min-h-10 items-center gap-1 rounded-full px-3 text-sm text-[var(--muted)]"
          >
            <Pencil size={14} /> {editing ? 'Close' : 'Edit'}
          </button>
        </div>
        {user.bio && <p className="mt-4 text-sm leading-relaxed">{user.bio}</p>}
        <p className="mt-4 text-sm text-[var(--muted)]">{notesCount} notes on this device</p>
      </div>

      {editing && (
        <form
          className="mt-4 space-y-3 rounded-[28px] bg-white/70 p-5 ring-1 ring-black/5 dark:bg-white/5"
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
            className="min-h-12 w-full rounded-2xl bg-[var(--paper)] px-3 text-sm outline-none"
          />
          <input
            value={draft.handle}
            onChange={(event) => setDraft({ ...draft, handle: event.target.value })}
            placeholder="Handle"
            className="min-h-12 w-full rounded-2xl bg-[var(--paper)] px-3 text-sm outline-none"
          />
          <textarea
            value={draft.bio}
            onChange={(event) => setDraft({ ...draft, bio: event.target.value })}
            placeholder="A line about you"
            className="min-h-24 w-full rounded-2xl bg-[var(--paper)] px-3 py-3 text-sm outline-none"
          />
          <div className="flex flex-wrap gap-2">
            {PROFILE_HUES.map((hue) => (
              <button
                key={hue}
                type="button"
                aria-label={`Color ${hue}`}
                onClick={() => setDraft({ ...draft, hue })}
                className="h-8 w-8 rounded-full"
                style={{ backgroundColor: hue, outline: draft.hue === hue ? '2px solid var(--ink)' : undefined }}
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
            <button type="button" onClick={() => photoRef.current?.click()} className="rounded-full px-3 py-2 text-sm">
              Photo
            </button>
            <button type="button" onClick={() => setDraft({ ...draft, avatar: null })} className="rounded-full px-3 py-2 text-sm">
              Remove
            </button>
          </div>
          {photoError && <p className="text-sm text-red-700">{photoError}</p>}
          <button type="submit" className="min-h-12 w-full rounded-full bg-[var(--ink)] text-sm font-semibold text-[var(--paper)]">
            Save profile
          </button>
        </form>
      )}

      <div className="mt-4 grid gap-2">
        <button type="button" onClick={onExportMarkdown} className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm dark:bg-white/5">
          <Download size={16} /> Export as Markdown
        </button>
        <button type="button" onClick={onExportJson} className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm dark:bg-white/5">
          <FileJson size={16} /> Export as JSON
        </button>
        <button type="button" onClick={() => importRef.current?.click()} className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm dark:bg-white/5">
          <FileJson size={16} /> Import JSON backup
        </button>
        <button type="button" onClick={onOpenTrash} className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm dark:bg-white/5">
          <Trash2 size={16} /> Trash
        </button>
        <button type="button" onClick={onLogout} className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm text-red-700 dark:bg-white/5">
          <LogOut size={16} /> Sign out
        </button>
        <Link href="/privacy/" className="flex min-h-12 items-center gap-3 rounded-2xl bg-white/70 px-4 text-left text-sm dark:bg-white/5">
          Privacy policy
        </Link>
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
      </div>
      <p className="mt-6 text-center text-xs text-[var(--muted)]">
        Notes stay on this device, isolated to {email}.
      </p>
    </section>
  )
}
