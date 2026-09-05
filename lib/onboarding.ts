export const ONBOARD_KEY = 'notes-board-onboarded'

const emailKey = (value: string) => value.trim().toLowerCase()

export const parseOnboarded = (raw: string | null): string[] => {
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw) as unknown
    if (!Array.isArray(parsed)) return []
    return parsed.filter((item): item is string => typeof item === 'string').map(emailKey)
  } catch {
    return []
  }
}

export const hasFinishedOnboarding = (email: string, raw?: string | null) => {
  const stored = raw ?? (typeof localStorage === 'undefined' ? null : localStorage.getItem(ONBOARD_KEY))
  return parseOnboarded(stored).includes(emailKey(email))
}

export const markOnboardingDone = (email: string) => {
  if (typeof localStorage === 'undefined') return
  const list = parseOnboarded(localStorage.getItem(ONBOARD_KEY))
  const key = emailKey(email)
  if (list.includes(key)) return
  localStorage.setItem(ONBOARD_KEY, JSON.stringify([...list, key]))
}
