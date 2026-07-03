---
layout: doc
title: Storage - How Kubb Decides Where Files Land
description: Understand Kubb's storage layer. The driver decouples code generation from its destination, so the same build can target disk, memory, or any backend you write.
outline: deep
---

# Storage

Storage is the layer that decides where generated files end up. The generation pipeline never writes to disk directly. It hands each file to a storage driver, and the driver decides what to do with it. That one indirection is what lets the same build target the local filesystem in development, an in-memory map during tests, or any backend you write.

## Why a storage layer

A code generator that wrote straight to disk would be hard to test and impossible to embed. Kubb avoids that by treating the destination as a plug-in. The driver exposes a small key-value contract (write a file, read it back, list keys, clear), so the rest of the pipeline stays agnostic about where the bytes go. Keys are root-relative paths such as `src/gen/api/getPets.ts`, which keeps the same file addressable no matter which backend is behind it.

## The built-in drivers

Kubb ships two drivers and uses `fsStorage` when you set no `storage` option.

`fsStorage` writes to the local filesystem. It skips writes when the content on disk is already identical and creates missing parent directories, so a normal `kubb generate` run needs no extra setup.

`memoryStorage` keeps everything in a `Map` and writes nothing to disk. That makes it the driver to reach for in tests, CI validation, and dry runs, where you want to inspect the output without touching the working tree. After a build you read the result back with `storage.getKeys()` and `storage.getItem(key)`.

Swapping the driver is a single field in [`kubb.config.ts`](/docs/5.x/reference/configuration#storage):

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { memoryStorage } from 'kubb/kit'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: memoryStorage(),
})
```

## When to write your own

Build a custom driver when the destination is neither the filesystem nor memory: an object store like S3, a virtual filesystem in the browser, or a remote service. A driver is any object that satisfies the `Storage` contract, and `createStorage` from `kubb/kit` wraps your backend into a reusable factory. The interface, the `createStorage` signature, and a worked example live in the [Kit API reference](/docs/5.x/reference/kit#createstorage).

## Reference

- [Storage in the Kit API](/docs/5.x/reference/kit#storage): `createStorage`, `fsStorage`, and `memoryStorage`.
- [The `Storage` interface](/docs/5.x/reference/kit#storage-interface): the contract every driver implements.
- [`storage` configuration option](/docs/5.x/reference/configuration#storage): where to set the driver.
- [Testing plugins](/docs/5.x/guide/going-further/creating-plugins#testing): capture generated files with `memoryStorage`.
