import assert from 'node:assert/strict'
import test from 'node:test'
import {
  accountUserFromStoredProfile,
  initialsFromName,
  normalizeHandle,
  parseProfiles,
  profileFromEmail,
  profileToAccountUser,
  sanitizeProfile,
  sanitizeWebsite,
  upsertProfile,
} from './index.ts'

test('profile builders sanitize handle, site, and initials', () => {
  assert.equal(normalizeHandle('Ada Chen!'), '@adachen')
  assert.equal(normalizeHandle('@Rahul_Mehta'), '@rahul_mehta')
  assert.equal(sanitizeWebsite('ava.design'), 'https://ava.design')
  assert.equal(initialsFromName('Ada Chen'), 'AC')
  const profile = sanitizeProfile({ name: '  Ada  ', handle: 'ada', website: 'x.com', hue: '#7c3aed' }, profileFromEmail('ada@notes.dev'))
  assert.equal(profile.name, 'Ada')
  assert.equal(profile.handle, '@ada')
  const user = profileToAccountUser(profile, 'ada@notes.dev')
  assert.equal(user.email, 'ada@notes.dev')
  assert.equal(user.initials, 'A')
})

test('profiles store is keyed by email', () => {
  const saved = upsertProfile({}, '  Ada@Notes.Dev ', profileFromEmail('ada@notes.dev'))
  const parsed = parseProfiles(JSON.stringify(saved))
  assert.ok(parsed['ada@notes.dev'])
  assert.equal(parseProfiles('not-json')['x'], undefined)
})

test('stored profile overlays email defaults', () => {
  const raw = JSON.stringify({
    'ada@notes.dev': {
      name: 'Ada Chen',
      handle: '@ada',
      bio: 'Hi',
      location: 'Taipei',
      website: 'ava.design',
      hue: '#7c3aed',
      avatar: null,
    },
  })
  const user = accountUserFromStoredProfile('Ada@notes.dev', raw)
  assert.equal(user.name, 'Ada Chen')
  assert.equal(user.location, 'Taipei')
  assert.equal(user.website, 'https://ava.design')
  const fallback = accountUserFromStoredProfile('new.user@notes.dev', '{}')
  assert.match(fallback.name, /New/)
  assert.equal(fallback.email, 'new.user@notes.dev')
})
