---
layout: doc
title: Kubb TypeScript Plugin
description: Generates TypeScript types and interfaces from your OpenAPI spec,
  the typed foundation the other Kubb plugins build on.
outline: deep
guides:
  - id: customization
    title: Customize generated types
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

`@kubb/plugin-ts` generates TypeScript types and interfaces from OpenAPI schemas. Other plugins use these types for requests, responses, hooks, and mocks.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-ts
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts
```

```shell [yarn]
yarn add -D @kubb/plugin-ts
```

::

## Dependencies

No plugin dependencies.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
  ],
})
```

## Documentation

- [Options](./reference/options)
- [Customize generated types](./guide/customization)

## See also

- [TypeScript](https://www.typescriptlang.org/)
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md)
