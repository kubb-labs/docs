---
layout: doc
title: Kubb Zod Plugin
description: Generates Zod v4 schemas from your OpenAPI spec so you validate API
  responses, form input, and query params at runtime.
outline: deep
guides:
  - id: customization
    title: Customize generated schemas
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

`@kubb/plugin-zod` generates Zod schemas for runtime validation. Enable `inferred` to export TypeScript types alongside the schemas.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-zod
```

```shell [pnpm]
pnpm add -D @kubb/plugin-zod
```

```shell [npm]
npm install --save-dev @kubb/plugin-zod
```

```shell [yarn]
yarn add -D @kubb/plugin-zod
```

::

## Dependencies

No plugin dependencies. Install [Zod](https://zod.dev/) v4 or higher in the consuming app. Enable `inferred` to use schema-derived types without `pluginTs`.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginZod({ inferred: true }),
  ],
})
```

## Documentation

- [Options](./reference/options)
- [Format and type mappings](./reference/options#format-and-type-mappings)
- [Dictionaries and key schemas](./reference/options#dictionaries-open-objects-and-key-schemas)
- [Customize generated schemas](./guide/customization)

## See also

- [Zod](https://zod.dev/)
- [Zod Mini](https://zod.dev/packages/mini)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
