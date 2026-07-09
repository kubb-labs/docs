---
layout: doc
title: Kubb Barrel Plugin
description: Generates an index.ts barrel for every plugin output and one root
  barrel, so you import all generated code from a single entry point. Ships with
  Kubb and runs by default.
outline: deep
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
> `pluginBarrel` runs by default, so barrel files appear with no setup. Set `output.barrel` to change how they are generated.

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

## Example

::: code-group

```typescript [Named exports (default)]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: './petStore.yaml',
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

```typescript [Nested barrels (plugin level)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

// nested lives on a plugin's output.barrel, not on the root output.barrel.
export default defineConfig({
  input: './petStore.yaml',
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
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod({ output: { path: 'zod', barrel: false } })],
})
```

```typescript twoslash [Disable the root barrel]
import { defineConfig } from 'kubb'

// No root index.ts. Each plugin still gets
// its own barrel from its inherited config.
export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: false },
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
