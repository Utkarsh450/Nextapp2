import assert from 'node:assert/strict'
import test from 'node:test'
import { isValidEmail, normalizeEmail, userFromEmail } from './index.ts'

test('email helpers', () => {
  assert.equal(normalizeEmail('  Ada@Notes.Dev '), 'ada@notes.dev')
  assert.equal(isValidEmail('ada@notes.dev'), true)
  assert.equal(isValidEmail('nope'), false)
  const user = userFromEmail('ada.chen@notes.dev')
  assert.equal(user.email, 'ada.chen@notes.dev')
  assert.equal(user.handle, '@ada.chen')
  assert.match(user.name, /Ada/)
})
