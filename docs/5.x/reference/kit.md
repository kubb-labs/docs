---
layout: doc
title: Kit API
description: Public API surface of kubb/kit, the plugin and generator authoring toolkit, including definePlugin, defineGenerator, defineResolver, defineParser, createAdapter, createRenderer, createStorage, Diagnostics, the ast and factory namespaces, and the kubb/kit/testing helpers.
outline: [2, 3]
---

# Kit API

`kubb/kit` is the authoring toolkit for extending Kubb: plugins, generators, resolvers, parsers, adapters, renderers, and storage backends all start here. It is a subpath of the top-level `kubb` package, backed by the `@kubb/kit` package, so there is nothing extra to install. Import straight from `kubb/kit`.

```typescript twoslash [imports.ts]
import {
  definePlugin,
  defineGenerator,
  defineResolver,
  defineParser,
  createAdapter,
  createRenderer,
  createStorage,
  memoryStorage,
  fsStorage,
  Diagnostics,
  ast,
  factory,
} from 'kubb/kit'
```

> [!TIP]
> The build-time engine (`createKubb`) lives in the [`kubb`](/docs/5.x/reference/core) package. `kubb/kit` is only for the authoring side: the code you write to add a new plugin, generator, resolver, parser, adapter, or renderer.

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
| `updateConfig`   | `(config: Partial<Config>) => void`                             | Merge a partial config update into the current build config   |
| `config`         | `Config`                                                        | The resolved build configuration at setup time                |
| `options`        | `TOptions`                                                      | The plugin's own options as passed by the user                |

> [!IMPORTANT]
> Plugin names should follow the convention `plugin-<feature>` (e.g., `plugin-react-query`, `plugin-zod`). See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for naming conventions.

#### Related

- [Full Plugin API reference](/docs/5.x/guide/concepts/plugins)
- [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins)

### `defineGenerator` {#defineGenerator}

`defineGenerator` declares a named generator unit consumed by a plugin. Generators walk the [AST](/docs/5.x/guide/concepts/ast) and emit files. The core calls each method for the matching node type during the generation loop.

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
| `ctx.hooks`           | `AsyncEventEmitter<KubbHooks>`                      | Event bus for `KubbHooks` events                                     |
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

### `defineResolver`

`defineResolver` creates a resolver that controls file naming and path resolution for a plugin. The builder is a zero-argument function. Use `this` to call sibling resolver methods.

The builder must return at least `{ name, pluginName }`. The other resolver methods (`default`, `resolveOptions`, `resolvePath`, `resolveFile`, `resolveBanner`, `resolveFooter`) receive built-in defaults and can each be overridden.

```typescript twoslash [resolver.ts]
import { defineResolver } from 'kubb/kit'
import type { PluginFactoryOptions, Resolver } from 'kubb/kit'

// Extend the base Resolver with plugin-specific naming methods.
type MyResolver = Resolver & {
  resolveName(node: { name: string }): string
}

type MyPlugin = PluginFactoryOptions<'plugin-example', object, object, MyResolver>

export const resolver = defineResolver<MyPlugin>(() => ({
  name: 'default',
  pluginName: 'plugin-example',
  resolveName(node) {
    return this.default(node.name, 'function')
  },
}))
```

#### Auto-injected resolver defaults

| Method           | Default behavior                                                       |
| ---------------- | ------------------------------------------------------------------------|
| `default`        | `camelCase` for `function`/`file`, `PascalCase` for `type`             |
| `resolveOptions` | Applies `exclude`, `include`, and `override` filters                   |
| `resolvePath`    | Resolves to `output.path`, with optional tag/path-based subdirectories |
| `resolveFile`    | Constructs a full `FileNode` using `default` + `resolvePath`           |
| `resolveBanner`  | Returns `output.banner` or the standard "Generated by Kubb" header     |
| `resolveFooter`  | Returns `output.footer` when set                                       |

#### Related

