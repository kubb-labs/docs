---
layout: doc
title: Barrel files
description: Generate index.ts barrel files for every plugin output directory using @kubb/plugin-barrel, a post-enforced plugin built into Kubb.
outline: deep
---

# Barrel files

Barrel files are `index.ts` files that re-export everything from a directory, making imports cleaner for consumers of generated code. Kubb generates them automatically through [`@kubb/plugin-barrel`](/plugins/plugin-barrel).

## Quick start

`@kubb/plugin-barrel` is included by default when you import `defineConfig` from the top-level `kubb` package. To change how barrels are generated, add it explicitly to your `plugins` array:

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginBarrel } from '@kubb/plugin-barrel'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginBarrel()],
})
```

## How it works

`@kubb/plugin-barrel` uses `enforce: 'post'` so it always runs after all regular plugins finish. It walks the output tree and creates an `index.ts` in each directory, then creates a root `index.ts` at the top of `output.path` that re-exports from all plugin directories.

## Options

| Export           | Purpose                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `pluginBarrel`   | Plugin factory that emits barrel files based on `output.barrel`.  |
| `pluginBarrelName` | Stable string identifier (`'plugin-barrel'`).                  |

> [!NOTE]
> Valid `barrel.type` values are `'all'` and `'named'`. At the plugin level, set `barrel: { type: 'named', nested: true }` for hierarchical barrels, or `barrel: false` to opt out for that plugin.
