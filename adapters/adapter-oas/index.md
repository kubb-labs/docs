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
dependencies: []
resources:
  documentation: https://kubb.dev/adapters/adapter-oas
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/adapter-oas/CHANGELOG.md
---

# @kubb/adapter-oas

Read OpenAPI 2.0, 3.0, and 3.1 documents.

- Validate schemas and operations, then convert them into Kubb's AST.
- Configure `defineConfig.adapter` to apply type mappings across plugins.

> [!NOTE]
> Kubb uses `adapterOas()` by default. Add it explicitly to change [options](/adapters/adapter-oas/reference/options).

## Installation

Ships with `kubb`, no extra install.

## Dependencies

No plugin dependencies.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas({ dateType: 'date', integerType: 'number' }),
  plugins: [pluginTs()],
})
```
