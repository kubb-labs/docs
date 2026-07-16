---
layout: doc
title: Add barrel files support
description: Generate index.ts barrel files for every plugin output directory with @kubb/plugin-barrel, the post-enforced plugin built into Kubb.
outline: deep
---

# Add barrel files support

A barrel file is an `index.ts` that re-exports everything from a directory. Consumers of the generated code then import from one place instead of reaching into individual files, which keeps their imports short and stable. Kubb generates these files through [`@kubb/plugin-barrel`](/plugins/plugin-barrel/).

`@kubb/plugin-barrel` ships inside `kubb`, and `defineConfig` registers it for you, but `output.barrel` defaults to `false`, so it generates nothing until you opt in. This guide shows how to configure it into the barrels your project needs.

Toggle the export style and barrel depth to see what each `index.ts` re-exports.

<BarrelTree />

## Configure the root barrel

Set `output.barrel` on `defineConfig` to control the root `index.ts` and the default every plugin inherits. The `type` field picks the export style.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [],
})
```

To tune the behavior yourself, add `pluginBarrel` to the `plugins` array. It reads the same `output.barrel` settings.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginBarrel } from '@kubb/plugin-barrel'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginBarrel()],
})
```

## Choose an export style

`type` is required whenever `output.barrel` is set to an object, and accepts `'named'` or `'all'`. Use `'named'` to re-export each symbol by name, which keeps tree-shaking accurate and imports explicit. Use `'all'` for a smaller barrel that re-exports everything with `export *`.

::: code-group

```typescript ['named']
// src/gen/index.ts
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript ['all']
// src/gen/index.ts
export * from './api/user'
export * from './api/post'
export * from './api/types/User'
```

:::

## Adjust a single plugin

A plugin inherits `output.barrel` from `config.output.barrel` when it sets none of its own. Override it on the plugin to change or drop that plugin's barrel.

Set `barrel: { type, nested: true }` on a plugin to write an `index.ts` in every subdirectory, so callers can import from any depth. The root `output.barrel` has no `nested` field and always stays flat.

```typescript twoslash [Nested barrels]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'api', barrel: { type: 'all', nested: true } } })],
})
```

Set `barrel: false` on a plugin to skip its barrel and drop its files from the root barrel.

```typescript twoslash [Disable a plugin barrel]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod({ output: { path: 'zod', barrel: false } })],
})
```

## Turn barrels off

`barrel: false` is already the default, so a fresh config needs no change. Set it explicitly on `defineConfig` to override a root barrel enabled elsewhere, for example a shared base config. Every plugin without its own `output.barrel` inherits the `false`, while a plugin that sets its own non-false `output.barrel` keeps its barrel.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: false },
  plugins: [],
})
```

## See also

- [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) for the plugin overview and examples
- [Options](/plugins/plugin-barrel/reference/options) for every `output.barrel` field
