---
layout: doc
title: Kubb Zod Plugin
description: Generates Zod v4 schemas from your OpenAPI spec so you validate API
  responses, form input, and query params at runtime.
outline: deep
recipes:
  - id: zod-as-the-single-source-of-truth
    title: Zod as the single source of truth
  - id: tree-shakeable-schemas-with-zod-mini
    title: Tree-shakeable schemas with Zod Mini
  - id: coerce-query-and-form-input
    title: Coerce query and form input
  - id: validate-every-api-response
    title: Validate every API response
  - id: encode-a-custom-type-on-requests
    title: Encode a custom type on requests
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

:::

## Dependencies

> [!IMPORTANT]
> The generated schemas need Zod v4 or higher.

The generated schemas stand alone: they import `z` from your project, so add [Zod](https://zod.dev/) to your dependencies. Set `inferred: true` to export a `z.infer` type alias next to each schema, which makes the schemas the single source of truth for types without `@kubb/plugin-ts`.

## Format and type mappings

`@kubb/plugin-zod` generates native Zod v4 schemas for standard OpenAPI types and formats:

| OpenAPI Type / Format | Standard Zod Output | Zod Mini Output | Notes |
| :--- | :--- | :--- | :--- |
| `integer` | `z.int()` | `z.int()` | Coerces to `z.coerce.number().int()` when `coercion.numbers` is enabled |
| `integer`, `format: int32` | `z.int32()` | `z.int32()` | 32-bit signed integer |
| `integer`, `format: uint32` | `z.uint32()` | `z.uint32()` | 32-bit unsigned integer |
| `integer`, `format: int64` | `z.bigint()` | `z.bigint()` | 64-bit integer |
| `string`, `format: byte` / `base64` | `z.base64()` | `z.base64()` | Base64 string validation |
| `string`, `format: base64url` | `z.base64url()` | `z.base64url()` | URL-safe base64 string validation |
| `string`, `format: jwt` | `z.jwt()` | `z.jwt()` | JSON Web Token format |
| `string`, `format: ulid` | `z.ulid()` | `z.ulid()` | ULID format |
| `string`, `format: iban` | `z.iban()` | `z.iban()` | International Bank Account Number |
| `string`, `format: duration` | `z.iso.duration()` | `z.iso.duration()` | ISO 8601 duration format |
| `string`, `format: uuid` | `z.uuid()` (or `z.guid()`) | `z.uuid()` (or `z.guid()`) | Configured via `guidType` |
| `string`, `format: email` | `z.email()` | `z.email()` | Email format |
| `string`, `format: uri` / `url` | `z.url()` | `z.url()` | URL format |
| `string`, `format: ipv4` / `ipv6` | `z.ipv4()` / `z.ipv6()` | `z.ipv4()` / `z.ipv6()` | IP address format |
| `string`, `format: date` | `z.iso.date()` | `z.iso.date()` | ISO 8601 date |
| `string`, `format: date-time` | `z.iso.datetime()` | `z.string()` | ISO 8601 date-time |
| `string`, `format: time` | `z.iso.time()` | `z.iso.time()` | ISO 8601 time |

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      output: { path: './zod', mode: 'directory' },
      group: { type: 'tag', name: ({ group }) => `${group}Schemas` },
      inferred: true,
      importPath: 'zod',
    }),
  ],
})
```

:::

## See also

- [Zod](https://zod.dev/)
- [Zod Mini](https://zod.dev/packages/mini)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
