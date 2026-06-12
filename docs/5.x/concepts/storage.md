---
layout: doc
title: Storage - Control File Output Backends
description: Control where Kubb writes generated files. Use fsStorage for disk output, memoryStorage for testing, or build a custom driver with createStorage.
outline: deep
---

# Storage

The storage driver controls where Kubb writes generated files. Configure it via the [`storage`](/docs/5.x/reference/configuration#storage) option in [`kubb.config.ts`](/docs/5.x/reference/configuration). When `storage` is omitted, Kubb defaults to `fsStorage()`, the built-in filesystem driver. Swap it with `memoryStorage()` for tests or implement the `Storage` interface to target any backend.

## Storage interface

Every driver must implement the `Storage` interface exported from [`@kubb/core`](https://www.npmjs.com/package/@kubb/core):

| Member       | Signature                                       | Purpose                                            |
| ------------ | ----------------------------------------------- | -------------------------------------------------- |
| `name`       | `string`                                        | Identifier used in logs and debug output           |
| `hasItem`    | `(key: string) => Promise<boolean>`             | Returns `true` when the key exists                 |
| `getItem`    | `(key: string) => Promise<string \| null>`      | Returns the stored value, or `null` when missing   |
| `setItem`    | `(key: string, value: string) => Promise<void>` | Persists a value under `key`                       |
| `removeItem` | `(key: string) => Promise<void>`                | Removes the entry for `key`                        |
| `getKeys`    | `(base?: string) => Promise<Array<string>>`     | Lists all keys, optionally filtered by prefix      |
| `clear`      | `(base?: string) => Promise<void>`              | Removes all entries, optionally scoped to a prefix |
| `dispose`    | `() => Promise<void>` (optional)                | Teardown hook called after the build completes     |

Keys are root-relative paths (e.g. `src/gen/api/getPets.ts`).

## Built-in drivers

### `fsStorage`

`fsStorage` writes files to the local filesystem. Kubb uses it when no `storage` option is configured.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { fsStorage } from '@kubb/core'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: fsStorage(),
})
```

Keys resolve against the configured `root` (defaults to `process.cwd()`). The driver skips writes when file content is already identical and creates missing parent directories automatically. Calling `clear()` without a `base` argument is a no-op. Pass a path prefix to remove a specific subtree.

### `memoryStorage`

`memoryStorage` stores all output in a `Map`. Nothing is written to disk, which makes it useful for testing, CI validation, and dry-run scenarios.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { memoryStorage } from '@kubb/core'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: memoryStorage(),
})
```

Each call to `memoryStorage()` creates an independent `Map` instance. Read back the generated output with `storage.getKeys()` and `storage.getItem(key)` after the build completes.

## Creating a custom driver

`createStorage` from [`@kubb/core`](/docs/5.x/api/core) wraps any backend. Pass a factory function that receives your options and returns a `Storage` implementation.

```typescript twoslash [s3Storage.ts]
import { createStorage } from '@kubb/core'

export const s3Storage = createStorage<{ bucket: string }>((options) => {
  return {
    name: 's3',
    async hasItem(key) {
      return false
    },
    async getItem(key) {
      return null
    },
    async setItem(key, value) {
      // upload to S3
    },
    async removeItem(key) {
      // delete from S3
    },
    async getKeys(base) {
      return []
    },
    async clear(base) {
      // batch delete from S3
    },
    async dispose() {
      // close any open connections
    },
  }
})
```

Pass it in `kubb.config.ts`:

```typescript twoslash [kubb.config.ts]
// @noErrors
import { defineConfig } from 'kubb'
import { s3Storage } from './s3Storage.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: s3Storage({ bucket: process.env.S3_BUCKET! }),
})
```

## Testing with `memoryStorage`

Use `memoryStorage` in tests to capture generated files without writing to disk:

```typescript twoslash [plugin.test.ts]
// @noErrors
import { createKubb, memoryStorage } from '@kubb/core'

const storage = memoryStorage()

const kubb = createKubb({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage,
  plugins: [],
})

const { error } = await kubb.build()

if (!error) {
  const keys = await storage.getKeys()
  const content = await storage.getItem(keys[0]!)
  console.log(content)
}
```

See [Testing your plugin locally](/docs/5.x/concepts/plugins#testing-your-plugin-locally) for a complete plugin test setup.
