import { existsSync, renameSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const api = join(root, 'app/api')
const hidden = join(root, '.cap-api-hidden')

const hideApi = () => {
  if (existsSync(api)) renameSync(api, hidden)
}

const restoreApi = () => {
  if (existsSync(hidden)) renameSync(hidden, api)
}

hideApi()

try {
  const result = spawnSync('pnpm', ['exec', 'next', 'build'], {
    cwd: root,
    stdio: 'inherit',
    env: { ...process.env, NEXT_OUTPUT: 'export' },
    shell: process.platform === 'win32',
  })
  process.exitCode = result.status ?? 1
} finally {
  restoreApi()
}
