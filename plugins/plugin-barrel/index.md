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

:::

The [Options](/plugins/plugin-barrel/reference/options) page documents wildcard exports (`type: 'all'`) and nested barrels, with the output each one generates. The [barrel files guide](/docs/5.x/guide/going-further/barrel-files) walks through tuning barrels per plugin and disabling them.

## See Also

- [Options](/plugins/plugin-barrel/reference/options)
- [Barrel files guide](/docs/5.x/guide/going-further/barrel-files)
- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
