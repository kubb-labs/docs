---
layout: doc
title: Adapters
description: createAdapter builds an adapter that converts an input specification into the universal AST. Covers the Adapter interface, the built-in OpenAPI adapter, and writing your own.
outline: [2, 3]
---

# Adapters

An adapter converts an input specification into the universal [AST](/docs/5.x/guide/concepts/ast) that every plugin reads. This page documents `createAdapter`, the `Adapter` interface, the built-in OpenAPI adapter, and how to build your own. For what adapters are and where they sit in the pipeline, see [Adapters concepts](/docs/5.x/guide/concepts/adapters).

> [!TIP]
> For OpenAPI 2.0, 3.0, and 3.1 use the official [`@kubb/adapter-oas`](/adapters/adapter-oas/). Kubb picks it for you when you import `defineConfig` from the `kubb` package. Write a custom adapter only when you target a different specification such as AsyncAPI, GraphQL, JSON Schema, or gRPC.

## `createAdapter`

`createAdapter` builds adapters that translate specs into Kubb's universal AST. Write a custom adapter when your source is something Kubb does not parse yet, such as a GraphQL schema, a gRPC definition, an AsyncAPI spec, or your own domain-specific language.

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
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

Wire it into your config with `defineConfig` from `kubb` and pass the adapter:

```typescript [kubb.config.ts]

import { defineConfig } from 'kubb/config'
import { adapterCustom } from './adapterCustom.ts'

export default defineConfig({
  input: './my-spec.json',
  output: { path: './src/gen' },
  adapter: adapterCustom({ strict: true }),
  plugins: [],
})
```

## Adapter anatomy

Every adapter returned from `createAdapter` matches the `Adapter` interface from [`kubb/kit`](/docs/5.x/reference/kit):

| Property     | Type                                                                                                  | Required | Purpose                                                                                                                                            |
| ------------ | ----------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`       | `string`                                                                                              | Yes      | Unique adapter identifier. Convention is `adapter-<id>`.                                                                                           |
| `options`    | `TResolvedOptions`                                                                                    | Yes      | Adapter options after defaults are applied.                                                                                  |
| `document`   | `TDocument \| null`                                                                                   | Yes      | The raw parsed source document, for plugins that need direct access. `null` before `parse()`.                                              |
| `parse`      | `(source: AdapterSource) => InputNode \| Promise<InputNode>`                                          | Yes      | Convert the spec into the [universal AST](/docs/5.x/guide/concepts/ast). The build driver consumes the returned `InputNode` directly.              |
| `validate`   | `(input: string, options?: { throwOnError?: boolean }) => Promise<void>`                              | Yes      | Validate the document at a path or URL without running the full pipeline.                                                                  |

Cross-references need no adapter hook: every plugin resolves `$ref` imports through [`resolver.imports`](/docs/5.x/reference/kit/resolvers#imports), which defaults each ref to its pointer's last segment. An adapter that renames a schema (for example to break a name collision) stamps `targetName` on every ref node pointing at it, so `resolveRefName` and those imports pick up the emitted name. Refs that keep their segment name need no stamp.

> [!IMPORTANT]
> Throw from `parse()` with a clear, user-facing message when the input is invalid.

## Adapter naming convention

Adapters share the layout of plugins, so [`getResolver`](./generators#defineGenerator), the registry, and the docs find them by inference:

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
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

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
    async validate() {
      // Throw or call ctx.error here when the spec is invalid.
    },
  }
})
```

Register the adapter in `kubb.config.ts`:

```typescript [kubb.config.ts]

import { defineConfig } from 'kubb/config'
import { adapterJsonSchema } from './adapterJsonSchema.ts'

export default defineConfig({
  input: './schema.json',
  output: { path: './src/gen' },
  adapter: adapterJsonSchema({ strict: true }),
  plugins: [],
})
```

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
  async validate(input) {
    if (!input.endsWith('.yaml')) {
      throw new Error('Expected a .yaml input file')
    }
  },
}))
```
