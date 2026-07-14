---
layout: doc
title: Kubb OpenAPI Adapter
description: Reads an OpenAPI 2.0, 3.0, or 3.1 spec and converts every schema and
  operation into the AST that Kubb plugins generate from, so one adapter feeds
  the whole build.
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

The OpenAPI adapter sits between your spec and every Kubb plugin. It reads the spec from `input`, whether that is a file, a URL, inline content, or a parsed object, validates it, and converts each schema and operation into Kubb's universal AST that downstream plugins consume.

Configure it once on `defineConfig`. Its choices for date representation, integer width, and server URL apply to every plugin in the build.

See [Options](/adapters/adapter-oas/reference/options) for the full configuration reference.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/adapter-oas@beta
```

```shell [pnpm]
pnpm add -D @kubb/adapter-oas@beta
```

```shell [npm]
npm install --save-dev @kubb/adapter-oas@beta
```

```shell [yarn]
yarn add -D @kubb/adapter-oas@beta
```

:::

## Dependencies

`@kubb/adapter-oas` has no plugin dependencies. It reads your OpenAPI spec and converts it into the AST that every Kubb plugin generates from, so plugins depend on it rather than the other way around.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas({
    validate: true,
    server: { index: 0, variables: { env: 'prod' } },
    discriminator: 'propagate',
    enums: 'root',
    dateType: 'date',
    integerType: 'number',
    unknownType: 'unknown',
    emptySchemaType: 'unknown',
    enumSuffix: 'enum',
  }),
  plugins: [pluginTs()],
})
```

:::

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/adapter-oas/CHANGELOG.md)
