---
layout: doc
title: Adapters API - createAdapter and the Adapter interface
description: Build Kubb adapters with createAdapter. The Adapter interface, streaming, the OpenAPI adapter options, and how to convert any specification into the universal AST.
outline: deep
---

# Adapters API

An adapter converts an input specification into the universal [AST](/docs/5.x/guide/concepts/ast) that every plugin reads. This page documents `createAdapter`, the `Adapter` interface, the built-in OpenAPI adapter, and how to build your own. For what adapters are and where they sit in the pipeline, see [Adapters concepts](/docs/5.x/guide/concepts/adapters).

> [!TIP]
> For OpenAPI 2.0, 3.0, and 3.1 use the official [`@kubb/adapter-oas`](/adapters/adapter-oas/). Kubb picks it for you when you import `defineConfig` from the `kubb` package. Write a custom adapter only when you target a different specification such as AsyncAPI, GraphQL, JSON Schema, or gRPC.

## Quick start

A minimal adapter declares a name and returns an empty [`InputNode`](/docs/5.x/guide/concepts/ast). An empty AST emits nothing, so fill `schemas` and `operations` from your spec next.

```typescript twoslash [adapterCustom.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

type AdapterCustom = AdapterFactoryOptions<'adapter-custom', { strict?: boolean }, { strict: boolean }>

export const adapterCustom = createAdapter<AdapterCustom>((options) => ({
  name: 'adapter-custom',
  options: { strict: options?.strict ?? false },
  document: null,
  async parse(_source) {
    return ast.factory.createInput({ schemas: [], operations: [] })
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

Wire it into your config with `defineConfig` from `kubb` and pass the adapter:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { adapterCustom } from './adapterCustom.ts'

export default defineConfig({
  input: { path: './my-spec.json' },
  output: { path: './src/gen' },
  adapter: adapterCustom({ strict: true }),
  plugins: [],
})
```

## Anatomy

