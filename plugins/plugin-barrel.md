---
layout: doc
title: Kubb Barrel Plugin
description: Generates `index.ts` re-export files for every plugin output and
  one root barrel. Ships with Kubb and is enabled by default.
outline: 2
kind: plugin
id: plugin-barrel
name: Barrel
category: output
type: official
npmPackage: "@kubb/plugin-barrel"
repo: https://github.com/kubb-labs/kubb
docsPath: /plugins/plugin-barrel
featured: true
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - barrel
  - index
  - exports
  - output
resources:
  documentation: https://kubb.dev/plugins/plugin-barrel
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md
---

> [!TIP]
> `plugin-barrel` ships with Kubb and is enabled automatically. Install it explicitly only when customizing barrel behavior.

`@kubb/plugin-barrel` generates an `index.ts` for every plugin output directory and one root barrel at `output.path/index.ts` after the build completes, so consumers import from a single entry point, such as `import { Pet, usePetByIdQuery, petMock } from './gen'`.

The plugin ships with Kubb and is registered by default in `defineConfig`, so barrels appear with no extra configuration. When `pluginBarrel` is part of `config.plugins`, `defineConfig` also applies a default `output.barrel` of `{ type: 'named' }`.

Plugins inherit `output.barrel` from `config.output.barrel` when their own value is omitted. Setting `barrel: false` on a plugin disables that plugin's barrel and excludes its files from the root barrel.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-barrel@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-barrel@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-barrel@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-barrel@beta
```

:::

## Options

### barrel

Sets the re-export style for generated barrel files. `pluginBarrel` takes no arguments, so you configure it through `output.barrel`: set it on `defineConfig` to control the root barrel and the default every plugin inherits, or on an individual plugin to override that plugin's barrel.

The `type` field picks the export style. `{ type: 'all' }` writes `export * from '...'` for every generated file, `{ type: 'named' }` writes `export { Foo, Bar } from '...'` from each file's named exports, and `false` turns off barrel generation.

A plugin's `output.barrel` also accepts `nested`. With `{ type: 'named', nested: true }` the plugin writes an `index.ts` in every subdirectory, each re-exporting only what sits directly inside it. The root `output.barrel` has no `nested` field, so it always stays flat.

Setting `barrel: false` on `defineConfig` disables only the root barrel and each plugin still emits its own. Setting `barrel: false` on a plugin disables that plugin's barrel and removes its files from the root barrel.

The `{ type: 'named' }` default applies only when `pluginBarrel` is part of `config.plugins`.

| Field | Type | Default | Required |
| --- | --- | --- | --- |
| `type` | `'all' \| 'named'` | `'named'` | `true` (when `barrel` is an object) |
| `nested` | `boolean` | `false` | `false` (plugin-level `output.barrel` only) |

The whole value is `{ type: 'all' \| 'named', nested?: boolean } \| false` at the plugin level and `{ type: 'all' \| 'named' } \| false` at the config level.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginBarrel } from '@kubb/plugin-barrel'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginBarrel()],
})
```

## Example

::: code-group

```typescript twoslash [{ type: 'named' } (default)]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [],
})
```

```typescript [Generated output]
// src/gen/index.ts
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
export { useUser } from './hooks/useUser'

// src/gen/api/index.ts
export { getUser, User } from './user'
export { getPost, Post } from './post'
export { User } from './types/User'

// src/gen/api/types/index.ts
export { User } from './User'
```

```typescript twoslash [{ type: 'all' }]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: { type: 'all' } },
  plugins: [],
})
```

```typescript [Generated output]
// src/gen/index.ts
export * from './api/user'
export * from './api/post'
export * from './api/types/User'
export * from './hooks/useUser'

// src/gen/api/index.ts
export * from './user'
export * from './post'
export * from './types/User'

// src/gen/api/types/index.ts
export * from './User'
```

```typescript twoslash [{ type: 'all', nested: true } (plugin level)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

// nested lives on a plugin's output.barrel, not on the root output.barrel.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'api', barrel: { type: 'all', nested: true } } })],
})
```

```typescript [Generated output (chained structure)]
// src/gen/api/index.ts re-exports its files and subdirectories
export * from './user'
export * from './post'
export * from './types'

// src/gen/api/types/index.ts re-exports its files
export * from './User'

// the root src/gen/index.ts still re-exports the plugin's files,
// using the config-level default ({ type: 'named' })
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript twoslash [Disable the barrel for a single plugin]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

// pluginZod opts out: no zod/index.ts is created,
// and zod files are excluded from the root index.ts.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod({ output: { path: 'zod', barrel: false } })],
})
```

```typescript twoslash [Disable only the root barrel]
import { defineConfig } from 'kubb'

// No root index.ts is generated, but each plugin
// still gets its own barrel using its inherited config.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: false },
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
