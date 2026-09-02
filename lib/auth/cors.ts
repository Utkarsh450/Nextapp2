import { NextResponse } from 'next/server'

export const corsHeaders = {
  'Access-Control-Allow-Origin': process.env.AUTH_CORS_ORIGIN || '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

export const withCors = (response: NextResponse) => {
  for (const [key, value] of Object.entries(corsHeaders)) {
    response.headers.set(key, value)
  }
  return response
}

export const corsPreflight = () => withCors(new NextResponse(null, { status: 204 }))