Every adapter returned from `createAdapter` matches the `Adapter` interface from [`@kubb/core`](https://www.npmjs.com/package/@kubb/core):

| Property     | Type                                                                                                  | Required | Purpose                                                                                                                                            |
| ------------ | ----------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`       | `string`                                                                                              | Yes      | Unique adapter identifier. Convention is `adapter-<id>`.                                                                                           |
| `options`    | `TResolvedOptions`                                                                                    | Yes      | Adapter options after defaults are applied.                                                                                                  |
| `document`   | `TDocument \| null`                                                                                   | Yes      | The raw parsed source document, for plugins that need direct access. `null` before `parse()`.                                              |
| `parse`      | `(source: AdapterSource) => InputNode \| Promise<InputNode>`                                          | Yes      | Convert the spec into the [universal AST](/docs/5.x/guide/concepts/ast). The build driver consumes the returned `InputNode` directly.              |
| `getImports` | `(node: SchemaNode, resolve: (name: string) => { name: string; path: string }) => Array<ImportNode>` | Yes      | Track cross-references so plugins emit correct imports. `resolve` receives the collision-corrected schema name and returns the `{ name, path }` for the import. |
| `validate`   | `(input: string, options?: { throwOnError?: boolean }) => Promise<void>`                              | Yes      | Validate the document at a path or URL without running the full pipeline.                                                                  |
| `stream`     | `(source: AdapterSource) => Promise<InputNode<true>>`                                                 | No       | Streaming variant of `parse()`. Returns `schemas` and `operations` as `AsyncIterable`s. The OAS adapter uses this path for every spec.                                  |

`AdapterSource` takes one of two shapes. Handle every form your users may pass:

```typescript twoslash [AdapterSource]
type AdapterSource = { type: 'path'; path: string } | { type: 'data'; data: string | unknown }
```

> [!IMPORTANT]
> Throw from `parse()` with a clear, user-facing message when the input is invalid. Kubb surfaces the error verbatim.

## Streaming

`stream()` returns an `InputNode<true>` whose `schemas` and `operations` are `AsyncIterable`s instead of arrays. Each `for await` loop runs a fresh parse pass over the cached document, so plugins iterate independently and the runtime never holds every node in memory at once.

The build driver prefers `stream()` when an adapter implements it. For `parse()`-only adapters, the driver wraps the result in a reusable `AsyncIterable` so the rest of the pipeline stays stream-shaped.

```typescript twoslash [adapterStream.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

type AdapterStream = AdapterFactoryOptions<'adapter-stream', Record<string, never>>

async function* streamSchemas(): AsyncIterable<ast.SchemaNode> {
  // yield each parsed schema as soon as it is ready
}

async function* streamOperations(): AsyncIterable<ast.OperationNode> {
  // yield each parsed operation as soon as it is ready
}

export const adapterStream = createAdapter<AdapterStream>(() => ({
  name: 'adapter-stream',
  options: {},
  document: null,
  async parse() {
    throw new Error('Use stream() instead. adapter-stream does not support eager parsing.')
  },
  async stream() {
    return ast.factory.createInput({
      stream: true,
      schemas: streamSchemas(),
      operations: streamOperations(),
      meta: { title: 'Streamed spec', circularNames: [], enumNames: [] },
    })
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

Build the result with `ast.factory.createInput({ stream: true, schemas, operations, meta })` (see [AST](/docs/5.x/guide/concepts/ast)). The `meta` field is optional. Set it when you can, so plugins read `title`, `version`, and `baseURL` before the first node is yielded.

## Naming convention

Adapters share the layout of plugins, so [`getResolver`](/docs/5.x/reference/core), the registry, and the docs find them by inference:

| Surface                       | Pattern                                            | Example             |
| ----------------------------- | -------------------------------------------------- | ------------------- |
| npm package                   | `@<scope>/adapter-<name>` or `kubb-adapter-<name>` | `@kubb/adapter-oas` |
| Adapter runtime name          | The spec identifier (lowercase)                    | `'oas'`             |
| Factory export                | `adapter<Name>` (camelCase)                        | `adapterOas`        |
| Name constant                 | `adapter<Name>Name`                                | `adapterOasName`    |
| `AdapterFactoryOptions` alias | `Adapter<Name>` (PascalCase)                       | `AdapterOas`        |

Export the runtime name as a `satisfies`-typed constant so consumers reference it without typos:

```typescript twoslash [naming.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

export type AdapterExample = AdapterFactoryOptions<'example', { strict?: boolean }, { strict: boolean }, unknown>
export const adapterExampleName = 'example' satisfies AdapterExample['name']

export const adapterExample = createAdapter<AdapterExample>((options) => ({
  name: adapterExampleName,
  options: { strict: options.strict ?? false },
  document: null,
  async parse() {
    return ast.factory.createInput()
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

## Built-in adapters

### `@kubb/adapter-oas`

Official adapter for OpenAPI 2.0 (Swagger), OpenAPI 3.0, and OpenAPI 3.1. Every official plugin is built against it. See the [`@kubb/adapter-oas` reference](/adapters/adapter-oas/) for the full option list.

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

Key options:

| Option        | Type                                                    | Default  | Purpose                                                               |
| ------------- | ------------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| `validate`    | `boolean`                                               | `true`   | Run OpenAPI schema validation before parsing.                         |
| `dateType`    | `false \| 'string' \| 'stringOffset' \| 'stringLocal' \| 'date'` | `'string'` | How `format: date`/`date-time` schemas are emitted in TypeScript.     |
| `server`      | `{ index?: number; variables?: Record<string, string> }` | none     | Which `servers[]` entry to use as the base URL, and its variable overrides. |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: true, dateType: 'date', server: { index: 0 } }),
})
```

> [!NOTE]
> `defineConfig` from the `kubb` package uses `adapterOas()` when you omit `adapter`. Set `adapter:` only to configure `adapterOas` options or supply a different adapter.

## Creating a custom adapter

Use `createAdapter` with `AdapterFactoryOptions` to model your input format. This JSON Schema adapter exposes the parsed document for plugins:

```typescript twoslash [adapterJsonSchema.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

type Document = { $schema: string; definitions?: Record<string, unknown> }

type AdapterJsonSchema = AdapterFactoryOptions<'adapter-json-schema', { strict?: boolean }, { strict: boolean }, Document>

export const adapterJsonSchema = createAdapter<AdapterJsonSchema>((options) => {
  let document: Document | null = null

  return {
    name: 'adapter-json-schema',
    options: { strict: options?.strict ?? false },
    get document() {
      return document
    },
    async parse(source): Promise<ast.InputNode> {
      if (source.type !== 'path') {
        throw new Error('adapter-json-schema requires { type: "path" } input')
      }

      document = { $schema: 'https://json-schema.org/draft/2020-12/schema', definitions: {} }
      return ast.factory.createInput({
        schemas: Object.keys(document.definitions ?? {}).map((name) => ast.factory.createSchema({ name, type: 'object', properties: [] })),
        operations: [],
      })
    },
    getImports(node, resolve) {
      if (node.type === 'ref' && node.ref) {
        const resolved = resolve(node.ref)
        return [ast.factory.createImport({ name: [resolved.name], path: resolved.path })]
      }
      return []
    },
    async validate() {
      // Throw or call ctx.error here when the spec is invalid.
    },
  }
})
```

Register the adapter in `kubb.config.ts`:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { adapterJsonSchema } from './adapterJsonSchema.ts'

export default defineConfig({
  input: { path: './schema.json' },
  output: { path: './src/gen' },
  adapter: adapterJsonSchema({ strict: true }),
  plugins: [],
})
```

### Schema dispatch and dialects

Turning a spec's schema objects into [`SchemaNode`](/docs/5.x/guide/concepts/ast)s is the heaviest part of an adapter. Most of that work is generic JSON Schema (`oneOf`/`anyOf`/`allOf`, `enum`, `const`, `type`, `format`, `items`, `properties`), so adapters follow one contract:

```text [Conversion pipeline]
context → [rule.match → rule.convert] → node
```

The adapter derives a small context from each schema, then runs it through an ordered table of dispatch rules that map spec shapes onto AST nodes. Only a few decisions differ between specs. Those live behind a dialect, a single object the converter pipeline reads, so it never hard-codes OpenAPI assumptions:

| Decision      | OpenAPI                                              | AsyncAPI (example)            |
| ------------- | --------------------------------------------------- | ----------------------------- |
| nullable      | `nullable: true`, `x-nullable`, or `type: ['…','null']` | `type: ['…', 'null']`         |
| discriminator | a structured `discriminator` object (not the Swagger 2 string form) | no discriminator object       |
| binary        | `contentMediaType: 'application/octet-stream'`      | `contentEncoding: 'binary'`   |
| optionality   | a parent's `required` plus the schema's `nullable` set `optional` / `nullish` | same JSON Schema `required` + `null` |

`@kubb/adapter-oas` ships the OpenAPI dialect as its default. A new adapter such as `@kubb/adapter-asyncapi` reuses the same converters and dispatch table and supplies only its own dialect, so the spec-specific surface stays small. You test it by swapping that one object.

## Examples

### Validate before parsing

```typescript twoslash [adapterValidated.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

type AdapterValidated = AdapterFactoryOptions<'adapter-validated', Record<string, never>>

export const adapterValidated = createAdapter<AdapterValidated>(() => ({
  name: 'adapter-validated',
  options: {},
  document: null,
  async parse(source) {
    if (source.type !== 'path' || !source.path.endsWith('.yaml')) {
      throw new Error('Expected a .yaml input file')
    }
    return ast.factory.createInput({ schemas: [], operations: [] })
  },
  getImports() {
    return []
  },
  async validate(input) {
    if (!input.endsWith('.yaml')) {
      throw new Error('Expected a .yaml input file')
    }
  },
}))
```
