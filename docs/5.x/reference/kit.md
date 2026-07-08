---
layout: doc
title: Kit API
description: The complete kubb/kit reference for authoring plugins, generators, resolvers, parsers, adapters, renderers, and storage backends, plus the ast namespace, Diagnostics, the engine surface with createKubb and defineConfig, and the kubb/kit/testing helpers.
outline: [2, 3]
---

# Kit API

`kubb/kit` contains everything you need to build your own plugin and custom logic. Plugins, generators, resolvers, parsers, adapters, renderers, and storage backends all start here. It is a subpath of the top-level `kubb` package, so there is nothing extra to install. Import straight from `kubb/kit`.

```typescript twoslash [imports.ts]
import {
  definePlugin,
  defineGenerator,
  createResolver,
  Resolver,
  defineParser,
  createAdapter,
  createRenderer,
  createStorage,
  memoryStorage,
  fsStorage,
  Diagnostics,
  ast,
} from 'kubb/kit'
```

`kubb/kit` is backed by the `@kubb/kit` package, which re-exports from the internal `@kubb/core` and `@kubb/ast` libraries. Treat both as implementation details and always import from `kubb/kit`, never from the internal packages directly.

> [!TIP]
> The build-time engine (`createKubb`) and `defineConfig` come from the `kubb` package and its `kubb/config` subpath, documented in [Engine and configuration](#engine-and-configuration) below. `kubb/kit` is the authoring side: the code you write to add a new plugin, generator, resolver, parser, adapter, or renderer.

## Plugin authoring

Plugins are the main extension point in Kubb. A plugin owns its file naming, its output folder, its lifecycle hooks, and the [generators](#defineGenerator) that walk the [AST](/docs/5.x/guide/concepts/ast) and emit `FileNode` objects.

### `definePlugin`

`definePlugin` wraps a factory function and returns a typed `Plugin`. All lifecycle handlers live under one `hooks` object, inspired by [Astro integrations](https://docs.astro.build/en/reference/integrations-reference/).

```typescript twoslash [plugin-example.ts]
import { definePlugin } from 'kubb/kit'

export const pluginExample = definePlugin((options: { prefix?: string } = {}) => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      // Register resolvers, generators, and options here.
    },
  },
}))
```

#### Plugin shape

| Property       | Type                                 | Required | Description                                                |
| -------------- | ------------------------------------ | -------- | ---------------------------------------------------------- |
| `name`         | `string`                             | Yes      | Unique plugin identifier (e.g., `plugin-ts`)               |
| `dependencies` | `Array<string>`                      | No       | Names of other plugins this one requires                   |
| `options`      | `unknown`                            | No       | User-supplied options passed through to generators         |
| `hooks`        | `{ 'kubb:plugin:setup'?: ...; ... }` | Yes      | Lifecycle handlers (see [Plugin API](/docs/5.x/guide/concepts/plugins)) |

#### `KubbPluginSetupContext` methods (passed to `kubb:plugin:setup`)

| Method           | Signature                                                       | Purpose                                                       |
| ---------------- | ----------------------------------------------------------------| ------------------------------------------------------------- |
| `addGenerator`   | `(...generators: Array<Generator>) => void`                     | Register one or more generators for this plugin               |
| `setResolver`    | `(resolver: Partial<Resolver>) => void`                         | Set or partially override the file naming resolver            |
| `addMacro`       | `(macro: Macro) => void`                                        | Add a macro that rewrites AST nodes before generators         |
| `setMacros`      | `(macros: Array<Macro>) => void`                                | Replace this plugin's macros with a new list                  |
| `setOptions`     | `(options: ResolvedOptions) => void`                            | Set the resolved options used by generators                   |
| `injectFile`     | `(file: UserFileNode) => void`                                  | Inject a raw file into the build output, bypassing generation |
| `config`         | `Config`                                                        | The resolved build configuration at setup time                |
| `options`        | `TOptions`                                                      | The plugin's own options as passed by the user                |

> [!IMPORTANT]
> Plugin names should follow the convention `plugin-<feature>` (e.g., `plugin-react-query`, `plugin-zod`). See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for naming conventions.

#### Related

- [Full Plugin API reference](/docs/5.x/guide/concepts/plugins)
- [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins)

### `defineGenerator` {#defineGenerator}

`defineGenerator` declares a named generator unit consumed by a plugin. Generators walk the [AST](/docs/5.x/guide/concepts/ast) and emit files. The engine calls each method for the matching node type during the generation loop.

Each generator method returns `TElement | Array<FileNode> | void`. Returning a renderer element (for example JSX from [`kubb/jsx`](/docs/5.x/reference/jsx)) requires a `renderer` factory on the generator. Returning `Array<FileNode>` directly, or calling `ctx.upsertFile()` and returning `void`, works without a renderer.

```typescript twoslash [my-generator.ts]
import { ast, defineGenerator } from 'kubb/kit'

const myGenerator = defineGenerator({
  name: 'my-generator',
  operation(node, ctx) {
    return [
      ast.factory.createFile({
        baseName: `${node.operationId}.ts`,
        path: `./${node.operationId}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`export const op = '${node.operationId}'`)],
          }),
        ],
      }),
    ]
  },
})
```

#### Generator methods

| Method         | Input                                   | Output                                | When to use                                                      |
| -------------- | ---------------------------------------- | -------------------------------------- | ------------------------------------------------------------------ |
| `schema()`     | `SchemaNode` (per data schema)          | `TElement \| Array<FileNode> \| void` | Generate types, validators, factories. Called once per schema    |
| `operation()`  | `OperationNode` (per API operation)     | `TElement \| Array<FileNode> \| void` | Generate hooks, clients, handlers. Called once per operation     |
| `operations()` | `Array<OperationNode>` (all operations) | `TElement \| Array<FileNode> \| void` | Generate index or barrel files. Called once after all operations |

#### `GeneratorContext` properties (the `ctx` argument passed to each method)

| Property              | Type                                                | Purpose                                                              |
| --------------------- | ----------------------------------------------------| ---------------------------------------------------------------------|
| `ctx.config`          | `Config`                                            | Resolved Kubb configuration                                          |
| `ctx.root`            | `string`                                            | Absolute path to the output directory for the current plugin         |
| `ctx.options`         | `TResolvedOptions`                                  | Per-node resolved options (after exclude/include/override filtering) |
| `ctx.plugin`          | `Plugin`                                            | The owning plugin descriptor                                         |
| `ctx.resolver`        | `Resolver`                                          | Resolver for the current plugin                                      |
| `ctx.driver`          | `KubbDriver`                                        | Plugin driver for cross-plugin access                                |
| `ctx.hooks`           | `Hookable<KubbHooks>`                               | Event bus for `KubbHooks` events                                     |
| `ctx.adapter`         | `Adapter`                                           | The adapter that parsed the input spec                               |
| `ctx.meta`            | `InputMeta`                                         | Document metadata from the adapter. Carries `title`, `version`, `baseURL`, and the pre-computed `circularNames` and `enumNames` arrays. |
| `ctx.addFile()`       | `(...files: FileNode[]) => Promise<void>`           | Add files, skipping any that already exist                           |
| `ctx.upsertFile()`    | `(...files: FileNode[]) => Promise<void>`           | Add or merge files (concatenates sources and imports)                |
| `ctx.getPlugin()`     | `(name: string) => Plugin \| undefined`             | Get a plugin by name                                                 |
| `ctx.requirePlugin()` | `(name: string) => Plugin`                          | Get a plugin by name or throw a descriptive error                    |
| `ctx.getResolver()`   | `(name: string) => Resolver`                        | Get a resolver by plugin name                                        |
| `ctx.info()`          | `(message: string) => void`                         | Emit an info message via the build event system                      |
| `ctx.warn()`          | `(message: string) => void`                         | Emit a warning via the build event system                            |
| `ctx.error()`         | `(error: string \| Error) => void`                  | Emit an error via the build event system                             |

> [!TIP]
> Return an empty array `[]` to skip a node without error. Return `void` to handle file writing manually via `ctx.upsertFile()`.

#### Related

- [AST concepts](/docs/5.x/guide/concepts/ast) for node types and traversal
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

### `createResolver`

`createResolver` builds a `Resolver` instance that controls file naming and path resolution for a plugin. Pass the plugin-specific fields directly as an object; `this` inside a method reaches sibling resolver methods.

The object must include at least `{ pluginName }`. The built-in machinery lives under `resolver.default` (`default.name`, `default.file`, `default.options`, `default.path`, `default.banner`, `default.footer`), exposed as a getter that always reaches the untouched defaults. The resolver exposes `name` and `file` methods that generators call, and both fall back to the defaults until the object overrides them. Set `name` to a function for identifier casing, and `file` to an object whose `baseName` builds the base name (extension included) and whose `path` returns the full path. Use `this` to reach sibling members, so a namespace method calls `this.name(...)` for the plugin's identifier casing.

```typescript twoslash [resolver.ts]
import { createResolver } from 'kubb/kit'
import type { PluginFactoryOptions, Resolver } from 'kubb/kit'

