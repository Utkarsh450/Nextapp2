import { NextResponse } from 'next/server'
import { corsPreflight, withCors } from '../../../../lib/auth/cors'
import { sessionCookieOptions } from '../../../../lib/auth/session'

export async function OPTIONS() {
  return corsPreflight()
}

export async function POST() {
  const response = NextResponse.json({ ok: true })
  response.cookies.set({
    ...sessionCookieOptions,
    value: '',
    maxAge: 0,
  })
  return withCors(response)
}
