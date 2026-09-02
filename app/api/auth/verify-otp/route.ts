import { NextResponse } from 'next/server'
import { corsPreflight, withCors } from '../../../../lib/auth/cors'
import { userFromEmail } from '../../../../lib/auth'
import { createSessionToken, sessionCookieOptions } from '../../../../lib/auth/session'
import { verifyEmailOtp } from '../../../../lib/auth/otp'

export async function OPTIONS() {
  return corsPreflight()
}

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}))
  const result = await verifyEmailOtp(String(body.email || ''), String(body.otp || ''))
  if (!result.ok) {
    return withCors(NextResponse.json(result, { status: 400 }))
  }

  const profile = userFromEmail(result.email)
  const token = createSessionToken(result.email)
  const response = NextResponse.json({
    ok: true,
    token,
    session: { email: result.email, name: profile.name, handle: profile.handle },
  })
  response.cookies.set({
    ...sessionCookieOptions,
    value: token,
  })
  return withCors(response)
}
