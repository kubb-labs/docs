---
layout: doc
title: Storage
description: Storage backends decide where generated files are written. Covers
  createStorage, the Storage interface, and the built-in fsStorage and
  memoryStorage backends.
outline:
  - 2
  - 3
order: 7
---

# Storage

Storage backends persist generated files in the filesystem, memory, or a custom destination.

## `createStorage`

`createStorage` takes a builder function `(options: TOptions) => Storage` and returns a factory `(options?: TOptions) => Storage`. Call the returned factory to create a backend.

```typescript twoslash [memory-storage.ts]
import { createStorage } from 'kubb/kit'

export const memoryStorage = createStorage(() => {
  const store = new Map<string, string>()
  return {
    name: 'memory',
    async existsItem(key) {
      return store.has(key)
    },
    async readItem(key) {
      return store.get(key) ?? null
    },
    async writeItem(key, value) {
      store.set(key, value)
    },
    async removeItem(key) {
      store.delete(key)
    },
    async readKeys(base) {
      const keys = [...store.keys()]
      return base ? keys.filter((k) => k.startsWith(base)) : keys
    },
    async empty(base) {
      if (!base) return store.clear()
      for (const k of store.keys()) if (k.startsWith(base)) store.delete(k)
    },
  }
})
```

> [!TIP]
> Use `memoryStorage` for tests and dry runs. Use `fsStorage` for normal development and CI/CD.

## `Storage` interface {#storage-interface}

The engine consumes this interface and exposes the backend through the build result.

| Method         | Params                       | Returns                   | Purpose                                       |
| -------------- | ---------------------------- | ------------------------- | --------------------------------------------- |
| `existsItem()` | `key: string`                | `Promise<boolean>`        | Check whether an item exists                  |
| `readItem()`   | `key: string`                | `Promise<string \| null>` | Retrieve an item's content                    |
| `writeItem()`  | `key: string, value: string` | `Promise<void>`           | Write an item                                 |
| `removeItem()` | `key: string`                | `Promise<void>`           | Delete an item                                |
| `readKeys()`   | `base?: string`              | `Promise<string[]>`       | List keys, optionally filtered by prefix      |
| `empty()`      | `base?: string`              | `Promise<void>`           | Delete all items, optionally scoped by prefix |

Omitting `base` on `empty()` is implementation-defined. `memoryStorage` wipes every entry, while the filesystem-backed `fsStorage` treats a missing `base` as a no-op and deletes nothing.

Every method is required. `readItem` returns `null` for a missing key. Kubb skips `writeItem` when content matches after trimming surrounding whitespace, so writes do not count every generated file.

## `fsStorage`

`fsStorage` is the built-in filesystem storage backend, used by default when no `storage` option is set in the config. It creates output directories automatically and respects `output.path`.

## `memoryStorage`

`memoryStorage` is the built-in in-memory storage backend that writes nothing to disk, so it suits plugin tests, CI validation, and dry runs.

> [!NOTE]
> Both `fsStorage` and `memoryStorage` are exported from `kubb/kit` and can be passed directly to the `storage` field at the root of your config.


## See also

- [Storage concepts](/docs/5.x/explanation/architecture#storage)
- [Configuration reference](/docs/5.x/reference/configuration)
