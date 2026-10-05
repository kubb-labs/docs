---
layout: doc
title: Kubb OpenAPI Adapter
description: Reads an OpenAPI 2.0, 3.0, or 3.1 spec and converts every schema
  and operation into the AST that Kubb plugins generate from, so one adapter
  feeds the whole build.
outline: deep
kind: adapter
id: adapter-oas
name: OpenAPI
category: openapi
type: official
npmPackage: "@kubb/adapter-oas"
repo: https://github.com/kubb-labs/kubb
docsPath: /adapters/adapter-oas
featured: true
icon:
  light: https://kubb.dev/feature/openapi.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - openapi
  - swagger
  - api-spec
  - parser
  - converter
resources:
  documentation: https://kubb.dev/adapters/adapter-oas
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/adapter-oas/CHANGELOG.md
---

# @kubb/adapter-oas

`@kubb/adapter-oas` reads and validates OpenAPI 2.0, 3.0, and 3.1 documents, then converts schemas and operations into the AST used by every plugin.

Configure it on `defineConfig.adapter`. Its type mappings apply to every plugin in the build. Kubb uses `adapterOas()` by default. Add it explicitly to change [Options](./reference/options).

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/adapter-oas
```

```shell [pnpm]
pnpm add -D @kubb/adapter-oas
```

```shell [npm]
npm install --save-dev @kubb/adapter-oas
```

```shell [yarn]
yarn add -D @kubb/adapter-oas
```

::

## Dependencies

No plugin dependencies.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas({ dateType: 'date', integerType: 'number' }),
  plugins: [pluginTs()],
})
```

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/adapter-oas/CHANGELOG.md)
