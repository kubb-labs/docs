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

Generate Zod schemas for runtime validation.

- Export TypeScript types with `inferred: true`, without `pluginTs`.

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

- No plugin dependencies.
- Install [Zod](https://zod.dev/) v4 or higher in the consuming app.

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

::card-group

:::card{title="Options" to="/plugins/plugin-zod/reference/options"}
:::

:::card{title="Format and type mappings" to="/plugins/plugin-zod/reference/options#format-and-type-mappings"}
:::

:::card{title="Dictionaries and key schemas" to="/plugins/plugin-zod/reference/options#dictionaries-open-objects-and-key-schemas"}
:::

:::card{title="Customize generated schemas" to="/plugins/plugin-zod/guide/customization"}
:::

::

## See also

- [Zod](https://zod.dev/)
- [Zod Mini](https://zod.dev/packages/mini)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