- [Plugin API: resolvers](/docs/5.x/guide/concepts/plugins#resolvers)
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

### `defineParser`

`defineParser` creates a parser that converts generated file ASTs to formatted source strings. Each parser declares which file extensions it handles via `extNames`.

The built-in parsers handle TypeScript, TSX, and markdown files: [`parserTs`, `parserTsx`](/docs/5.x/guide/concepts/parsers), and `parserMd`. Implement `defineParser` to add other languages or custom output formats.

#### Related

- [Parser concepts](/docs/5.x/guide/concepts/parsers)

### `createAdapter`

`createAdapter` builds adapters that translate non-OpenAPI specs into Kubb's universal [AST](/docs/5.x/guide/concepts/ast). The built-in [`@kubb/adapter-oas`](/docs/5.x/guide/concepts/adapters) handles OpenAPI and Swagger documents.

Write a custom adapter when your source is something Kubb does not parse yet, such as a GraphQL schema, a gRPC definition, an AsyncAPI spec, or your own domain-specific language.

> [!IMPORTANT]
> Adapters must parse their input format to Kubb's `InputNode` structure. See [Adapter API](/docs/5.x/guide/concepts/adapters) for complete documentation.

#### Related

- [Adapter concepts](/docs/5.x/guide/concepts/adapters)
- [Creating a custom adapter](/docs/5.x/reference/adapters#creating-a-custom-adapter)

## Rendering

### `createRenderer`

`createRenderer` takes a builder function and returns a factory that produces a `Renderer`, the object a generator's `renderer` field points at. It follows the same builder-to-factory shape as `createStorage`: call the builder once, get back a reusable factory, call the factory to get an instance.

Reach for `createRenderer` when a generator needs to emit something other than plain `FileNode` arrays or [`kubb/jsx`](/docs/5.x/reference/jsx) elements, for example a renderer that walks a different templating format into `FileNode`s. `kubb/jsx`'s own `jsxRenderer` ships as a plain factory and does not depend on `createRenderer`, so most plugin authors only need `createRenderer` when they are building an alternative to JSX rendering.

#### Related

- [`jsxRenderer`](/docs/5.x/reference/core#jsxrenderer-via-kubb-jsx), the shipped JSX renderer documented on the Core API reference
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

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
    async dispose() {
      store.clear()
    },
  }
})
```

> [!TIP]
> Use `memoryStorage` for tests and dry runs. Use `fsStorage` for normal development and CI/CD.

The `Storage` interface itself (`hasItem`, `getItem`, `setItem`, `removeItem`, `getKeys`, `clear`, `dispose`) is documented on the [engine reference](/docs/5.x/reference/core#storage), since `Storage` describes something the engine consumes, not something `kubb/kit` defines.

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

`ast` is `kubb/kit`'s namespace for the [entire AST surface](/docs/5.x/reference/ast), the same way TypeScript groups its node constructors under `ts.factory`. Reach for `ast` when you also need the visitors (`ast.walk`, `ast.transform`, `ast.collect`), the guards, or the schema and string helpers alongside node construction.

```typescript twoslash [ast-namespace.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [],
})
```

### `factory`

`factory` is the bare node-builder namespace, equivalent to `ast.factory` but importable on its own when a generator only needs to construct nodes and does not need the rest of the `ast` namespace.

```typescript twoslash [factory-namespace.ts]
import { factory } from 'kubb/kit'

