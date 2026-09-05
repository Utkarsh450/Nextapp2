import { useCallback, useEffect, useState } from 'react'
import type { AuthSession } from '@/lib/auth'
import { authFetch, clearAuthToken, loadAuthOrigin, readAuthToken, writeAuthToken } from '@/lib/auth/client'
import { peekAuthToken } from '@/lib/auth/offlineSession'
import { applyLayoutClass, applySkinClass, applyThemeClass, readLayout, readSkin, readTheme, writeLayout, writeSkin, writeTheme, type BoardLayout, type PaperSkin, type ThemeMode } from '@/lib/theme'

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

export const useSkin = () => {
  const [skin, setSkin] = useState<PaperSkin>('classic')

  useEffect(() => {
    const next = readSkin()
    applySkinClass(next)
    if (next !== 'classic') {
      // Hydrate from localStorage after mount to avoid a server/client mismatch.
      // eslint-disable-next-line react-hooks/set-state-in-effect -- localStorage is only available on the client
      setSkin(next)
    }
  }, [])

  const setPaperSkin = useCallback((next: PaperSkin) => {
    setSkin(next)
    writeSkin(next)
    applySkinClass(next)
  }, [])

  return { skin, setPaperSkin }
}

export const useLayout = () => {
  const [layout, setLayout] = useState<BoardLayout>('masonry')

  useEffect(() => {
    const next = readLayout()
    applyLayoutClass(next)
    if (next !== 'masonry') {
      // Hydrate from localStorage after mount to avoid a server/client mismatch.
      // eslint-disable-next-line react-hooks/set-state-in-effect -- localStorage is only available on the client
      setLayout(next)
    } else {
      applyLayoutClass('masonry')
    }
  }, [])

  const setBoardLayout = useCallback((next: BoardLayout) => {
    setLayout(next)
    writeLayout(next)
    applyLayoutClass(next)
  }, [])

  return { layout, setBoardLayout }
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
