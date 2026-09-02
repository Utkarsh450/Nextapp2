import assert from 'node:assert/strict'
import test from 'node:test'
import { isValidEmail, normalizeEmail, userFromEmail } from './index.ts'
import { peekAuthToken } from './offlineSession.ts'

test('email helpers', () => {
  assert.equal(normalizeEmail('  Ada@Notes.Dev '), 'ada@notes.dev')
  assert.equal(isValidEmail('ada@notes.dev'), true)
  assert.equal(isValidEmail('nope'), false)
  const user = userFromEmail('ada.chen@notes.dev')
  assert.equal(user.email, 'ada.chen@notes.dev')
  assert.equal(user.handle, '@ada.chen')
  assert.match(user.name, /Ada/)
})

test('offline session peeks a token without the network', () => {
  const payload = Buffer.from(JSON.stringify({
    email: 'ada@notes.dev',
    exp: Date.now() + 60_000,
  })).toString('base64url')
  const session = peekAuthToken(`${payload}.offline`)
  assert.equal(session?.email, 'ada@notes.dev')
  assert.equal(peekAuthToken(`${payload}.offline`, Date.now() + 120_000), null)
  assert.equal(peekAuthToken(null), null)
})