// Extend the base Resolver with plugin-specific naming namespaces.
type MyResolver = Resolver & {
  schema: {
    name(node: { name: string }): string
  }
}

type MyPlugin = PluginFactoryOptions<'plugin-example', object, object, MyResolver>

export const resolver = createResolver<MyPlugin>({
  pluginName: 'plugin-example',
  name(name) {
    return `${name.charAt(0).toUpperCase()}${name.slice(1)}`
  },
  schema: {
    name(node) {
      return this.name(node.name)
    },
  },
})
```

#### Auto-injected resolver defaults

| Method           | Default behavior                                                        |
| ---------------- | ---------------------------------------------------------------------- |
| `name`           | Top-level identifier casing, delegates to `default.name`               |
| `file`           | Top-level `FileNode` builder, delegates to `default.file`              |
| `default.name`   | The built-in generated-identifier casing                               |
| `default.options`| Applies `exclude`, `include`, and `override` filters                   |
| `default.path`   | Resolves to `output.path`, with optional tag/path-based subdirectories |
| `default.file`   | Constructs a full `FileNode` using the resolver's `file.baseName` casing (default `toFilePath`) |
| `default.banner` | Returns `output.banner` or the standard "Generated by Kubb" header     |
| `default.footer` | Returns `output.footer` when set                                       |

#### `Resolver.merge`

`Resolver.merge(base, patch)` returns a new resolver with `patch`'s fields layered over `base`'s and every helper re-bound. A top-level `name` replaces, while `file` and each namespace merge per member, so overriding `query.name` keeps the base `query.keyName`. Framework code uses it to apply a `setResolver` partial override over a plugin's built-in resolver, and you can call it yourself when composing resolvers. Type a patch with `ResolverPatch<T>` to keep `this` and namespace shapes checked against the target resolver.

```typescript twoslash [merge.ts]
import { Resolver } from 'kubb/kit'
import { resolver } from './resolver.ts'
// ---cut---
const patched = Resolver.merge(resolver, {
  name(name) {
    return `Custom${this.default.name(name)}`
  },
})
```

#### Related

- [Plugin API: resolvers](/docs/5.x/guide/concepts/plugins#resolvers)
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

## Adapters

An adapter converts an input specification into the universal [AST](/docs/5.x/guide/concepts/ast) that every plugin reads. This section documents `createAdapter`, the `Adapter` interface, the built-in OpenAPI adapter, and how to build your own. For what adapters are and where they sit in the pipeline, see [Adapters concepts](/docs/5.x/guide/concepts/adapters).

> [!TIP]
> For OpenAPI 2.0, 3.0, and 3.1 use the official [`@kubb/adapter-oas`](/adapters/adapter-oas/). Kubb picks it for you when you import `defineConfig` from the `kubb` package. Write a custom adapter only when you target a different specification such as AsyncAPI, GraphQL, JSON Schema, or gRPC.

### `createAdapter`

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

### Adapter anatomy

Every adapter returned from `createAdapter` matches the `Adapter` interface from [`kubb/kit`](#adapters-and-parsers):

| Property     | Type                                                                                                  | Required | Purpose                                                                                                                                            |
| ------------ | ----------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`       | `string`                                                                                              | Yes      | Unique adapter identifier. Convention is `adapter-<id>`.                                                                                           |
| `options`    | `TResolvedOptions`                                                                                    | Yes      | Adapter options after defaults are applied.                                                                                  |
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

