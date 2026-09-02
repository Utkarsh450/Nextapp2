import { useCallback, useEffect, useState } from 'react'
import type { AuthSession } from '@/lib/auth'
import { authFetch, clearAuthToken, loadAuthOrigin, readAuthToken, writeAuthToken } from '@/lib/auth/client'
import { peekAuthToken } from '@/lib/auth/offlineSession'
import { applyThemeClass, readTheme, writeTheme, type ThemeMode } from '@/lib/theme'

export const useTheme = () => {
  const [theme, setTheme] = useState<ThemeMode>('light')

  useEffect(() => {
    const next = readTheme()
    applyThemeClass(next)
    if (next !== 'light') {
      // Hydrate from localStorage after mount to avoid a server/client mismatch.
      // eslint-disable-next-line react-hooks/set-state-in-effect -- localStorage is only available on the client
      setTheme(next)
    }
  }, [])

  const toggle = useCallback(() => {
    setTheme((current) => {
      const next = current === 'dark' ? 'light' : 'dark'
      writeTheme(next)
      applyThemeClass(next)
      return next
    })
  }, [])

  return { theme, toggle }
}

const localSession = () => peekAuthToken(readAuthToken())

export const useSession = () => {
  const [session, setSession] = useState<AuthSession | null>(null)
  const [loading, setLoading] = useState(true)
  const [origin, setOrigin] = useState('')

  const refresh = useCallback(async (authOrigin = origin) => {
    try {
      const response = await authFetch('/api/auth/session', { method: 'GET' }, authOrigin)
      const data = await response.json() as { session?: AuthSession | null }
      setSession(data.session ?? localSession())
    } catch {
      setSession(localSession())
    } finally {
      setLoading(false)
    }
  }, [origin])

  useEffect(() => {
    let cancelled = false
    void loadAuthOrigin().then((nextOrigin) => {
      if (cancelled) return
      setOrigin(nextOrigin)
      void (async () => {
        try {
          const response = await authFetch('/api/auth/session', { method: 'GET' }, nextOrigin)
          const data = await response.json() as { session?: AuthSession | null }
          if (!cancelled) setSession(data.session ?? localSession())
        } catch {
          if (!cancelled) setSession(localSession())
        } finally {
          if (!cancelled) setLoading(false)
        }
      })()
    })
    return () => {
      cancelled = true
    }
  }, [])

  const sendOtp = useCallback(async (email: string) => {
    const response = await authFetch('/api/auth/send-otp', {
      method: 'POST',
      body: JSON.stringify({ email }),
    }, origin)
    return response.json() as Promise<{ ok?: boolean; error?: string; via?: string }>
  }, [origin])

  const verifyOtp = useCallback(async (email: string, otp: string) => {
    const response = await authFetch('/api/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ email, otp }),
    }, origin)
    const data = await response.json() as { ok?: boolean; error?: string; session?: AuthSession; token?: string }
    if (data.token) writeAuthToken(data.token)
    if (data.ok && data.session) setSession(data.session)
    return data
  }, [origin])

  const logout = useCallback(async () => {
    try {
      await authFetch('/api/auth/logout', { method: 'POST' }, origin)
    } catch {
      // Local sign-out still works if the hosted API is unreachable.
    }
    clearAuthToken()
    setSession(null)
  }, [origin])

  return { session, loading, sendOtp, verifyOtp, logout, refresh }
}
