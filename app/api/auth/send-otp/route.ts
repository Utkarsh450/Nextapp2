import { NextResponse } from 'next/server'
import { corsPreflight, withCors } from '../../../../lib/auth/cors'
import { sendEmailOtp } from '../../../../lib/auth/otp'

export async function OPTIONS() {
  return corsPreflight()
}

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}))
  const result = await sendEmailOtp(String(body.email || ''))
  return withCors(NextResponse.json(result, { status: result.ok ? 200 : 400 }))
}
