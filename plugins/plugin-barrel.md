---
layout: doc
title: Kubb Barrel Plugin
description: Generates `index.ts` re-export files for every plugin output and
  one root barrel. Ships with Kubb and is enabled by default.
outline: 2
kind: plugin
id: plugin-barrel
---

> [!TIP]
> `plugin-barrel` ships with Kubb and is enabled automatically. Install it explicitly only when customizing barrel behavior.

`@kubb/plugin-barrel` generates an `index.ts` for every plugin output directory and one root barrel at `output.path/index.ts` after the build completes. Consumers then import from a single entry point, such as `import { Pet, usePetByIdQuery, petMock } from './gen'`.

The plugin ships with Kubb and is registered by default in `defineConfig`, so barrels appear out of the box with no extra configuration. When `pluginBarrel` is part of `config.plugins`, `defineConfig` also applies a default `output.barrel` of `{ type: 'named' }`.

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

Re-export style used for every generated barrel file. Set via `output.barrel` in `defineConfig` (applies to all plugins and the root barrel) or per plugin via that plugin's own `output.barrel`. It is not an argument to the plugin itself.

At the config level:

- `{ type: 'all' }`: writes `export * from '...'` for every generated file.
- `{ type: 'named' }`: writes `export { Foo, Bar } from '...'` from each file's named exports.
- `false`: turns off barrel generation.

At the plugin level you also get `nested`:

- `{ type: 'named', nested: true }`: generates a barrel for every subdirectory, re-exporting only direct children, so callers can import from any depth.
- `false`: turns off the plugin's barrel and removes its files from the root barrel.

The `{ type: 'named' }` default kicks in only when `pluginBarrel` is part of `config.plugins`.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

```typescript [kubb.config.ts]
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

```typescript [{ type: 'named' } (default)]
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

```typescript [{ type: 'all' }]
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

```typescript [{ type: 'named', nested: true }]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named', nested: true } },
  plugins: [],
})
```

```typescript [Generated output (chained structure)]
// src/gen/index.ts (only exports directories)
export * from './api'
export * from './hooks'

// src/gen/api/index.ts (exports files and subdirs)
export * from './user'
export * from './post'
export * from './types'

// src/gen/api/types/index.ts (exports files)
export * from './User'
```

```typescript [Disable the barrel for a single plugin]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

// pluginZod opts out: no zod/index.ts is created,
// and zod files are excluded from the root index.ts.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod({ output: { barrel: false } })],
})
```

```typescript [Disable only the root barrel]
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
