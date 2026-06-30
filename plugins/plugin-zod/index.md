---
layout: doc
title: Kubb Zod Plugin
description: Generate Zod v4 schemas from OpenAPI for runtime validation that
  stays in sync with your TypeScript types.
outline: deep
kind: plugin
id: plugin-zod
name: Zod
category: validation
type: official
npmPackage: "@kubb/plugin-zod"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-zod
featured: true
icon:
  light: https://kubb.dev/feature/zod.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - zod
  - validation
  - schema
  - runtime-validation
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-zod
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/zod
---

# @kubb/plugin-zod

`@kubb/plugin-zod` turns your OpenAPI schemas into [Zod](https://zod.dev/) v4 schemas. Use them to validate API responses at runtime, build form schemas, or feed router libraries that take Zod (`tRPC`, `Hono`, `Elysia`).

Pair it with a client plugin (`@kubb/plugin-axios` or `@kubb/plugin-fetch`) and set the client's `validator: 'zod'` to validate every response.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-zod@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-zod@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-zod@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-zod@beta
```

:::

## Dependencies

`@kubb/plugin-zod` pairs with `@kubb/plugin-ts`. Add `pluginTs` to the plugins list when `typed: true`, since the generated schemas reference the TypeScript types it produces. Without `typed`, the schemas stand alone, and `inferred: true` exports their `z.infer` types so you do not need `pluginTs` at all.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod({
      output: { path: './zod' },
      group: { type: 'tag', name: ({ group }) => `${group}Schemas` },
      typed: true,
      importPath: 'zod',
    }),
  ],
})
```

:::

## See Also

- [Zod](https://zod.dev/)
- [Zod Mini](https://zod.dev/packages/mini)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
