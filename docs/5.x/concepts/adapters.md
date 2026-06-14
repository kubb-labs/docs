---
layout: doc
title: Adapters - Convert Specs to the Kubb AST
description: Build Kubb adapters with createAdapter. Convert OpenAPI, AsyncAPI, GraphQL, or any custom specification into the universal AST that all plugins consume.
outline: deep
---

# Adapters

An adapter is the single entry point that turns your input specification into the universal [AST](/docs/5.x/concepts/ast). Every [plugin](/docs/5.x/concepts/plugins) consumes that AST, so the adapter abstracts the input format away from the rest of the build.

> [!TIP]
> For OpenAPI 2.0, 3.0, and 3.1 use the official [`@kubb/adapter-oas`](/adapters/adapter-oas). It is selected automatically when you import `defineConfig` from the top-level `kubb` package. Build a custom adapter only when you target a different specification (AsyncAPI, GraphQL, JSON Schema, gRPC, …).

## Quick start

A minimal adapter declares its name and produces an empty [`InputNode`](/docs/5.x/concepts/ast). Plugins won't emit anything for an empty AST, so start here and then populate `schemas` and `operations` from your spec.

```typescript twoslash [adapterCustom.ts]
import { createAdapter } from '@kubb/core'
import { createInput } from '@kubb/ast/factory'
import type { AdapterFactoryOptions } from '@kubb/core'

type AdapterCustom = AdapterFactoryOptions<'adapter-custom', { strict?: boolean }, { strict: boolean }>

export const adapterCustom = createAdapter<AdapterCustom>((options) => ({
  name: 'adapter-custom',
  options: { strict: options?.strict ?? false },
  document: null,
  async parse(_source) {
    return createInput({ schemas: [], operations: [] })
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

Wire it into your config with `defineConfig` from `kubb` and pass your adapter explicitly:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb'
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
| `options`    | `TResolvedOptions`                                                                                    | Yes      | Adapter options after defaults have been applied.                                                                                                  |
| `document`   | `TDocument \| null`                                                                                   | Yes      | The raw parsed source document, exposed for plugins that need direct access. `null` before `parse()`.                                              |
| `parse`      | `(source: AdapterSource) => InputNode \| Promise<InputNode>`                                          | Yes      | Convert the spec into the [universal AST](/docs/5.x/concepts/ast). The returned `InputNode` is consumed directly by the build driver.              |
| `getImports` | `(node: SchemaNode, resolve: (name: string) => { name: string; path: string }) => Array<ImportNode>` | Yes      | Track cross-references so plugins emit correct imports. `resolve` receives the collision-corrected schema name and must return the `{ name, path }` for the import. |
| `validate`   | `(input: string, options?: { throwOnError?: boolean }) => Promise<void>`                              | Yes      | Validate the document at the given path or URL without running the full pipeline.                                                                  |
| `stream`     | `(source: AdapterSource) => Promise<InputStreamNode>`                                                 | No       | Memory-efficient streaming variant of `parse()`. Returns `schemas` and `operations` as `AsyncIterable`s. The OAS adapter uses this code path for every spec.                                  |

`AdapterSource` is one of three shapes. Handle every form your users may pass:

```typescript twoslash
type AdapterSource = { type: 'path'; path: string } | { type: 'data'; data: string | unknown } | { type: 'paths'; paths: Array<string> }
```

> [!IMPORTANT]
> Throw from `parse()` with a clear, user-facing message when the input is invalid. The error is surfaced verbatim.

## Streaming

`stream()` is the streaming counterpart to `parse()`. It returns an `InputStreamNode` whose `schemas` and `operations` are `AsyncIterable`s instead of arrays. Each `for await` loop produces a fresh parse pass over the cached in-memory document, so plugins iterate independently and the runtime never holds every node in memory at once.

The build driver prefers `stream()` when an adapter implements it. For `parse()`-only adapters, the driver wraps the result in a reusable `AsyncIterable` so the rest of the pipeline stays stream-shaped.

```typescript twoslash [adapterStream.ts]
import { createAdapter } from '@kubb/core'
import { createStreamInput } from '@kubb/ast/factory'
import type { AdapterFactoryOptions } from '@kubb/core'
import type { SchemaNode, OperationNode } from '@kubb/ast'

type AdapterStream = AdapterFactoryOptions<'adapter-stream', Record<string, never>>

async function* streamSchemas(): AsyncIterable<SchemaNode> {
  // yield each parsed schema as soon as it is ready
}

async function* streamOperations(): AsyncIterable<OperationNode> {
  // yield each parsed operation as soon as it is ready
}

