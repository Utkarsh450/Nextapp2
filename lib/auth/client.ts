export const AUTH_TOKEN_KEY = 'notes-otp-token'

export const authApiOrigin = (override = '') =>
  override.replace(/\/$/, '') || (process.env.NEXT_PUBLIC_AUTH_API_ORIGIN || '').replace(/\/$/, '')

export const authUrl = (path: string, origin = '') => `${authApiOrigin(origin)}${path}`

export const usesRemoteAuth = (origin = '') => Boolean(authApiOrigin(origin))

export const readAuthToken = () => {
  if (typeof localStorage === 'undefined') return null
  return localStorage.getItem(AUTH_TOKEN_KEY)
}

export const writeAuthToken = (token: string) => {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(AUTH_TOKEN_KEY, token)
}

export const clearAuthToken = () => {
  if (typeof localStorage === 'undefined') return
  localStorage.removeItem(AUTH_TOKEN_KEY)
}

export const loadAuthOrigin = async () => {
  const fromEnv = authApiOrigin()
  if (fromEnv) return fromEnv
  try {
    const response = await fetch('/auth-origin.json')
    const data = await response.json() as { origin?: string }
    return authApiOrigin(data.origin || '')
  } catch {
    return ''
  }
}

export const authFetch = async (path: string, init: RequestInit = {}, origin = '') => {
  const headers = new Headers(init.headers)
  if (init.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }
  const token = readAuthToken()
  if (token) headers.set('Authorization', `Bearer ${token}`)
  return fetch(authUrl(path, origin), {
    ...init,
    headers,
    credentials: usesRemoteAuth(origin) ? 'omit' : 'include',
  })
}
