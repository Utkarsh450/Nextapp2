import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { AUTH_COOKIE } from '../../../../lib/auth'
import { corsPreflight, withCors } from '../../../../lib/auth/cors'
import { readSessionToken, tokenFromRequest } from '../../../../lib/auth/session'

export async function OPTIONS() {
  return corsPreflight()
}

export async function GET(request: Request) {
  const cookie = (await cookies()).get(AUTH_COOKIE)?.value
  const session = readSessionToken(tokenFromRequest(request, cookie))
  return withCors(NextResponse.json({ session }))
}
