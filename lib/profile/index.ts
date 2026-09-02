export const PROFILE_KEY = 'notes-board-profiles'
export const PROFILE_HUES = ['#18181b', '#7c3aed', '#0f766e', '#be185d', '#c2410c', '#1d4ed8', '#a16207'] as const

const emailKey = (value: string) => value.trim().toLowerCase()

export type UserProfile = {
  name: string
  handle: string
  bio: string
  location: string
  website: string
  hue: string
  avatar: string | null
}

export type AccountUser = UserProfile & {
  email: string
  initials: string
}

export const initialsFromName = (name: string) => {
  const initials = name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase()
  return initials || 'YO'
}

export const normalizeHandle = (value: string) => {
  const cleaned = value.trim().replace(/^@+/, '').toLowerCase().replace(/[^a-z0-9._]/g, '').slice(0, 18)
  return `@${cleaned || 'you'}`
}

export const sanitizeWebsite = (value: string) => {
  const trimmed = value.trim()
  if (!trimmed) return ''
  if (/^https?:\/\//i.test(trimmed)) return trimmed.slice(0, 80)
  return `https://${trimmed}`.slice(0, 80)
}

export const profileFromEmail = (email: string): UserProfile => {
  const local = emailKey(email).split('@')[0] || 'you'
  const name = local
    .replace(/[._-]+/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
  return {
    name: name || 'You',
    handle: normalizeHandle(local),
    bio: '',
    location: '',
    website: '',
    hue: '#18181b',
    avatar: null,
  }
}

export const sanitizeProfile = (partial: Partial<UserProfile>, fallback: UserProfile): UserProfile => {
  const hue = PROFILE_HUES.includes(partial.hue as typeof PROFILE_HUES[number]) ? partial.hue as string : fallback.hue
  const avatar = partial.avatar === null || (typeof partial.avatar === 'string' && partial.avatar.startsWith('data:image/'))
    ? partial.avatar
    : fallback.avatar

  return {
    name: (partial.name ?? fallback.name).trim().slice(0, 40) || fallback.name,
    handle: normalizeHandle(partial.handle ?? fallback.handle),
    bio: (partial.bio ?? fallback.bio).trim().slice(0, 160),
    location: (partial.location ?? fallback.location).trim().slice(0, 40),
    website: sanitizeWebsite(partial.website ?? fallback.website),
    hue,
    avatar,
  }
}

export const profileToAccountUser = (profile: UserProfile, email: string): AccountUser => ({
  ...profile,
  email: emailKey(email),
  initials: initialsFromName(profile.name),
})

export const parseProfiles = (raw: string | null): Record<string, UserProfile> => {
  if (!raw) return {}
  try {
    const parsed = JSON.parse(raw) as unknown
    if (!parsed || typeof parsed !== 'object') return {}
    const entries = Object.entries(parsed as Record<string, Partial<UserProfile>>)
    return Object.fromEntries(
      entries.map(([email, value]) => {
        const fallback = profileFromEmail(email)
        return [emailKey(email), sanitizeProfile(value ?? {}, fallback)]
      })
    )
  } catch {
    return {}
  }
}

export const upsertProfile = (
  store: Record<string, UserProfile>,
  email: string,
  profile: UserProfile
) => ({
  ...store,
  [emailKey(email)]: profile,
})

export const accountUserFromStoredProfile = (email: string, raw: string | null) => {
  const store = parseProfiles(raw)
  const profile = store[emailKey(email)] ?? profileFromEmail(email)
  return profileToAccountUser(profile, email)
}

export const readStoredProfiles = () => {
  if (typeof localStorage === 'undefined') return {}
  return parseProfiles(localStorage.getItem(PROFILE_KEY))
}

export const writeStoredProfiles = (store: Record<string, UserProfile>) => {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(PROFILE_KEY, JSON.stringify(store))
}

export const saveProfileForEmail = (email: string, profile: UserProfile) => {
  const next = upsertProfile(readStoredProfiles(), email, profile)
  writeStoredProfiles(next)
  return next
}
