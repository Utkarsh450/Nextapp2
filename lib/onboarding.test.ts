import assert from 'node:assert/strict'
import test from 'node:test'
import { hasFinishedOnboarding, parseOnboarded } from './onboarding.ts'

test('onboarding list is keyed by email and ignores junk', () => {
  assert.deepEqual(parseOnboarded(null), [])
  assert.deepEqual(parseOnboarded('not-json'), [])
  assert.deepEqual(parseOnboarded('["Ada@Notes.Dev"]'), ['ada@notes.dev'])
  assert.equal(hasFinishedOnboarding('ada@notes.dev', '["ada@notes.dev"]'), true)
  assert.equal(hasFinishedOnboarding('sam@notes.dev', '["ada@notes.dev"]'), false)
})
