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
> `plugin-barrel` ships with Kubb and runs by default. Install it on its own only when you want to tune barrel behavior.

`@kubb/plugin-barrel` writes the `index.ts` barrel files. It adds one barrel per plugin output directory and one root barrel at `output.path/index.ts`. This runs after the build finishes, so you import everything from one entry point, like `import { Pet, usePetByIdQuery, petMock } from './gen'`.

The plugin is registered by default in `defineConfig`, so barrels appear with no setup. When it runs, the default `output.barrel` is `{ type: 'named' }`.

A plugin inherits `output.barrel` from `config.output.barrel` when it sets none of its own. Set `barrel: false` on a plugin to skip its barrel and drop its files from the root barrel.

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

### output.barrel

Sets the re-export style for barrel files. `pluginBarrel` takes no arguments. You configure it through `output.barrel` instead. Set it on `defineConfig` to control the root barrel and the default every plugin inherits. Set it on a single plugin to override that plugin's barrel.

The `type` field picks the export style. `{ type: 'named' }` writes `export { Foo, Bar } from '...'` from each file's named exports. `{ type: 'all' }` writes `export * from '...'` for every file. `false` turns off barrel generation.

A plugin's `output.barrel` also accepts `nested`. With `nested: true` the plugin writes an `index.ts` in every subdirectory, each re-exporting only what sits directly inside it. The root `output.barrel` has no `nested` field, so it always stays flat.

Set `barrel: false` on `defineConfig` to disable only the root barrel. Each plugin still emits its own. Set `barrel: false` on a plugin to disable that plugin's barrel and drop its files from the root barrel.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

> [!NOTE]
> `nested` is plugin-level only and defaults to `false`. The config-level value drops it, so the root barrel type is `{ type: 'all' \| 'named' } \| false`.

#### type

Export style for the barrel files.

|           |                    |
| --------: | :----------------- |
|     Type: | `'all' \| 'named'` |
| Required: | `true`             |
|  Default: | `'named'`          |

::: code-group

```typescript ['named' (default) → src/gen/index.ts]
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript ['all' → src/gen/index.ts]
export * from './api/user'
export * from './api/post'
export * from './api/types/User'
```

:::

#### nested

Writes an `index.ts` in every subdirectory instead of one flat root barrel. Each one re-exports only what sits directly inside it. This field works on a plugin's `output.barrel` only.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'api', barrel: { type: 'named', nested: true } } })],
})
```

## Example

::: code-group

```typescript [Named exports (default)]
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

```typescript [Wildcard exports]
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

```typescript [Nested barrels (plugin level)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

// nested lives on a plugin's output.barrel, not on the root output.barrel.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'api', barrel: { type: 'all', nested: true } } })],
})
```

```typescript [Generated output]
// src/gen/api/index.ts re-exports its files and subdirectories
export * from './user'
export * from './post'
export * from './types'

// src/gen/api/types/index.ts re-exports its files
export * from './User'

// the root src/gen/index.ts still uses the config default ({ type: 'named' })
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript [Disable a plugin barrel]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

// No zod/index.ts is created, and zod files
// are dropped from the root index.ts.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod({ output: { path: 'zod', barrel: false } })],
})
```

```typescript twoslash [Disable the root barrel]
import { defineConfig } from 'kubb'

// No root index.ts. Each plugin still gets
// its own barrel from its inherited config.
export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', barrel: false },
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