### Streaming adapters

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

### Adapter naming convention

Adapters share the layout of plugins, so [`getResolver`](#defineGenerator), the registry, and the docs find them by inference:

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

### Built-in adapters

#### `@kubb/adapter-oas`

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

### Creating a custom adapter

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

#### Schema dispatch and dialects {#schema-dispatch-and-dialects}

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

#### Validate before parsing

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

## Parsers

A parser turns a `FileNode` into the source string written to disk. This section documents `defineParser`, the `Parser` interface, the built-in parsers, and how to add your own. For why parsers exist and where they sit in the pipeline, see [Parsers concepts](/docs/5.x/guide/concepts/parsers).

> [!TIP]
> For TypeScript and JavaScript output use the built-in [`@kubb/parser-ts`](/parsers/parser-ts/). It is added by default when you import `defineConfig` from the `kubb` package. Build a custom parser only when you target a different language, such as Python, Kotlin, or Rust.

### `defineParser`

`defineParser` creates a parser that converts generated file ASTs to formatted source strings. Each parser declares which file extensions it handles via `extNames`. A minimal parser registers its extensions and concatenates each source:

```typescript twoslash [parserText.ts]
import { defineParser } from 'kubb/kit'

export const parserText = defineParser({
  name: 'parser-text',
  extNames: ['.txt'],
  parse(file) {
    return file.sources
      .flatMap((source) => source.nodes ?? [])
      .map((node) => (node.kind === 'Text' ? node.value : ''))
      .join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

Wire it into your config:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { parserText } from './parserText.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx, parserText],
})
```

### Parser anatomy

Every value returned from `defineParser` matches the `Parser` interface from [`kubb/kit`](#adapters-and-parsers):

| Property   | Type                                                                      | Required | When called                                  | Purpose                                                                                                                                              |
| ---------- | ------------------------------------------------------------------------- | -------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | `string`                                                                  | Yes      |                                              | Unique parser identifier. Convention is `parser-<id>`.                                                                                               |
| `extNames` | `Array<FileNode['extname']> \| undefined`                                 | Yes      |                                              | File extensions this parser handles. Set to `undefined` to register a catch-all fallback.                                                            |
| `parse`    | `(file: FileNode, options?: { extname?: FileNode['extname'] }) => string` | Yes      | By the file processor after all plugins run  | Serializes the file's staged sources into the final output string. Must return synchronously.                                                         |
| `print`    | `(...nodes: TNode[]) => string`                                           | Yes      | By plugins, before files are staged          | Renders compiler AST nodes to source text. The node type is parser-specific, for example `ts.Node` for `parserTs`. |

> [!IMPORTANT]
> If two parsers register the same extension, the first one in the `parsers` array wins. Order matters.

> [!NOTE]
> `parse()` is synchronous. The file processor streams files through a synchronous pipeline, so returning a `Promise` is not supported. Do async work before the file reaches the parser and pass the result through `FileNode`.

> [!NOTE]
> Formatting and linting (Prettier, Biome, oxlint) run after `parse()`. Keep `parse()` focused on producing syntactically valid output.

When no parser matches a file's extension, the file processor joins the file's source strings directly.

### Parser naming convention

Parsers share the layout of [plugins](/docs/5.x/guide/concepts/plugins) and [adapters](/docs/5.x/guide/concepts/adapters):

| Surface             | Pattern                                          | Example                          |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| npm package         | `@<scope>/parser-<name>` or `kubb-parser-<name>` | `@kubb/parser-ts`                |
| Parser runtime name | The output language or format (lowercase)        | `'typescript'`, `'markdown'`     |
| Factory export      | `parser<Name>` (camelCase)                       | `parserTs`, `parserMd`           |

Parsers export a plain [`Parser`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineParser.ts#L7) object, not a factory function. Pass them directly to `parsers:` in `defineConfig`:

```typescript twoslash [naming.ts]
import { defineParser } from 'kubb/kit'

export const parserCustom = defineParser({
  name: 'custom',
  extNames: ['.custom'],
  parse(file) {
    return file.sources.map((source) => source.name ?? '').join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

> [!TIP]
> Parsers compose by extension. `parserTs` (`.ts`, `.js`) and `parserTsx` (`.tsx`, `.jsx`) ship in the same [`@kubb/parser-ts`](/parsers/parser-ts/) package and register side by side.

### Built-in parsers

#### `@kubb/parser-ts`

The default parser for TypeScript and JavaScript output. It uses the official TypeScript compiler to resolve import paths, deduplicate declarations, print JSDoc, and rewrite extensions based on `output.extension`. See the [`@kubb/parser-ts` reference](/parsers/parser-ts/) for the full option list.

::: code-group

```shell [bun]
bun add -d @kubb/parser-ts@beta
```

```shell [pnpm]
pnpm add -D @kubb/parser-ts@beta
```

```shell [npm]
npm install --save-dev @kubb/parser-ts@beta
```

```shell [yarn]
yarn add -D @kubb/parser-ts@beta
```

:::

| Export      | Extensions handled | Notes                                   |
| ----------- | ------------------ | --------------------------------------- |
| `parserTs`  | `.ts`, `.js`       | TypeScript and plain JavaScript output. |
| `parserTsx` | `.tsx`, `.jsx`     | Same as `parserTs` with JSX support.    |

Both expose `parse(file, options?)` and `print(...nodes: ts.Node[])`. Call `parserTs.print(node)` from a plugin to render a TypeScript compiler node to its source string before staging it on `FileNode.sources`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx],
})
```

> [!TIP]
> `defineConfig` from the `kubb` package installs `parserTs`, `parserTsx`, and `parserMd` automatically. Set `parsers:` only when you add a custom parser or need to change the registration order.

### Creating a custom parser

`defineParser` is an identity wrapper that infers the parser type. It returns the object you pass in unchanged, with no per-build options:

```typescript twoslash [parserPython.ts]
import { defineParser } from 'kubb/kit'

export const parserPython = defineParser({
  name: 'parser-python',
  extNames: ['.py', '.pyi'],
  parse(file) {
    const lines: Array<string> = []

    if (file.banner) {
      lines.push(file.banner)
    }

    for (const source of file.sources) {
      for (const node of source.nodes ?? []) {
        if (node.kind === 'Text') {
          lines.push(node.value)
        }
      }
    }

    if (file.footer) {
      lines.push(file.footer)
    }

    return lines.join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

Register it alongside the built-ins:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { parserTs } from '@kubb/parser-ts'
import { parserPython } from './parserPython.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserPython],
})
```

> [!TIP]
> Set `extNames: undefined` to register a catch-all fallback that runs when no other parser matches. Useful for a default `.txt` writer or for inspecting what files the build produces.

> [!NOTE]
> `parse()` runs synchronously, so external formatting (a service call, a child process, or a worker thread) must finish before the file reaches the parser. Stage the pre-formatted output on `FileNode.sources[].nodes` inside a generator, then let the parser join it verbatim.

### How the file processor runs parsers

The file processor is internal to the Kubb engine and processes files one at a time. The build driver enqueues each file as plugins emit it, the processor runs it through `parse()`, and the result lands in storage without buffering the full set. Progress surfaces as `start`, `update` (with `{ file, source, processed, total, percentage }`), and `end` events on the main event bus, which the built-in reporters render. Memory stays flat regardless of build size because each file is pulled through the pipeline one at a time.

## Rendering

### `createRenderer`

`createRenderer` takes a builder function and returns a factory that produces a `Renderer`, the object a generator's `renderer` field points at. It follows the same builder-to-factory shape as `createStorage`: call the builder once, get back a reusable factory, call the factory to get an instance.

Reach for `createRenderer` when a generator needs to emit something other than plain `FileNode` arrays or [`kubb/jsx`](/docs/5.x/reference/jsx) elements, for example a renderer that walks a different templating format into `FileNode`s. `kubb/jsx`'s own `jsxRenderer` ships as a plain factory and does not depend on `createRenderer`, so most plugin authors only need `createRenderer` when they are building an alternative to JSX rendering.

#### Related

- [`jsxRenderer`](#jsxrenderer-via-kubb-jsx), the shipped JSX renderer
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

### `jsxRenderer` (via `kubb/jsx`) {#jsxrenderer-via-kubb-jsx}

For JSX-based rendering, import `jsxRenderer` from [`kubb/jsx`](/docs/5.x/reference/jsx), backed by the internal `@kubb/renderer-jsx` package.

`jsxRenderer` is a React-free recursive renderer. It walks the JSX components into `FileNode`s without a React reconciliation pass, and its `stream()` returns a synchronous `Generator<FileNode>` that skips a microtask per file. Components run as plain functions, so hooks and suspense are not available.

```typescript twoslash [renderer.ts]
import { jsxRenderer } from 'kubb/jsx'

const renderer = jsxRenderer()
```

Set the renderer on a generator through its `renderer` field (`renderer: jsxRenderer`) to enable JSX-based output for that generator. Leave it unset, or pass `renderer: null`, to opt out of rendering. See the [JSX API reference](/docs/5.x/reference/jsx) for `File`, `Function`, `Type`, `Const`, and the `jsx-runtime` / `jsx-dev-runtime` subpaths.

## Storage

Storage backends decide where generated files are written. Kubb ships a filesystem backend and an in-memory one. Use `createStorage` to build your own.

### `createStorage`

`createStorage` takes a builder function `(options: TOptions) => Storage` and returns a factory `(options?: TOptions) => Storage`. Call the returned factory to instantiate the storage, optionally with options.

```typescript twoslash [memory-storage.ts]
import { createStorage } from 'kubb/kit'

export const memoryStorage = createStorage(() => {
  const store = new Map<string, string>()
  return {
    name: 'memory',
    async hasItem(key) {
      return store.has(key)
    },
    async getItem(key) {
      return store.get(key) ?? null
    },
    async setItem(key, value) {
      store.set(key, value)
    },
    async removeItem(key) {
      store.delete(key)
    },
    async getKeys(base) {
      const keys = [...store.keys()]
      return base ? keys.filter((k) => k.startsWith(base)) : keys
    },
    async clear(base) {
      if (!base) return store.clear()
      for (const k of store.keys()) if (k.startsWith(base)) store.delete(k)
    },
  }
})
```

> [!TIP]
> Use `memoryStorage` for tests and dry runs. Use `fsStorage` for normal development and CI/CD.

### `Storage` interface {#storage-interface}

The `Storage` interface is the shape every backend implements. A `Storage` instance is what the engine consumes at build time and returns from `driver.storage`.

| Method         | Params                       | Returns                   | Purpose                                                 |
| -------------- | ---------------------------- | ------------------------- | ------------------------------------------------------- |
| `hasItem()`    | `key: string`                | `Promise<boolean>`        | Check whether an item exists                            |
| `getItem()`    | `key: string`                | `Promise<string \| null>` | Retrieve an item's content                              |
| `setItem()`    | `key: string, value: string` | `Promise<void>`           | Write an item                                           |
| `removeItem()` | `key: string`                | `Promise<void>`           | Delete an item                                          |
| `getKeys()`    | `base?: string`              | `Promise<string[]>`       | List keys, optionally filtered by prefix                |
| `clear()`      | `base?: string`              | `Promise<void>`           | Delete all items, optionally scoped by prefix           |

### `fsStorage`

`fsStorage` is the built-in filesystem storage backend. Kubb uses it by default when no `storage` option is set in the config. It creates output directories automatically and respects `output.path`.

### `memoryStorage`

`memoryStorage` is the built-in in-memory storage backend. It writes nothing to disk, so it suits plugin tests, CI validation, and dry runs.

> [!NOTE]
> Both `fsStorage` and `memoryStorage` are exported from `kubb/kit` and can be passed directly to the `storage` field at the root of your config.

#### Related

- [Configuration reference](/docs/5.x/reference/configuration)

## AST and node builders

### `ast`

`ast` is `kubb/kit`'s namespace for the entire AST surface, the same way TypeScript groups its node constructors under `ts.factory`. It carries the `factory` node builders, the `walk`, `transform`, and `collect` visitors, the guards, the ref and string helpers, and the macro engine. The namespace is backed by the internal `@kubb/ast` library. Always reach it through `kubb/kit`.

```typescript twoslash [ast-namespace.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [],
})
```

Node building goes through `ast.factory`. `ast.factory.createFile`, `ast.factory.createSource`, and `ast.factory.createText` build the `FileNode` tree a generator returns.

```typescript twoslash [factory.ts]
import { ast } from 'kubb/kit'

const file = ast.factory.createFile({
  baseName: 'pet.ts',
  path: './pet.ts',
  sources: [ast.factory.createSource({ nodes: [ast.factory.createText('export type Pet = { id: number }')] })],
})
```

For why the AST exists and how it fits the pipeline, see [AST concepts](/docs/5.x/guide/concepts/ast).

### Schema node types

A `SchemaNode` is discriminated by its `type`. The values fall into three families.

#### Structural types

| Type           | Description                             | TypeScript                      |
| -------------- | --------------------------------------- | ------------------------------- |
| `object`       | Object with named properties            | `{ name: string; age: number }` |
| `array`        | Sequence of items                       | `string[]`                      |
| `tuple`        | Fixed-length array with typed positions | `[string, number, boolean]`     |
| `union`        | One of multiple types                   | `string \| number`              |
| `intersection` | Combination of multiple types           | `A & B`                         |
| `enum`         | Fixed set of literal values             | `'active' \| 'inactive'`        |

#### Scalar types

| Type      | Description    | TypeScript |
| --------- | -------------- | ---------- |
| `string`  | Text value     | `string`   |
| `number`  | Numeric value  | `number`   |
| `integer` | Whole number   | `number`   |
| `bigint`  | Large integer  | `bigint`   |
| `boolean` | True/false     | `boolean`  |
| `null`    | Null value     | `null`     |
| `any`     | Any value      | `any`      |
| `unknown` | Unknown value  | `unknown`  |
| `void`    | No value       | `void`     |
| `never`   | Never produced | `never`    |

#### Special types

| Type       | Description                 | Example                                |
| ---------- | --------------------------- | -------------------------------------- |
| `ref`      | Reference to another schema | `Pet` (from `$ref`)                    |
| `date`     | ISO date                    | `2024-01-15`                           |
| `datetime` | ISO datetime                | `2024-01-15T10:30:00Z`                 |
| `time`     | ISO time                    | `10:30:00`                             |
| `uuid`     | UUID string                 | `550e8400-e29b-41d4-a716-446655440000` |
| `email`    | Email address               | `user@example.com`                     |
| `url`      | URL string                  | `https://example.com`                  |
| `blob`     | Binary data                 | Raw bytes                              |

### Factory functions

Factories return defaulted, fully typed nodes. Use them in adapters and inside generator handlers. Never build AST literals by hand.

```typescript twoslash [factories.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] }), ast.factory.createSchema({ name: 'Status', type: 'enum', values: ['active', 'inactive'] })],
  operations: [ast.factory.createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

The `ast.factory` namespace also provides constructors for source files and TypeScript-level artifacts that generators emit:

| Factory                                                             | Purpose                                                  |
| ------------------------------------------------------------------- | -------------------------------------------------------- |
| `createFile`, `createSource`, `createText`                          | Build `FileNode`s emitted by generators.                 |
| `createImport`, `createExport`                                      | Emit `import` / `export` statements.                     |
| `createConst`, `createFunction`, `createArrowFunction`, `createJsx` | Emit TypeScript declarations and JSX.                    |
| `createParameter`                                                   | Describe operation parameters.                           |
| `createProperty`, `createType`                                      | Compose object properties and TypeScript types.          |
| `createResponse`, `createRequestBody`, `createContent`, `createOutput` | Model responses, request bodies, content entries, and generator outputs. |
| `createBreak`                                                       | Emit line breaks between nodes.                          |
| `update`                                                            | Apply an identity-preserving shallow update to any node. |

### Visitors {#visitors}

Three visitor functions cover the common traversal patterns. Visitor objects use lowercase, kind-style keys (`input`, `operation`, `schema`, `property`, `parameter`, `response`). To rewrite nodes inside a plugin, reach for [macros](/docs/5.x/guide/going-further/macros). They add names, ordering, and composition on top of `transform`.

#### `walk`: async traversal with side effects

```typescript twoslash [walk.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

await ast.walk(root, {
  async operation(node) {
    console.log(`Found ${node.method} ${node.path}`)
  },
  async schema(node) {
    if ('deprecated' in node && node.deprecated) {
      console.warn(`Schema ${'name' in node ? node.name : '?'} is deprecated`)
    }
  },
})
```

Use `walk` to log, validate, collect statistics, or trigger a side effect per node.

#### `transform`: synchronous, returns a new tree

```typescript twoslash [transform.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const enhanced = ast.transform(root, {
  schema(node) {
    if (node.type === 'object' && node.additionalProperties === undefined) {
      return { ...node, additionalProperties: false }
    }
    return node
  },
  operation(node) {
    return { ...node, tags: node.tags?.length ? node.tags : ['untagged'] }
  },
})
```

Use `transform` to change AST structure, normalize inconsistencies, or annotate nodes.

> [!NOTE]
> `transform` preserves identity through structural sharing. When a visitor leaves a node and all its descendants unchanged, `transform` returns the original reference, so unchanged subtrees and their arrays are reused, not copied. Returning the same node is a no-op. Returning a new node replaces it and rebuilds only its ancestors. A no-op pass allocates nothing, and you detect whether anything changed with `result === input`.

To apply a change and keep that guarantee, use the `update` factory instead of spreading by hand. It returns the same node when every field you pass already matches:

```typescript twoslash [update.ts]
import { ast } from 'kubb/kit'

const node = ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })

ast.factory.update(node, { name: 'Pet' }) // -> same `node` reference (no change)
ast.factory.update(node, { name: 'Animal' }) // -> new node with `name` replaced
```

#### `collect`: gather matching nodes

```typescript twoslash [collect.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const mutations = ast.collect<ast.OperationNode>(root, {
  operation(node) {
    return node.method === 'POST' ? node : undefined
  },
})

const deprecated = ast.collect<ast.SchemaNode>(root, {
  schema(node) {
    return 'deprecated' in node && node.deprecated ? node : undefined
  },
})

console.log(`POST operations: ${mutations.length}`)
console.log(`Deprecated schemas: ${deprecated.length}`)
```

Use `collect` to find specific nodes, filter by a criterion, or build a list for later processing.

### Guards and narrowing {#guards-and-narrowing}

Kubb exports type guards and a `narrowSchema` helper for safe discrimination:

```typescript twoslash [guards.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

await ast.walk(root, {
  async schema(node) {
    const obj = ast.narrowSchema(node, 'object')
    if (obj) {
      console.log(`object with ${obj.properties.length} properties`)
    }

    if (node.type === 'ref') {
      console.log(`reference to: ${node.ref}`)
    }
  },
  async operation(node) {
    if (ast.isHttpOperationNode(node)) {
      console.log(`${node.method} ${node.path}`)
    }
  },
})
```

### Refs and naming helpers

The ref and naming helpers ship on the `ast` namespace, alongside the other string and code-building utilities. Reach them the same way you reach the guards or node types.

| Helper           | Purpose                                            |
| ---------------- | --------------------------------------------------- |
| `extractRefName` | Turn `'#/components/schemas/Pet'` into `'Pet'`.    |
| `childName`      | Derive a child property name from context.         |
| `enumPropName`   | Convert an enum value into a valid property name.  |

```typescript twoslash [refs.ts]
import { ast } from 'kubb/kit'

const name = ast.extractRefName('#/components/schemas/Pet')
//    ^?
```

### Constants

| Export        | Purpose                                    |
| ------------- | ------------------------------------------ |
| `schemaTypes` | Map of every schema `type` discriminant.   |

### Macros

A macro is a named, composable transform built on `transform`. Macros rewrite nodes before printing, with ordering, gating, and reuse that a bare visitor does not give you. See [Macros concepts](/docs/5.x/guide/going-further/macros).

| Export          | Purpose                                          |
| --------------- | ------------------------------------------------ |
| `defineMacro`   | Type a macro and read it as one definition.      |
| `composeMacros` | Fold an ordered list of macros into one visitor. |
| `applyMacros`   | Run a list of macros over a node tree.           |

### Printers

Lower-level helpers for parsers that turn the AST into source code:

| Export          | Purpose                                |
| --------------- | -------------------------------------- |
| `createPrinter` | Typed helper for creating a `Printer`. |

`createPrinter` takes an `overrides` map to replace the handler for individual schema node types. Inside an override, `this.base(node)` runs the built-in handler the override replaced, so you can wrap its output instead of re-implementing it. Pass overrides through the `overrides` field rather than spreading them into `nodes`, otherwise `this.base` cannot find the original handler. The `printer.nodes` option on `@kubb/plugin-ts`, `@kubb/plugin-zod`, and `@kubb/plugin-faker` feeds this map. See [Override a printer](/docs/5.x/guide/going-further/printers).

See [Parsers concepts](/docs/5.x/guide/concepts/parsers) for how parsers consume printers. `defineDialect` is the adapter seam for spec-specific schema behavior. It keeps the shared converters generic, so an adapter supplies only the questions that differ between specs. See [Schema dispatch and dialects](#schema-dispatch-and-dialects).

### Collect every operation tag

```typescript twoslash [tags.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const tags = new Set(
  ast.collect<string>(root, {
    operation(node) {
      return node.tags?.[0]
    },
  }),
)

console.log([...tags])
```

## Diagnostics

### `Diagnostics`

`Diagnostics` is the namespace a plugin or adapter uses to build and narrow the structured errors Kubb collects during a build. Throw or return a `Diagnostics.Error` instead of a bare `Error` when you want a stable code, a severity, and a location attached.

| Member                  | Purpose                                                                 |
| ----------------------- | -------------------------------------------------------------------------|
| `Diagnostics.Error`     | Constructs a diagnostic-carrying error with a `code`, `severity`, and `message` |
| `Diagnostics.hasError`  | Narrows an array of diagnostics to whether any has `severity: 'error'` |
| `Diagnostics.isProblem` | Guards a diagnostic down to the problem kind (as opposed to `performance` or `update`) |

See the [Diagnostics reference](/docs/5.x/reference/diagnostics) for the full list of stable codes Kubb ships with, and how `Diagnostics.hasError` and `Diagnostics.isProblem` are used together after a build.

## Engine and configuration {#engine-and-configuration}

The engine that runs your plugins comes from the `kubb` package and its `kubb/config` subpath, backed by the internal `@kubb/core` library. This section documents that surface: `defineConfig`, `createKubb`, and the build types they share.

### `defineConfig`

`defineConfig` adds TypeScript type-checking to a `kubb.config.ts` file. It comes from the `kubb` package and fills in defaults for any field you omit.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
})
```

It accepts a config object, an array of configs, a Promise, or a function. The function form receives the [CLI options](/docs/5.x/reference/commands/) at runtime, so you can toggle behavior on flags like `--watch`:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig(({ watch }) => ({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: !watch },
}))
```

#### Defaults applied for omitted fields

| Field            | Default                                  |
| ---------------- | ---------------------------------------- |
| `root`           | `process.cwd()`                          |
| `adapter`        | [`adapterOas()`](/docs/5.x/guide/concepts/adapters) |
| `parsers`        | `[parserTs, parserTsx, parserMd]`        |
| `reporters`      | `[cli, json, file]`                      |
| `plugins`        | `pluginBarrel()` appended when not already present |
| `output.barrel`  | `{ type: 'named' }`, only when `pluginBarrel` is in `plugins` |
| `output.format`  | `false`                                  |
| `output.lint`    | `false`                                  |

> [!IMPORTANT]
> `defineConfig` comes from the `kubb` package. Import it from `kubb` or the `kubb/config` subpath.

> [!TIP]
> The `output.barrel` default of `{ type: 'named' }` applies only when `pluginBarrel` is present in `plugins`. A plugins list without `pluginBarrel` leaves barrel generation untouched.

#### Related

- [Configuration reference](/docs/5.x/reference/configuration)
- [CLI options](/docs/5.x/reference/commands/)
- [`@kubb/plugin-barrel`](/plugins/plugin-barrel/)

### `createKubb` {#createkubb}

`createKubb` drives Kubb from your own code. It accepts a `UserConfig` and returns a `Kubb` instance. Calling `.build()` runs the full generation pipeline and returns a `BuildOutput`.

Reach for `createKubb` when you orchestrate several builds, inspect diagnostics, or feed Kubb output into a larger toolchain. For a one-off build, chain the call: `await createKubb(config).build()`.

Import `createKubb` from the `kubb` package. Unlike `defineConfig`, `createKubb` adds no defaults, so pass `adapter`, `parsers`, and your plugins yourself.

`createKubb` takes a plain config object, the same shape `defineConfig` produces in `kubb.config.ts`. It is not a fluent builder. The config stays plain serializable data so Kubb can validate it against the shipped JSON schema.

```typescript twoslash [build.ts]
// @module: esnext
import { createKubb } from 'kubb'
import { Diagnostics } from 'kubb/kit'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

const kubb = createKubb({
  adapter: adapterOas(),
  parsers: [parserTs, parserTsx],
  input: { path: './petStore.yaml' },
  output: { path: './gen' },
  plugins: [pluginTs(), pluginAxios()],
})

const { files, storage, driver, diagnostics } = await kubb.safeBuild()

if (Diagnostics.hasError(diagnostics)) {
  for (const diagnostic of diagnostics.filter(Diagnostics.isProblem)) {
    if (diagnostic.severity === 'error') {
      console.error(`${diagnostic.plugin ?? 'kubb'}: ${diagnostic.message}`)
    }
  }
  process.exit(1)
}

// Per-plugin timings are carried as `performance` diagnostics.
for (const { plugin, duration } of diagnostics.filter(Diagnostics.isPerformance)) {
  console.log(`${plugin}: ${duration}ms`)
}
console.log(`Generated ${files.length} files`)
const paths = await storage.getKeys()
paths.forEach((path) => console.log(`  ${path}`))
```

#### `Kubb` instance members (all getters are read-only)

| Member         | Type                           | Description                                                                                        |
| -------------- | ------------------------------ | -------------------------------------------------------------------------------------------------- |
| `.setup()`     | `() => Promise<void>`          | Initializes the driver and storage. `build()` calls this automatically.                            |
| `.build()`     | `() => Promise<BuildOutput>`   | Runs the full pipeline and throws a `BuildError` when any diagnostic is an error.                  |
| `.safeBuild()` | `() => Promise<BuildOutput>`   | The canonical call. Runs the full pipeline and collects problems in `BuildOutput.diagnostics` instead of throwing. |
| `.hooks`       | `Hookable<KubbHooks>`          | Read-only. Shared hook emitter. Call `.hook(name, handler)` before `build()` to attach a listener. |
| `.config`      | `Config`                       | Read-only. Resolved config, available right after `createKubb` since it resolves in the constructor. |
| `.storage`     | `Storage`                      | Read-only getter. Final source code keyed by absolute path. Available after `setup()`, throws before. |
| `.driver`      | read-only getter               | Advanced plugin driver handle, available after `setup()`. Throws if accessed before `setup()`.     |

#### `BuildOutput` fields

| Field         | Type                | Description                                                                |
| ------------- | ------------------- | -------------------------------------------------------------------------- |
| `files`       | `Array<FileNode>`   | Generated files with paths, names, and content                                  |
| `storage`     | `Storage`           | Generated source code accessible via the `Storage` API                          |
| `driver`      | driver handle       | Advanced plugin driver handle for introspection                                 |
| `diagnostics` | `Array<Diagnostic>` | Problems collected during the build, plus a `performance` diagnostic per plugin |

Each `Diagnostic` carries a `code`, a `severity` (`error`, `warning`, or `info`), a `message`, and the `plugin` that produced it. Failed-plugin diagnostics keep the original error on `cause`. A `performance` diagnostic (`kind: 'performance'`) carries a `duration` in milliseconds. Use the `Diagnostics.isProblem`, `Diagnostics.isPerformance`, and `Diagnostics.isUpdate` guards to narrow by kind.

> [!WARNING]
> After `safeBuild()`, check `Diagnostics.hasError(diagnostics)` before processing files. Plugins can fail without `safeBuild()` throwing. `build()` throws a `BuildError` in that case.

#### Related

- [Programmatic usage recipe](/docs/5.x/guide/recipes#programmatic-build)

### Narrowing `config.input`

`config.input` is either the `{ path: string }` form or the `{ data: string | unknown }` form. Narrow between them with an [`in` check](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#the-in-operator-narrowing):

```typescript twoslash [narrow.ts]
import type { UserConfig } from 'kubb/kit'

declare const input: NonNullable<UserConfig['input']>

if ('path' in input) {
  const filePath = input.path // narrowed to string
} else {
  const spec = input.data // narrowed to the spec object or string
}
```

## Testing

`kubb/kit/testing` is a separate subpath for the Vitest-backed helpers used to test plugins, generators, and adapters. It stays separate from `kubb/kit` so importing the authoring toolkit never pulls Vitest into a plugin's runtime dependencies.

```typescript twoslash [plugin.test.ts]
import { createMockedPlugin, renderGeneratorOperation, matchFiles } from 'kubb/kit/testing'
```

`createMockedPlugin` and `createMockedAdapter` build a minimal plugin or adapter for a test without wiring a full config. `createMockedPluginDriver` builds a driver around a set of plugins so a generator can run through its real lifecycle in isolation. `renderGeneratorSchema`, `renderGeneratorOperation`, and `renderGeneratorOperations` call a generator's `schema()`, `operation()`, or `operations()` method directly against a node fixture and return the resulting files. `matchFiles` asserts a set of generated `FileNode`s matches expected paths and contents, the assertion most generator tests end on.

## See also

- [Kit concepts](/docs/5.x/guide/concepts/kit) for why the authoring toolkit is a separate surface from the engine
- [JSX API reference](/docs/5.x/reference/jsx) for `kubb/jsx`, the JSX renderer
- [Plugin concepts](/docs/5.x/guide/concepts/plugins) for lifecycle hooks, generators, resolvers, and the plugin registry
- [AST concepts](/docs/5.x/guide/concepts/ast) for `InputNode`, `OperationNode`, `SchemaNode`, and traversal
- [Adapter concepts](/docs/5.x/guide/concepts/adapters) on how adapters convert specs to the universal AST
- [Parser concepts](/docs/5.x/guide/concepts/parsers) on converting `FileNode` AST to source strings
- [Macros concepts](/docs/5.x/guide/going-further/macros) for `defineMacro`, `composeMacros`, and `applyMacros`
- [Barrel files](/docs/5.x/guide/going-further/barrel-files) for barrel generation with `@kubb/plugin-barrel`
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide to building a full plugin
- [Programmatic usage recipes](/docs/5.x/guide/recipes#programmatic-build) with `createKubb` usage patterns
- [Configuration reference](/docs/5.x/reference/configuration) for all `defineConfig` options
