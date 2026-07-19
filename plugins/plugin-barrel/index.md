---
layout: doc
title: Kubb Barrel Plugin
description: Generates an index.ts barrel for every plugin output and one root
  barrel, so you import all generated code from a single entry point. Ships with
  Kubb, but only generates barrels once output.barrel is configured.
outline: deep
recipes:
  - id: named-re-exports-for-tree-shaking
    title: Named re-exports for tree-shaking
  - id: one-wildcard-barrel
    title: One wildcard barrel
  - id: a-barrel-in-every-folder
    title: A barrel in every folder
  - id: turn-barrels-on
    title: Turn barrels on
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

# @kubb/plugin-barrel

> [!TIP]
> `pluginBarrel` is registered by default, but generates nothing until you set `output.barrel`.

`@kubb/plugin-barrel` writes the `index.ts` barrel files. It adds one barrel per plugin output directory and one root barrel at `output.path/index.ts`. This runs after the build finishes, so you import everything from one entry point, like `import { Pet, usePetByIdQuery, petMock } from './gen'`.

The plugin is registered by default in `defineConfig`, but barrels stay off until you configure [`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel), root or per-plugin. See that reference entry for how the default, inheritance, and overrides work.

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

## Dependencies

`@kubb/plugin-barrel` has no plugin dependencies. It ships with Kubb and runs by default, reading the files other plugins write to build the barrels, so you never add it to `plugins` yourself.

## Example

::: code-group

```typescript twoslash [Named exports]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
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

```typescript twoslash [Wildcard exports]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: './petStore.yaml',
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

```typescript twoslash [Nested barrels (plugin level)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

// nested lives on a plugin's output.barrel, not on the root output.barrel.
export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
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

// the root src/gen/index.ts still uses the root's own output.barrel ({ type: 'named' })
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript twoslash [Disable a plugin barrel]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

// No zod/index.ts is created, and zod files
// are dropped from the root index.ts.
export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginTs(), pluginZod({ output: { path: 'zod', barrel: false } })],
})
```

```typescript twoslash [Disable the root barrel]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

// No root index.ts. The pluginTs barrel below still
// generates from its own output.barrel.
export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: false },
  plugins: [pluginTs({ output: { barrel: { type: 'named' } } })],
})
```

:::

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
