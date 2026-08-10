---
layout: doc
title: Storage
description: Storage backends decide where generated files are written. Covers createStorage, the Storage interface, and the built-in fsStorage and memoryStorage backends.
outline: [2, 3]
---

# Storage

Storage backends decide where generated files are written. Kubb ships a filesystem backend and an in-memory one. Use `createStorage` to build your own.

## `createStorage`

`createStorage` takes a builder function `(options: TOptions) => StorageDefinition` and returns a factory `(options?: TOptions) => Storage`. Call the returned factory to instantiate the storage, optionally with options.

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

Method names follow Node's filesystem vocabulary, so `readItem` reads like `readFile`, `writeItem` like `writeFile`, and `ensureItem` like fs-extra's `ensureFile`.

> [!TIP]
> Use `memoryStorage` for tests and dry runs. Use `fsStorage` for normal development and CI/CD.

## `Storage` interface {#storage-interface}

The `Storage` interface is the shape every backend implements. A `Storage` instance is what the engine consumes at build time and returns from `driver.storage`.

| Method         | Params                                            | Returns                   | Purpose                                       |
| -------------- | ------------------------------------------------- | ------------------------- | --------------------------------------------- |
| `existsItem()` | `key: string`                                     | `Promise<boolean>`        | Check whether an item exists                  |
| `readItem()`   | `key: string`                                     | `Promise<string \| null>` | Retrieve an item's content                    |
| `writeItem()`  | `key: string, value: string`                      | `Promise<void>`           | Write an item                                 |
| `ensureItem()` | `key: string, factory: () => string \| Promise<string>` | `Promise<string>`   | Read an item, writing the factory result first when it is missing |
| `removeItem()` | `key: string`                                     | `Promise<void>`           | Delete an item                                |
| `readKeys()`   | `base?: string`                                   | `Promise<string[]>`       | List keys, optionally filtered by prefix      |
| `empty()`      | `base?: string`                                   | `Promise<void>`           | Delete all items, optionally scoped by prefix |

`ensureItem` is the one method a backend can leave out. The builder returns a `StorageDefinition`, where `ensureItem` is optional, and `createStorage` derives one from `readItem` and `writeItem` when it is missing. A stored empty string counts as present, so the factory runs only when the key holds nothing at all. Implement it yourself when the backend can do the read and the conditional write in one atomic operation.

## `fsStorage`

`fsStorage` is the built-in filesystem storage backend, used by default when no `storage` option is set in the config. It creates output directories automatically and respects `output.path`.

## `memoryStorage`

`memoryStorage` is the built-in in-memory storage backend that writes nothing to disk, so it suits plugin tests, CI validation, and dry runs.

> [!NOTE]
> Both `fsStorage` and `memoryStorage` are exported from `kubb/kit` and can be passed directly to the `storage` field at the root of your config.

### Related

- [Storage concepts](/docs/5.x/guide/concepts/storage)
- [Configuration reference](/docs/5.x/reference/configuration)