const file = factory.createFile({
  baseName: 'pet.ts',
  path: './pet.ts',
  sources: [factory.createSource({ nodes: [factory.createText("export type Pet = { id: number }")] })],
})
```

`ast.factory.createX(...)` and the bare `factory.createX(...)` construct the same nodes. Pick whichever import reads better in the file: `ast.factory` when the file already uses `ast.walk` or `ast.transform` nearby, `factory` on its own when node construction is the only thing the file does. Both come from `kubb/kit`.

#### Related

- [AST concepts](/docs/5.x/guide/concepts/ast) for the full mental model of the AST, its node kinds, and traversal
- [AST API reference](/docs/5.x/reference/ast) for every factory, visitor, and guard the AST exposes

## Diagnostics

### `Diagnostics`

`Diagnostics` is the namespace a plugin or adapter uses to build and narrow the structured errors Kubb collects during a build. Throw or return a `Diagnostics.Error` instead of a bare `Error` when you want a stable code, a severity, and a location attached.

| Member                  | Purpose                                                                 |
| ----------------------- | -------------------------------------------------------------------------|
| `Diagnostics.Error`     | Constructs a diagnostic-carrying error with a `code`, `severity`, and `message` |
| `Diagnostics.hasError`  | Narrows an array of diagnostics to whether any has `severity: 'error'` |
| `Diagnostics.isProblem` | Guards a diagnostic down to the problem kind (as opposed to `performance` or `update`) |

See the [Diagnostics reference](/docs/5.x/reference/diagnostics) for the full list of stable codes Kubb ships with, and how `Diagnostics.hasError` and `Diagnostics.isProblem` are used together after a build.

## Public types

`kubb/kit` re-exports the types that go with plugin, generator, resolver, adapter, and renderer authoring. Import them alongside the functions above to type your own code. `Config` and `UserConfig`, the overall build configuration shapes, are re-exported here too, next to `defineConfig` and `createKubb` from the `kubb` package.

#### Plugins

| Type                     | Purpose                                            |
| ------------------------ | --------------------------------------------------- |
| `Plugin`                 | Final plugin object returned from `definePlugin`   |
| `PluginFactoryOptions`   | Generic parameter pack used to type a plugin       |
| `KubbPluginSetupContext` | Context passed to `kubb:plugin:setup`              |
| `KubbHooks`              | Map of every lifecycle event the driver emits      |

#### Generators

| Type               | Purpose                                                                 |
| ------------------ | ------------------------------------------------------------------------|
| `Generator`        | Generator object returned from `defineGenerator`                        |
| `GeneratorContext` | Context passed to `schema()`, `operation()`, and `operations()` methods |

#### Resolvers

| Type                    | Purpose                                                                        |
| ----------------------- | --------------------------------------------------------------------------------|
| `Resolver`              | Base constraint for resolvers returned from `defineResolver`                   |
| `ResolverContext`       | Shared context for path, file, and name resolution                             |
| `ResolverPathParams`    | Parameters for `Resolver.resolvePath`                                          |
| `ResolverFileParams`    | Parameters for `Resolver.resolveFile`                                          |
| `ResolveBannerContext`  | Context for banner and footer resolution (`output`, `config`, per-file `file`) |
| `ResolveBannerFile`     | Per-file context (`path`, `baseName`, `isBarrel`, `isAggregation`)             |
| `BannerMeta`            | `InputMeta` extended with per-file fields, passed to a `banner` or `footer` function |
| `ResolveOptionsContext` | Context for `resolveOptions` (include, exclude, override)                      |

#### Adapters and parsers

| Type                    | Purpose                                                        |
| ----------------------- | ----------------------------------------------------------------|
| `Adapter`               | Final adapter object returned from `createAdapter`             |
| `AdapterFactoryOptions` | Generic parameter pack for an adapter                          |
| `AdapterSource`         | `{ type: 'path'; path }` or `{ type: 'data'; data }`          |
| `Parser`                | Final parser object returned from `defineParser`               |

#### Rendering

| Type                           | Purpose                                                               |
| ------------------------------ | -----------------------------------------------------------------------|
| `Renderer` / `RendererFactory` | Interfaces for custom renderers set on a generator's `renderer` field |

#### Output and filters

| Type              | Purpose                                                |
| ----------------- | --------------------------------------------------------|
| `Output`          | Per-plugin output configuration                        |
| `OutputMode`      | `'directory' \| 'file'`                                |
| `OutputOptions`   | Output plus a `group` strategy                         |
| `Group`           | Grouping strategy for generated files                  |
| `Include`         | Filter narrowing generation to matching nodes          |
| `Exclude`         | Filter preventing matching nodes from being generated  |
| `Override`        | Filter pairing a match with per-node option overrides  |

## Testing

`kubb/kit/testing` is a separate subpath for the Vitest-backed helpers used to test plugins, generators, and adapters. It stays separate from `kubb/kit` so importing the authoring toolkit never pulls Vitest into a plugin's runtime dependencies.

```typescript twoslash [plugin.test.ts]
import { createMockedPlugin, renderGeneratorOperation, matchFiles } from 'kubb/kit/testing'
```

`createMockedPlugin` and `createMockedAdapter` build a minimal plugin or adapter for a test without wiring a full config. `createMockedPluginDriver` builds a driver around a set of plugins so a generator can run through its real lifecycle in isolation. `renderGeneratorSchema`, `renderGeneratorOperation`, and `renderGeneratorOperations` call a generator's `schema()`, `operation()`, or `operations()` method directly against a node fixture and return the resulting files. `matchFiles` asserts a set of generated `FileNode`s matches expected paths and contents, the assertion most generator tests end on.

## See also

- [Core API](/docs/5.x/reference/core) for the engine: `createKubb`, `KubbDriver`, storage, reporters, and the file pipeline
- [AST API reference](/docs/5.x/reference/ast) for the full AST surface behind `kubb/kit`'s `ast` and `factory`
- [JSX API reference](/docs/5.x/reference/jsx) for `kubb/jsx`, the JSX renderer
- [Plugin concepts](/docs/5.x/guide/concepts/plugins) for lifecycle hooks, generators, resolvers, and the plugin registry
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide to building a full plugin
