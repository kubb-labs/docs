---
layout: doc
title: Kubb Effect Plugin
description: Generates Effect v4 schemas and matching TypeScript types from your OpenAPI specification.
outline: deep
kind: plugin
id: plugin-effect
name: Effect
category: validation
type: official
npmPackage: "@kubb/plugin-effect"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-effect
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - effect
  - validation
  - schema
  - runtime-validation
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-effect
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-effect/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/effect
---

# @kubb/plugin-effect

`@kubb/plugin-effect` generates [Effect](https://effect.website/) v4 schemas and matching TypeScript types from OpenAPI. Each schema uses the same PascalCase name in the type and value namespaces.

```typescript [Pet.ts]
import * as Schema from 'effect/Schema'

export type Pet = {
  readonly id: number
  readonly name: string
}

export const Pet = Schema.Struct({
  id: Schema.Number.check(Schema.isFinite(), Schema.isInt()),
  name: Schema.String,
})
```

> [!WARNING]
> The first release targets `effect@4.0.0-beta.98`. Other Effect v4 beta releases and the future stable release may require changes to generated code.

## Installation

Install the plugin as a development dependency and Effect as an application dependency.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-effect@beta
bun add effect@4.0.0-beta.98
```

```shell [pnpm]
pnpm add -D @kubb/plugin-effect@beta
pnpm add effect@4.0.0-beta.98
```

```shell [npm]
npm install --save-dev @kubb/plugin-effect@beta
npm install effect@4.0.0-beta.98
```

```shell [yarn]
yarn add -D @kubb/plugin-effect@beta
yarn add effect@4.0.0-beta.98
```

:::

## Example

The plugin emits types itself, so it can replace `@kubb/plugin-ts` when Effect schemas are the source of truth.

```typescript twoslash [kubb.config.ts]
import { pluginEffect } from '@kubb/plugin-effect'
import { defineConfig } from 'kubb'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginEffect({
      output: { path: './effect' },
    }),
  ],
})
```

> [!IMPORTANT]
> Do not write the default `pluginEffect()` and `pluginTs()` outputs into the same barrel. Both plugins export names such as `Pet`. Use separate output paths or add a suffix with `resolver` when one project needs both sets of types.

## Runtime behavior

OpenAPI length, range, pattern, uniqueness, and `oneOf` rules become Effect checks. OpenAPI `format` and `default` values become schema annotations. A format such as `email` does not reject a string, and a default does not fill a missing value.

When the OpenAPI adapter uses `dateType: 'date'`, generated codecs decode `date-time` strings into `DateTime.Utc` values and encode them as UTC ISO strings. Date-only fields preserve their `YYYY-MM-DD` wire format, while the default string representation keeps both formats as annotated strings.

## See also

- [Effect Schema](https://effect.website/docs/schema/introduction/)
- [Options](/plugins/plugin-effect/reference/options)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-effect/CHANGELOG.md)
