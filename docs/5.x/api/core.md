---
layout: doc
title: Core API
description: Public API surface of @kubb/core including createKubb, definePlugin, defineGenerator, defineResolver, defineParser, createAdapter, createStorage, Diagnostics, KubbDriver, and all public types.
outline: [2, 3]
---

# Core API

`@kubb/core` is the low-level foundation of Kubb. It exports the primitives you need to embed Kubb in your own code, write a plugin, implement a storage backend, or extend the generation pipeline.

::: code-group

```shell [bun]
bun add -d @kubb/core@beta
```

```shell [pnpm]
pnpm add -D @kubb/core@beta
```

```shell [npm]
npm install --save-dev @kubb/core@beta
```

```shell [yarn]
yarn add -D @kubb/core@beta
```

:::

> [!TIP]
> Most users do not install `@kubb/core` directly. The top-level [`kubb`](https://www.npmjs.com/package/kubb) package re-exports it with `adapterOas` and `parserTs` pre-installed. Use `@kubb/core` directly when embedding Kubb programmatically or writing a plugin.

```typescript twoslash
import { defineConfig } from 'kubb'
import {
  defineGenerator,
  defineParser,
  definePlugin,
  defineResolver,
  createAdapter,
  createKubb,
  createStorage,
  createReporter,
  fsStorage,
  memoryStorage,
  cliReporter,
  jsonReporter,
  fileReporter,
  KubbDriver,
  Diagnostics,
  AsyncEventEmitter,
  Url,
  logLevel,
  ast,
} from '@kubb/core'
```

> [!NOTE]
> `@kubb/core` re-exports the entire [`@kubb/ast`](/docs/5.x/concepts/ast) module under the `ast` namespace. You can equivalently import helpers directly from `@kubb/ast`.

## Configuration

### `defineConfig`

`defineConfig` is the primary way to add TypeScript type-checking to a `kubb.config.ts` file. It is exported from the `kubb` package (not `@kubb/core`) and automatically applies production-ready defaults: [`adapterOas`](/docs/5.x/concepts/adapters) as the adapter, `[parserTs, parserTsx, parserMd]` as parsers, and `[pluginBarrel()]` as a post-enforced plugin.

```typescript twoslash
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
})
```

The function form receives the [CLI options](/docs/5.x/api/commands/) at runtime, which lets you toggle behavior based on flags like `--watch`:

```typescript twoslash
import { defineConfig } from 'kubb'

export default defineConfig(({ watch }) => ({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: !watch },
}))
```

> [!IMPORTANT]
> `defineConfig` is only exported from the `kubb` package. The `@kubb/core` package exports the raw `UserConfig` type but does not provide a `defineConfig` with defaults.

> [!TIP]
> The `output.barrel` default of `{ type: 'named' }` applies only when `pluginBarrel` is present in `plugins`. Configs that omit it leave barrel generation untouched.

#### Related

- [Configuration reference](/docs/5.x/reference/configuration)
- [CLI options](/docs/5.x/api/commands/)
- [`@kubb/plugin-barrel`](/plugins/plugin-barrel)

## Build

### `createKubb`

`createKubb` is the entry point for driving Kubb from your own code. It accepts a `UserConfig` and returns a `Kubb` instance. Calling `.build()` on the instance runs the full generation pipeline and returns a `BuildOutput` object.

Reach for `createKubb` when you need to orchestrate several builds, inspect diagnostics, or feed Kubb output into a larger toolchain. For a one-off build, chain the call directly: `await createKubb(config).build()`.

`createKubb` takes a plain config object, the same shape `defineConfig` produces in `kubb.config.ts`. It is not a fluent builder, and that stays deliberate. A builder cannot live in a config file, and the config has to remain plain serializable data so Kubb can validate it against the shipped JSON schema.

```typescript twoslash
// @module: esnext
import { createKubb, Diagnostics } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

const kubb = createKubb({
  input: { path: './petStore.yaml' },
  output: { path: './gen' },
  plugins: [pluginTs(), pluginClient()],
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
| `.hooks`       | `AsyncEventEmitter<KubbHooks>` | Read-only. Shared event emitter; attach listeners before calling `build()`.                        |
| `.config`      | `Config`                       | Read-only. Resolved config, available right after `createKubb` since it resolves in the constructor. |
| `.storage`     | `Storage`                      | Read-only getter. Final source code keyed by absolute path. Available after `setup()`, throws before. |
| `.driver`      | `KubbDriver`                 | Read-only getter. Available after `setup()`. Throws if accessed before `setup()`.                  |

#### `BuildOutput` fields

| Field         | Type                | Description                                                                |
| ------------- | ------------------- | -------------------------------------------------------------------------- |
| `files`       | `Array<FileNode>`   | Generated files with paths, names, and content                                  |
| `storage`     | `Storage`           | Generated source code accessible via the `Storage` API                          |
| `driver`      | `KubbDriver`        | Plugin driver instance for advanced introspection                               |
| `diagnostics` | `Array<Diagnostic>` | Problems collected during the build, plus a `performance` diagnostic per plugin |

Each `Diagnostic` carries a `code`, a `severity` (`error`, `warning`, or `info`), a `message`, and the `plugin` that produced it. Failed-plugin diagnostics also keep the original error on `cause`, and `performance` diagnostics (`kind: 'performance'`) carry a `duration` in milliseconds. Use the `Diagnostics.isProblem`, `Diagnostics.isPerformance`, and `Diagnostics.isUpdate` guards to narrow by kind.

> [!WARNING]
> After `safeBuild()`, check `Diagnostics.hasError(diagnostics)` before processing files. Plugins can fail without `safeBuild()` throwing. `build()` throws a `BuildError` in that case instead.

#### Related

- [Programmatic usage recipe](/docs/5.x/recipes#programmatic-build)
- [`KubbDriver`](#kubbdriver)

## Plugin authoring

Plugins are the main extension point in Kubb. A plugin owns its file naming, its output folder, its lifecycle hooks, and the [generators](#definegenerator) that walk the [AST](/docs/5.x/concepts/ast) and emit `FileNode` objects.

### `definePlugin`

`definePlugin` wraps a factory function and returns a typed `Plugin`. All lifecycle handlers live under a single `hooks` object, inspired by [Astro integrations](https://docs.astro.build/en/reference/integrations-reference/).

```typescript twoslash
import { definePlugin } from '@kubb/core'

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
| `hooks`        | `{ 'kubb:plugin:setup'?: ...; ... }` | Yes      | Lifecycle handlers (see [Plugin API](../concepts/plugins)) |

#### `KubbPluginSetupContext` methods (passed to `kubb:plugin:setup`)

| Method           | Signature                               | Purpose                                                         |
| ---------------- | --------------------------------------- | --------------------------------------------------------------- |
| `addGenerator`   | `(generator: Generator) => void`        | Register a generator for this plugin                            |
| `setResolver`    | `(resolver: Partial<Resolver>) => void` | Set or partially override the file naming resolver              |
| `addMacro`       | `(macro: Macro) => void`                | Add a macro that rewrites AST nodes before generators           |
| `setMacros`      | `(macros: Array<Macro>) => void`        | Replace this plugin's macros with a new list                    |
| `setOptions`     | `(options: ResolvedOptions) => void`    | Set the resolved options used by generators                     |
| `injectFile`     | `(file: UserFileNode) => void`          | Inject a raw file into the build output, bypassing generation   |
| `updateConfig`   | `(config: Partial<Config>) => void`     | Merge a partial config update into the current build config     |
| `config`         | `Config`                                | The resolved build configuration at setup time                  |
| `options`        | `TOptions`                              | The plugin's own options as passed by the user                  |

> [!IMPORTANT]
> Plugin names should follow the convention `plugin-<feature>` (e.g., `plugin-react-query`, `plugin-zod`). See [Creating plugins](/docs/5.x/guides/creating-plugins) for naming conventions.

#### Related

- [Full Plugin API reference](../concepts/plugins)
- [Creating your first plugin](/docs/5.x/guides/creating-plugins)

### `defineGenerator` {#generator}

`defineGenerator` declares a named generator unit consumed by a plugin. Generators walk the [AST](/docs/5.x/concepts/ast) and emit files. The core calls each method for the matching node type during the generation loop.

Each generator method returns `TElement | Array<FileNode> | void`. Returning a renderer element (e.g., JSX from `@kubb/renderer-jsx`) requires declaring a `renderer` factory on the generator. Returning `Array<FileNode>` directly or calling `ctx.upsertFile()` manually and returning `void` works without a renderer.

```typescript twoslash
import { ast, defineGenerator } from '@kubb/core'

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
| -------------- | --------------------------------------- | ------------------------------------- | ---------------------------------------------------------------- |
| `schema()`     | `SchemaNode` (per data schema)          | `TElement \| Array<FileNode> \| void` | Generate types, validators, factories; called once per schema    |
| `operation()`  | `OperationNode` (per API operation)     | `TElement \| Array<FileNode> \| void` | Generate hooks, clients, handlers; called once per operation     |
| `operations()` | `Array<OperationNode>` (all operations) | `TElement \| Array<FileNode> \| void` | Generate index or barrel files; called once after all operations |

#### `GeneratorContext` properties (the `ctx` argument passed to each method)

| Property              | Type                                                | Purpose                                                              |
| --------------------- | --------------------------------------------------- | -------------------------------------------------------------------- |
| `ctx.config`          | `Config`                                            | Resolved Kubb configuration                                          |
| `ctx.root`            | `string`                                            | Absolute path to the output directory for the current plugin         |
| `ctx.options`         | `TResolvedOptions`                                  | Per-node resolved options (after exclude/include/override filtering) |
| `ctx.plugin`          | `Plugin`                                            | The owning plugin descriptor                                         |
| `ctx.resolver`        | `Resolver`                                          | Resolver for the current plugin                                      |
| `ctx.driver`          | `KubbDriver`                                      | Plugin driver for cross-plugin access                                |
| `ctx.hooks`           | `AsyncEventEmitter<KubbHooks>`                      | Event bus; subscribe to `KubbHooks` events                           |
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

- [AST concepts](/docs/5.x/concepts/ast) for node types and traversal
- [Creating plugins](/docs/5.x/guides/creating-plugins)

### `defineResolver` {#resolver}

`defineResolver` creates a resolver that controls file naming and path resolution for a plugin. The builder is a zero-argument function; use `this` to call sibling resolver methods.

The builder must return at least `{ name, pluginName }`. All other resolver methods (`default`, `resolveOptions`, `resolvePath`, `resolveFile`, `resolveBanner`, `resolveFooter`) receive built-in defaults and can be individually overridden.

```typescript twoslash
import { defineResolver } from '@kubb/core'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

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
| ---------------- | ---------------------------------------------------------------------- |
| `default`        | `camelCase` for `function`/`file`, `PascalCase` for `type`             |
| `resolveOptions` | Applies `exclude`, `include`, and `override` filters                   |
| `resolvePath`    | Resolves to `output.path`, with optional tag/path-based subdirectories |
| `resolveFile`    | Constructs a full `FileNode` using `default` + `resolvePath`           |
| `resolveBanner`  | Returns `output.banner` or the standard "Generated by Kubb" header     |
| `resolveFooter`  | Returns `output.footer` when set                                       |

#### Related

- [Plugin API: resolvers](../concepts/plugins#resolvers)
- [Creating plugins](/docs/5.x/guides/creating-plugins)

### `defineParser`

`defineParser` creates a parser that converts generated file ASTs to formatted source strings. Each parser declares which file extensions it handles via `extNames`.

The built-in parsers, [`@kubb/parser-ts`](/docs/5.x/concepts/parsers) and its TSX variant, handle TypeScript and TSX files. Implement `defineParser` to add support for other languages or custom output formats.

#### Related

- [Parser concepts](/docs/5.x/concepts/parsers)

### `createAdapter`

`createAdapter` is the factory for building adapters that translate non-OpenAPI specs into Kubb's universal [AST](/docs/5.x/concepts/ast). The built-in [`@kubb/adapter-oas`](/docs/5.x/concepts/adapters) handles OpenAPI and Swagger documents.

Write a custom adapter when your source is something Kubb does not parse yet, such as a GraphQL schema, a gRPC definition, an AsyncAPI spec, or a domain-specific language of your own.

> [!IMPORTANT]
> Adapters must parse their input format to Kubb's `InputNode` structure. See [Adapter API](/docs/5.x/concepts/adapters) for complete documentation.

#### Related

- [Adapter concepts](/docs/5.x/concepts/adapters)
- [Creating a custom adapter](/docs/5.x/concepts/adapters#creating-a-custom-adapter)

## Storage

Storage backends decide where generated files are written. Kubb ships a filesystem backend and an in-memory one. Use `createStorage` to build your own.

### `createStorage`

`createStorage` takes a builder function `(options: TOptions) => Storage` and returns a factory `(options?: TOptions) => Storage`. Call the returned factory to instantiate the storage (optionally with options).

```typescript twoslash
import { createStorage } from '@kubb/core'

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
> Use `memoryStorage` for tests and dry-runs. Use `fsStorage` for normal development and CI/CD.

#### `Storage` interface

| Method         | Params                       | Returns                   | Purpose                                                 |
| -------------- | ---------------------------- | ------------------------- | ------------------------------------------------------- |
| `hasItem()`    | `key: string`                | `Promise<boolean>`        | Check whether an item exists                            |
| `getItem()`    | `key: string`                | `Promise<string \| null>` | Retrieve an item's content                              |
| `setItem()`    | `key: string, value: string` | `Promise<void>`           | Write an item                                           |
| `removeItem()` | `key: string`                | `Promise<void>`           | Delete an item                                          |
| `getKeys()`    | `base?: string`              | `Promise<string[]>`       | List keys, optionally filtered by prefix                |
| `clear()`      | `base?: string`              | `Promise<void>`           | Delete all items, optionally scoped by prefix           |
| `dispose?()`   | (none)                       | `Promise<void>`           | Optional teardown hook called after the build completes |

### `fsStorage`

`fsStorage` is the built-in filesystem storage backend. Kubb uses it by default when no `storage` option is set in the config. It creates output directories automatically and respects `output.path`.

### `memoryStorage`

`memoryStorage` is the built-in in-memory storage backend. It writes nothing to disk, so it suits plugin tests, CI validation, and dry runs.

> [!NOTE]
> Both `fsStorage` and `memoryStorage` are exported from `@kubb/core` and can be passed directly to the `storage` field at the root of your config.

#### Related

- [Configuration reference](/docs/5.x/reference/configuration)

## Files & rendering

### The file manager (`driver.fileManager`)

The file manager is the high-level store for generated files within the build pipeline. The plugin driver creates and owns one instance, accessible via `driver.fileManager`. The class itself is internal and not exported from `@kubb/core`. Inside generators, prefer the context helpers `ctx.addFile()` and `ctx.upsertFile()` over accessing the file manager directly.

#### Key members

- `add()`: Add one or more files. When a file at the same path already exists, the new entry replaces it instead of merging.
- `upsert()`: Add or merge files, concatenating sources, imports, and exports when an entry at the same path already exists.
- `getByPath()`: Retrieve a file by its absolute path
- `deleteByPath()`: Remove a file by its absolute path
- `clear()`: Remove all files
- `hooks`: An `AsyncEventEmitter` that emits `upsert` with the resolved `FileNode` every time a file lands through `add` or `upsert`. The build loop listens on it to drain newly written files into the file processor without scanning the whole cache.
- `files`: Getter returning all stored files sorted by path length. The sort runs lazily on read, so high-volume `upsert` calls stay O(1).

#### Streaming model

The file manager does not expose a `stream()` method of its own. It streams through its `hooks`: every `addFile()` / `upsertFile()` call emits `upsert` with the resolved `FileNode`. The build driver subscribes to that event, so files flow directly into the file processor, get parsed one at a time, and land in `Storage` without buffering. The full cache is only iterated when a consumer reads `files`, for example inside a post-enforced plugin that listens on `kubb:plugins:end`.

#### Related

- [Plugin concepts: generator context](../concepts/plugins#generators)

### The file processor

The file processor is the lower-level pipeline that processes each `FileNode` before writing. It runs the registered parsers, falls back to joining raw source strings when no parser claims a file's extension, and writes the result to storage one file at a time. The build driver enqueues every file the file manager emits, so the whole flow is automatic. The class is internal and not exported from `@kubb/core`.

#### Streaming

Files stream through the processor as they arrive: the driver calls `enqueue(file)` for every `upsert` the file manager emits, and the processor parses and persists each one without buffering the full set. Progress surfaces through `start`, `update` (with `{ file, source, processed, total, percentage }`), and `end` events on the processor's `hooks` emitter, which the core re-emits on the main event bus for reporters.

### `jsxRenderer` (via `@kubb/renderer-jsx`)

For JSX-based rendering, import `jsxRenderer` directly from [`@kubb/renderer-jsx`](https://www.npmjs.com/package/@kubb/renderer-jsx). `@kubb/core` no longer re-exports a `createRenderer` factory.

`jsxRenderer` is a React-free recursive renderer. It walks the same JSX components into `FileNode`s without a React reconciliation pass, and its `stream()` returns a synchronous `Generator<FileNode>` that skips a microtask per file. Components run as plain functions, so hooks and suspense are not available.

```typescript twoslash
import { jsxRenderer } from '@kubb/renderer-jsx'

const renderer = jsxRenderer()
```

Set the renderer on a generator through its `renderer` field (`renderer: jsxRenderer`) to enable JSX-based output for that generator. Leave it unset, or pass `renderer: null`, to opt out of rendering.

#### Related

- [Creating plugins](/docs/5.x/guides/creating-plugins)

## Plugin driver

### `KubbDriver`

`KubbDriver` orchestrates the entire generation pipeline. It executes plugins in dependency order, emits lifecycle events, owns the [file manager](#the-file-manager-driver-filemanager), and routes path/name resolution through each plugin's resolver.

Access the driver via `ctx.driver` inside generator context methods, or from the build result via `result.driver`.

#### Key members

| Property               | Type                                    | Purpose                                               |
| ---------------------- | --------------------------------------- | ----------------------------------------------------- |
| `driver.plugins`       | `Map<string, Plugin>`                   | All installed plugins keyed by name                   |
| `driver.fileManager`   | `FileManager`                           | Central file store (`add`, `upsert`, `getByPath`)     |
| `driver.config`        | `Config`                                | Resolved Kubb configuration                           |
| `driver.hooks`         | `AsyncEventEmitter<KubbHooks>`          | Lifecycle event bus for listening and emitting        |
| `driver.getPlugin()`   | `(name: string) => Plugin \| undefined` | Look up a plugin by name (typed via `PluginRegistry`) |
| `driver.getResolver()` | `(name: string) => Resolver`            | Look up a plugin's resolver by name                   |

> [!TIP]
> Subscribe to lifecycle events via `driver.hooks.on(event, handler)` to observe the full build pipeline from outside of a plugin.

#### Related

- [Plugin concepts](../concepts/plugins)

## Utilities

### `AsyncEventEmitter`

`AsyncEventEmitter` is the typed event emitter that drives every `KubbHooks` event. Listeners can be async, the emitter awaits them, and it propagates errors and filters events along the way.

`@kubb/core` re-exports `AsyncEventEmitter` from `@internals/utils`. Use it directly when you want to listen to events on a `Kubb` instance before calling `.build()`.

#### Related

- [Plugin concepts: lifecycle events](../concepts/plugins#lifecycle-events)

### `Url`

`Url` is a helper class for working with OpenAPI path strings. Use `Url.canParse` to detect whether a given path string is a remote URL rather than a local file path.

```typescript twoslash
import { Url } from '@kubb/core'

Url.canParse('https://petstore.swagger.io/v2/swagger.json') // true
Url.canParse('./petStore.yaml') // false
```

### Narrowing `config.input`

`config.input` is either an `InputPath` (the `{ path: string }` form) or an `InputData` (the `{ data: ... }` form). Both types are exported from `@kubb/core`. Narrow between them with an [`in` check](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#the-in-operator-narrowing):

```typescript twoslash
import type { UserConfig } from '@kubb/core'

declare const input: NonNullable<UserConfig['input']>

if ('path' in input) {
  const filePath = input.path // narrowed to string
} else {
  const spec = input.data // narrowed to the spec object or string
}
```

### `logLevel`

`logLevel` is a constants object that enumerates the valid log level values. Pass one of these values to the `logLevel` field in your config or CLI flags.

| Level     | Usage              | Output                                  |
| --------- | ------------------ | --------------------------------------- |
| `silent`  | Production, CI     | No output                               |
| `info`    | Normal development | Status messages                         |
| `verbose` | Debugging builds   | Timing info, plugin details             |

> [!TIP]
> Use `verbose` when profiling plugin performance. To write a log file, pick the `file` reporter with [`--reporter file`](/docs/5.x/api/commands/generate#reporters).

## Public types

`@kubb/core` re-exports every public type from its `types.ts` barrel. Import them to type your own plugins, adapters, parsers, and build runners.

#### Configuration

| Type                      | Purpose                                                              |
| ------------------------- | -------------------------------------------------------------------- |
| `Config` / `UserConfig`   | Resolved and user-facing configuration shapes                        |
| `PossibleConfig`          | Every accepted form of a Kubb config (object, fn, array, sync/async) |
| `CLIOptions`              | Flags passed to the CLI (`--config`, `--watch`, `--logLevel`)        |
| `InputPath` / `InputData` | Two discriminants of `Config['input']`                               |
| `Output`                  | Output configuration (path, clean, barrel)                           |
| `Group`                   | Grouping strategy for generated files (`tag` or `path`)              |
| `BarrelType`              | `'all' \| 'named' \| 'propagate'` for barrel file generation         |

#### Plugins

| Type                     | Purpose                                            |
| ------------------------ | -------------------------------------------------- |
| `Plugin`                 | Final plugin object returned from `definePlugin`   |
| `PluginFactoryOptions`   | Generic parameter pack used to type a plugin       |
| `NormalizedPlugin`       | Internal representation after driver normalization |
| `KubbPluginSetupContext` | Context passed to `kubb:plugin:setup`              |
| `KubbBuildStartContext`  | Context passed to `kubb:build:start`               |
| `KubbBuildEndContext`    | Context passed to `kubb:build:end`                 |
| `KubbHooks`              | Map of every lifecycle event the driver emits      |
| `Kubb`                   | Kubb instance returned from `createKubb`           |
| `BuildOutput`            | Return shape of `kubb.build()`                     |

#### Lifecycle hook context types

| Type                              | Event                         | Shape                                                                      |
| --------------------------------- | ----------------------------- | -------------------------------------------------------------------------- |
| `KubbLifecycleStartContext`       | `kubb:lifecycle:start`        | `{ version: string }`                                                      |
| `KubbGenerationStartContext`      | `kubb:generation:start`       | `{ config: Config }`                                                       |
| `KubbGenerationEndContext`        | `kubb:generation:end`         | `{ config, storage, diagnostics?, status?, hrStart?, filesCreated? }`     |
| `KubbPluginStartContext`          | `kubb:plugin:start`           | `{ plugin: Plugin }`                                                       |
| `KubbPluginEndContext`            | `kubb:plugin:end`             | `{ plugin, duration, success, error? }`                                    |
| `KubbHookStartContext`            | `kubb:hook:start`             | `{ id?, command, args? }`                                                  |
| `KubbHookLineContext`             | `kubb:hook:line`              | `{ id, line }`                                                              |
| `KubbHookEndContext`              | `kubb:hook:end`               | `{ id?, command, args?, success, error, stdout?, stderr? }`                |
| `KubbFilesProcessingStartContext`  | `kubb:files:processing:start`  | `{ files: FileNode[] }`                                                    |
| `KubbFilesProcessingUpdateContext` | `kubb:files:processing:update` | `{ files: Array<KubbFileProcessingUpdate> }`                               |
| `KubbFileProcessingUpdate`         | (per-item, inside `files[]`)   | `{ processed, total, percentage, source?, file, config }`                  |
| `KubbFilesProcessingEndContext`    | `kubb:files:processing:end`    | `{ files: FileNode[] }`                                                    |
| `KubbInfoContext`                 | `kubb:info`                   | `{ message: string, info?: string }`                                       |
| `KubbErrorContext`                | `kubb:error`                  | `{ error: Error, meta?: Record<string, unknown> }`                         |
| `KubbDiagnosticContext`           | `kubb:diagnostic`             | `{ diagnostic: Diagnostic }`                                               |
| `KubbSuccessContext`              | `kubb:success`                | `{ message: string, info?: string }`                                       |
| `KubbWarnContext`                 | `kubb:warn`                   | `{ message: string, info?: string }`                                       |

#### Adapters & parsers

| Type                    | Purpose                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `Adapter`               | Final adapter object returned from `createAdapter`             |
| `AdapterFactoryOptions` | Generic parameter pack for an adapter                          |
| `AdapterSource`         | `{ type: 'path' }`, `{ type: 'data' }`, or `{ type: 'paths' }` |
| `Parser`                | Final parser object returned from `defineParser`               |

#### Resolvers

| Type                    | Purpose                                                                        |
| ----------------------- | ------------------------------------------------------------------------------ |
| `Resolver`              | Base constraint for resolvers returned from `defineResolver`                   |
| `ResolverContext`       | Shared context for path/file/name resolution                                   |
| `ResolverPathParams`    | Parameters for `Resolver.resolvePath`                                          |
| `ResolverFileParams`    | Parameters for `Resolver.resolveFile`                                          |
| `ResolveNameParams`     | Parameters for customizing names by kind (`file`, `function`, `type`, `const`) |
| `ResolveBannerContext`  | Context for banner/footer resolution (`output`, `config`, per-file `file`)     |
| `ResolveBannerFile`     | Per-file context (`path`, `baseName`, `isBarrel`, `isAggregation`)             |
| `BannerMeta`            | `InputMeta` extended with per-file fields, passed to a `banner`/`footer` function |
| `ResolveOptionsContext` | Context for `resolveOptions` (include/exclude/override)                        |

#### Generators & files

| Type               | Purpose                                                                 |
| ------------------ | ----------------------------------------------------------------------- |
| `Generator`        | Generator object returned from `defineGenerator`                        |
| `GeneratorContext` | Context passed to `schema()`, `operation()`, and `operations()` methods |
| `FileMetaBase`     | Minimal `meta` shape for file nodes (`{ pluginName? }`)                 |

#### Filters

| Type              | Purpose                                                            |
| ----------------- | ------------------------------------------------------------------ |
| `PatternFilter`   | `{ type; pattern }` shape shared by include, exclude, and override |
| `PatternOverride` | Filter plus partial option overrides                               |
| `Include`         | Filter narrowing generation to matching nodes                      |
| `Exclude`         | Filter preventing matching nodes from being generated              |
| `Override`        | Filter pairing a match with per-node option overrides              |

#### Storage and rendering

| Type                           | Purpose                                                       |
| ------------------------------ | ------------------------------------------------------------- |
| `Storage`                      | Shape returned by `createStorage`                             |
| `Renderer` / `RendererFactory` | Interfaces for custom renderers set on a generator's `renderer` field |

> [!NOTE]
> `defineLogger` and the logger types (`Logger`, `UserLogger`, `LoggerOptions`, `LoggerContext`) have moved to `@kubb/cli`. They are only needed when building a custom CLI logger.

## See also

- [Plugin concepts](/docs/5.x/concepts/plugins) for lifecycle hooks, generators, resolvers, and the plugin registry
- [AST concepts](/docs/5.x/concepts/ast) for `InputNode`, `OperationNode`, `SchemaNode`, and traversal helpers
- [Adapter concepts](/docs/5.x/concepts/adapters) on how `createAdapter` converts specs to the universal AST
- [Barrel files](/docs/5.x/concepts/middlewares) for barrel generation with `@kubb/plugin-barrel`
- [Parser concepts](/docs/5.x/concepts/parsers) on converting `FileNode` AST to source strings
- [Creating plugins](/docs/5.x/guides/creating-plugins) for a step-by-step guide to building a full plugin
- [Programmatic usage recipes](/docs/5.x/recipes#programmatic-build) with `createKubb` usage patterns
- [Configuration reference](/docs/5.x/reference/configuration) for all `defineConfig` options
- [`@kubb/ast` package](https://www.npmjs.com/package/@kubb/ast), the node constructors re-exported under `ast.factory`
- [TypeScript handbook: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) on narrowing `config.input` with the `in` operator
- [Astro integrations reference](https://docs.astro.build/en/reference/integrations-reference/), the inspiration for the hook-style API
