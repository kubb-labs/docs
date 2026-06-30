---
layout: doc
title: Barrel files
description: Generate index.ts barrel files for every plugin output directory using @kubb/plugin-barrel, a post-enforced plugin built into Kubb.
outline: deep
---

# Barrel files

A barrel file is an `index.ts` that re-exports everything from a directory. Consumers of the generated code then import from one place instead of reaching into individual files, which keeps their imports short and stable. Kubb generates these files through [`@kubb/plugin-barrel`](/plugins/plugin-barrel/).

## Quick start

`@kubb/plugin-barrel` is included by default when you import `defineConfig` from the `kubb` package. To change how barrels are generated, add it to your `plugins` array.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginBarrel } from '@kubb/plugin-barrel'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginBarrel()],
})
```

## How it works

`@kubb/plugin-barrel` uses `enforce: 'post'`, so it runs after all regular plugins finish. By that point the output tree is complete, so it can walk it and create an `index.ts` in each directory, then a root `index.ts` at the top of `output.path` that re-exports from every plugin directory.

## Exports

| Export           | Purpose                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `pluginBarrel`   | Plugin factory that emits barrel files based on `output.barrel`.  |
| `pluginBarrelName` | Stable string identifier (`'plugin-barrel'`).                  |

> [!NOTE]
> Valid `barrel.type` values are `'all'` and `'named'`. At the plugin level, set `barrel: { type: 'named', nested: true }` for hierarchical barrels, or `barrel: false` to opt out for that plugin.
