---
layout: doc
title: Kubb TypeScript Plugin
description: Generates TypeScript types and interfaces from your OpenAPI spec, the
  typed foundation the other Kubb plugins build on.
outline: deep
kind: plugin
id: plugin-ts
name: TypeScript
category: types
type: official
npmPackage: "@kubb/plugin-ts"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-ts
featured: true
icon:
  light: https://kubb.dev/feature/typescript.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - typescript
  - types
  - interfaces
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-ts
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/typescript
---

# @kubb/plugin-ts

`@kubb/plugin-ts` turns your OpenAPI schemas into TypeScript types and interfaces. Most other Kubb plugins build on it. Clients, query hooks, mocks, and validators reuse the names it generates. That way every request, response, parameter, and enum is checked at compile time.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta
```

:::

## Dependencies

`@kubb/plugin-ts` has no plugin dependencies. It reads the OpenAPI spec through `@kubb/adapter-oas` and produces the type names every other plugin reuses, so add it whenever a client, query, mock, or validator plugin needs typed output.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
      exclude: [{ type: 'tag', pattern: 'store' }],
      group: { type: 'tag' },
      enum: { type: 'asConst' },
      optionalType: 'questionTokenAndUndefined',
    }),
  ],
})
```

:::

## See Also

- [TypeScript](https://www.typescriptlang.org/)
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md)