export const adapterStream = createAdapter<AdapterStream>(() => ({
  name: 'adapter-stream',
  options: {},
  document: null,
  async parse() {
    throw new Error('Use stream() instead — adapter-stream does not support eager parsing.')
  },
  async stream() {
    return createStreamInput(streamSchemas(), streamOperations(), {
      title: 'Streamed spec',
      circularNames: [],
      enumNames: [],
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

Use `createStreamInput(schemas, operations, meta?)` from [`@kubb/ast`](/docs/5.x/concepts/ast) to assemble the result. The `meta` argument is optional but recommended. When you set it, plugins can read `title`, `version`, and `baseURL` before the first node is yielded.

## Naming convention

Adapters follow the same layout as plugins so [`getResolver`](/docs/5.x/api/core), the registry, and the documentation can find them by inference:

| Surface                       | Pattern                                            | Example             |
| ----------------------------- | -------------------------------------------------- | ------------------- |
| npm package                   | `@<scope>/adapter-<name>` or `kubb-adapter-<name>` | `@kubb/adapter-oas` |
| Adapter runtime name          | The spec identifier (lowercase)                    | `'oas'`             |
| Factory export                | `adapter<Name>` (camelCase)                        | `adapterOas`        |
| Name constant                 | `adapter<Name>Name`                                | `adapterOasName`    |
| `AdapterFactoryOptions` alias | `Adapter<Name>` (PascalCase)                       | `AdapterOas`        |

Export the runtime name as a `satisfies`-typed constant so consumers can reference it without typos:

```typescript twoslash [naming.ts]
import { createAdapter } from '@kubb/core'
import { createInput } from '@kubb/ast/factory'
import type { AdapterFactoryOptions } from '@kubb/core'

export type AdapterExample = AdapterFactoryOptions<'example', { strict?: boolean }, { strict: boolean }, unknown>
export const adapterExampleName = 'example' satisfies AdapterExample['name']

export const adapterExample = createAdapter<AdapterExample>((options) => ({
  name: adapterExampleName,
  options: { strict: options.strict ?? false },
  document: null,
  async parse() {
    return createInput()
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

Official adapter for OpenAPI 2.0 (Swagger), OpenAPI 3.0, and OpenAPI 3.1. Every official plugin is built against it. See the [`@kubb/adapter-oas` reference](/adapters/adapter-oas) for the full option list.

::: code-group

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

:::

Key options:

| Option        | Type                                                    | Default  | Purpose                                                               |
| ------------- | ------------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| `validate`    | `boolean`                                               | `true`   | Run OpenAPI schema validation before parsing.                         |
| `dateType`    | `'date' \| 'string' \| 'stringOffset' \| 'stringLocal'` | `'date'` | How `format: date`/`date-time` schemas are emitted in TypeScript.     |
| `serverIndex` | `number`                                                | `0`      | Which `servers[]` entry to use as the base URL for client generation. |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: true, dateType: 'date', serverIndex: 0 }),
})
```

> [!NOTE]
> `defineConfig` from the top-level `kubb` package automatically uses `adapterOas()` when `adapter` is omitted. Set `adapter:` explicitly only to configure `adapterOas` options or supply a different adapter.

## Creating a custom adapter

Use `createAdapter` with `AdapterFactoryOptions` to model your input format. The example below sketches a JSON Schema adapter that exposes the parsed document for plugins:

```typescript twoslash [adapterJsonSchema.ts]
import { createAdapter } from '@kubb/core'
import { createInput, createImport, createSchema } from '@kubb/ast/factory'
import type { AdapterFactoryOptions } from '@kubb/core'
import type { InputNode } from '@kubb/ast'

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
    async parse(source): Promise<InputNode> {
      if (source.type !== 'path') {
        throw new Error('adapter-json-schema requires { type: "path" } input')
      }

      document = { $schema: 'https://json-schema.org/draft/2020-12/schema', definitions: {} }
      return createInput({
        schemas: Object.keys(document.definitions ?? {}).map((name) => createSchema({ name, type: 'object', properties: [] })),
        operations: [],
      })
    },
    getImports(node, resolve) {
      if (node.type === 'ref' && node.ref) {
        const resolved = resolve(node.ref)
        return [createImport({ name: [resolved.name], path: resolved.path })]
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
import { defineConfig } from 'kubb'
import { adapterJsonSchema } from './adapterJsonSchema.ts'

export default defineConfig({
  input: { path: './schema.json' },
  output: { path: './src/gen' },
  adapter: adapterJsonSchema({ strict: true }),
  plugins: [],
})
```

> [!TIP]
> `defineConfig` from `kubb` only fills `adapter` with `adapterOas()` when no `adapter` is provided. Passing your own adapter wins, so the same import works for both built-in and custom adapters.

### Schema dispatch and dialects

An adapter's hardest job is turning a spec's schema objects into [`SchemaNode`](/docs/5.x/concepts/ast)s. Most of that work is generic JSON Schema (`oneOf`/`anyOf`/`allOf`, `enum`, `const`, `type`, `format`, `items`, `properties`), so adapters follow one contract:

```text
context → [rule.match → rule.convert] → node
```

The adapter derives a small context from each schema, then runs it through an ordered table of [`dispatch`](/docs/5.x/concepts/ast#dispatch) rules that map spec shapes onto AST nodes. The few decisions that genuinely differ between specs are isolated behind a dialect, a single object the converter pipeline reads instead of hard-coding OpenAPI assumptions:

| Decision      | OpenAPI                                              | AsyncAPI (example)            |
| ------------- | --------------------------------------------------- | ----------------------------- |
| nullable      | `nullable: true`, `x-nullable`, or `type: ['…','null']` | `type: ['…', 'null']`         |
| discriminator | a `discriminator` object with a `mapping`           | no discriminator object       |
| binary        | `contentMediaType: 'application/octet-stream'`      | `contentEncoding: 'binary'`   |

`@kubb/adapter-oas` ships the OpenAPI dialect as its default. A new adapter such as `@kubb/adapter-asyncapi` reuses the same converters and dispatch table and only supplies its own dialect, so it does not reimplement schema parsing. This keeps the spec-specific surface small, discoverable, and easy to test by swapping a single object.

## Examples

### Validate before parsing

```typescript twoslash [adapterValidated.ts]
import { createAdapter } from '@kubb/core'
import { createInput } from '@kubb/ast/factory'
import type { AdapterFactoryOptions } from '@kubb/core'

type AdapterValidated = AdapterFactoryOptions<'adapter-validated', Record<string, never>>

export const adapterValidated = createAdapter<AdapterValidated>(() => ({
  name: 'adapter-validated',
  options: {},
  document: null,
  async parse(source) {
    if (source.type !== 'path' || !source.path.endsWith('.yaml')) {
      throw new Error('Expected a .yaml input file')
    }
    return createInput({ schemas: [], operations: [] })
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
