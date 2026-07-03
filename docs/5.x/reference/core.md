---
layout: doc
title: Core API
description: Public API surface of @kubb/core, the build engine, including createKubb, KubbDriver, the file manager and file processor, reporters, and the engine-only public types.
outline: [2, 3]
---

# Core API

`@kubb/core` is the foundation of Kubb, the build engine. It exports the primitives for embedding Kubb in your own code and driving the generation pipeline: `createKubb`, the plugin driver, the file manager and processor, and the reporters.

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
> Most users do not install `@kubb/core` directly. The top-level [`kubb`](https://www.npmjs.com/package/kubb) package re-exports it with `adapterOas` and the default parsers pre-installed. Use `@kubb/core` directly when embedding Kubb programmatically. Writing a plugin instead? See the [Kit API](/docs/5.x/reference/kit).

```typescript twoslash [imports.ts]
import { defineConfig } from 'kubb/config'
import {
  createKubb,
  createReporter,
  cliReporter,
  jsonReporter,
  fileReporter,
  KubbDriver,
  AsyncEventEmitter,
  Url,
  logLevel,
} from '@kubb/core'
```

Writing a plugin, generator, resolver, parser, or adapter instead? That surface moved to `kubb/kit`:

```typescript twoslash [authoring-imports.ts]
import {
  ast,
  definePlugin,
  defineGenerator,
  defineResolver,
  defineParser,
  createAdapter,
  createStorage,
  Diagnostics,
} from 'kubb/kit'
```

See the [Kit API](/docs/5.x/reference/kit) for the full authoring reference.

> [!NOTE]
> `@kubb/core` no longer re-exports `@kubb/ast`. Import `ast` from [`kubb/kit`](/docs/5.x/reference/kit#ast) for the authoring-side namespace, or from `@kubb/ast` directly for the [AST API](/docs/5.x/reference/ast).

## Configuration

### `defineConfig`

`defineConfig` adds TypeScript type-checking to a `kubb.config.ts` file. It comes from the `kubb` package, not `@kubb/core`. It fills in defaults for any field you omit.

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
| `reporters`      | `[cliReporter, jsonReporter, fileReporter]` |
| `plugins`        | `pluginBarrel()` appended when not already present |
| `output.barrel`  | `{ type: 'named' }`, only when `pluginBarrel` is in `plugins` |
| `output.format`  | `false`                                  |
| `output.lint`    | `false`                                  |

> [!IMPORTANT]
> `defineConfig` is only exported from the `kubb` package. The `@kubb/core` package exports the raw `UserConfig` type but does not provide a `defineConfig` with defaults.

> [!TIP]
> The `output.barrel` default of `{ type: 'named' }` applies only when `pluginBarrel` is present in `plugins`. A plugins list without `pluginBarrel` leaves barrel generation untouched.

#### Related

- [Configuration reference](/docs/5.x/reference/configuration)
- [CLI options](/docs/5.x/reference/commands/)
- [`@kubb/plugin-barrel`](/plugins/plugin-barrel/)

## Build

### `createKubb`

`createKubb` drives Kubb from your own code. It accepts a `UserConfig` and returns a `Kubb` instance. Calling `.build()` runs the full generation pipeline and returns a `BuildOutput`.

Reach for `createKubb` when you orchestrate several builds, inspect diagnostics, or feed Kubb output into a larger toolchain. For a one-off build, chain the call: `await createKubb(config).build()`.

The `kubb` package and `@kubb/core` both export a `createKubb`. Import it from `kubb` to get the same defaults as `defineConfig` (`adapterOas`, the default parsers, the built-in reporters, and `pluginBarrel`), which is the entry point most scripts want since it drops the `@kubb/core` dependency. Import it from [`@kubb/core`](#createkubb-from-kubb-core) when you wire the adapter and parsers yourself.

`createKubb` takes a plain config object, the same shape `defineConfig` produces in `kubb.config.ts`. It is not a fluent builder. The config stays plain serializable data so Kubb can validate it against the shipped JSON schema.

```typescript twoslash [build.ts]
// @module: esnext
import { createKubb } from 'kubb'
import { Diagnostics } from 'kubb/kit'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

const kubb = createKubb({
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
| `.hooks`       | `AsyncEventEmitter<KubbHooks>` | Read-only. Shared event emitter. Attach listeners before calling `build()`.                        |
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

Each `Diagnostic` carries a `code`, a `severity` (`error`, `warning`, or `info`), a `message`, and the `plugin` that produced it. Failed-plugin diagnostics keep the original error on `cause`. A `performance` diagnostic (`kind: 'performance'`) carries a `duration` in milliseconds. Use the `Diagnostics.isProblem`, `Diagnostics.isPerformance`, and `Diagnostics.isUpdate` guards to narrow by kind.

> [!WARNING]
> After `safeBuild()`, check `Diagnostics.hasError(diagnostics)` before processing files. Plugins can fail without `safeBuild()` throwing. `build()` throws a `BuildError` in that case.

#### `createKubb` from `@kubb/core`

The `@kubb/core` export is the same function without the `defineConfig` defaults. It adds no `adapter`, `parsers`, `reporters`, or `pluginBarrel`, so you pass them yourself. Use it when you embed the engine without the `kubb` package or when you want full control over the adapter and parser set.

```typescript twoslash [build.ts]
import { createKubb } from '@kubb/core'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { pluginTs } from '@kubb/plugin-ts'

const kubb = createKubb({
  adapter: adapterOas(),
  parsers: [parserTs, parserTsx],
  input: { path: './petStore.yaml' },
  output: { path: './gen' },
  plugins: [pluginTs()],
})

await kubb.build()
```

#### Related

- [Programmatic usage recipe](/docs/5.x/guide/recipes#programmatic-build)
- [`KubbDriver`](#kubbdriver)

## Plugin authoring

Writing a plugin, generator, resolver, parser, or adapter no longer happens against `@kubb/core`. `definePlugin`, `defineGenerator`, `defineResolver`, `defineParser`, and `createAdapter` moved to `kubb/kit`, alongside `createRenderer`, `createStorage`, and `Diagnostics`.

See the [Kit API](/docs/5.x/reference/kit) for the full reference, and [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide.

## Storage

Storage backends decide where generated files are written. The two built-in backends, `fsStorage` and `memoryStorage`, and the `createStorage` builder for writing a custom one, moved to [`kubb/kit`](/docs/5.x/reference/kit#storage). The `Storage` interface below is the shape every backend implements, kept here because a `Storage` instance is what the engine consumes at build time and returns from `driver.storage`.

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

#### Related

- [Kit API: Storage](/docs/5.x/reference/kit#storage)
- [Configuration reference](/docs/5.x/reference/configuration)

## Files & rendering

### The file manager (`driver.fileManager`)

The file manager is the high-level store for generated files within the build pipeline. The plugin driver creates and owns one instance, reachable via `driver.fileManager`. The class is internal and not exported from `@kubb/core`. Inside generators, prefer the context helpers `ctx.addFile()` and `ctx.upsertFile()` over reaching the file manager directly.

#### Key members

| Member           | Purpose                                                                                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `add()`          | Add one or more files. An entry at the same path is replaced, not merged.                                                                |
| `upsert()`       | Add or merge files, concatenating sources, imports, and exports when an entry at the same path exists.                                   |
| `getByPath()`    | Retrieve a file by its absolute path.                                                                                                    |
| `deleteByPath()` | Remove a file by its absolute path.                                                                                                      |
| `clear()`        | Remove all files.                                                                                                                        |
| `hooks`          | An `AsyncEventEmitter` that emits `upsert` with the resolved `FileNode` every time a file lands through `add` or `upsert`.               |
| `files`          | Getter returning all stored files sorted by path length. The sort runs lazily on read, so high-volume `upsert` calls stay O(1).         |

#### Streaming model

The file manager does not expose its own `stream()` method. It streams through its `hooks`. Every `addFile()` or `upsertFile()` call emits `upsert` with the resolved `FileNode`. The build driver subscribes to that event, so files flow into the file processor, get parsed one at a time, and land in `Storage` without buffering. The full cache is only iterated when a consumer reads `files`, for example inside a post-enforced plugin that listens on `kubb:plugins:end`.

#### Related

- [Plugin concepts: generator context](/docs/5.x/guide/concepts/plugins#generators)

### The file processor

The file processor is the lower-level pipeline that processes each `FileNode` before writing. It runs the registered parsers, falls back to joining raw source strings when no parser claims a file's extension, and writes the result to storage one file at a time. The build driver enqueues every file the file manager emits, so the flow is automatic. The class is internal and not exported from `@kubb/core`.

#### Streaming

Files stream through the processor as they arrive. The driver calls `enqueue(file)` for every `upsert` the file manager emits, and the processor parses and persists each one without buffering the full set. Progress surfaces through `start`, `update` (with `{ file, source, processed, total, percentage }`), and `end` events on the processor's `hooks` emitter, which the core re-emits on the main event bus for reporters.

### `jsxRenderer` (via `kubb/jsx`)

For JSX-based rendering, import `jsxRenderer` from [`kubb/jsx`](/docs/5.x/reference/jsx), backed by the `@kubb/renderer-jsx` package.

`jsxRenderer` is a React-free recursive renderer. It walks the JSX components into `FileNode`s without a React reconciliation pass, and its `stream()` returns a synchronous `Generator<FileNode>` that skips a microtask per file. Components run as plain functions, so hooks and suspense are not available.

```typescript twoslash [renderer.ts]
import { jsxRenderer } from 'kubb/jsx'

const renderer = jsxRenderer()
```

Set the renderer on a generator through its `renderer` field (`renderer: jsxRenderer`) to enable JSX-based output for that generator. Leave it unset, or pass `renderer: null`, to opt out of rendering. See the [JSX API reference](/docs/5.x/reference/jsx) for `File`, `Function`, `Type`, `Const`, and the `jsx-runtime` / `jsx-dev-runtime` subpaths.

#### Related

- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

## Plugin driver

### `KubbDriver`

`KubbDriver` orchestrates the generation pipeline. It runs plugins in dependency order, emits lifecycle events, owns the [file manager](#the-file-manager-driver-filemanager), and routes path and name resolution through each plugin's resolver.

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

- [Plugin concepts](/docs/5.x/guide/concepts/plugins)

## Utilities

### `AsyncEventEmitter`

`AsyncEventEmitter` is the typed event emitter that drives every `KubbHooks` event. Listeners can be async. The emitter awaits them, propagates errors, and filters events as it goes.

`@kubb/core` re-exports `AsyncEventEmitter` from `@internals/utils`. Use it to listen to events on a `Kubb` instance before calling `.build()`.

#### Related

- [Plugin concepts: lifecycle events](/docs/5.x/guide/concepts/plugins#lifecycle-events)

### `Url`

`Url` is a helper class for turning OpenAPI path strings into other shapes. `Url.toPath` rewrites `{param}` placeholders into Express-style `:param` segments, and `Url.toObject` returns the path together with its extracted params.

```typescript twoslash [url.ts]
import { Url } from '@kubb/core'

Url.toPath('/pet/{petId}') // '/pet/:petId'
Url.toObject('/pet/{petId}') // { url: '/pet/:petId', params: { petId: 'petId' } }
```

### Narrowing `config.input`

`config.input` is either an `InputPath` (the `{ path: string }` form) or an `InputData` (the `{ data: string | unknown }` form). Both types are exported from `@kubb/core`. Narrow between them with an [`in` check](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#the-in-operator-narrowing):

```typescript twoslash [narrow.ts]
import type { UserConfig } from '@kubb/core'

declare const input: NonNullable<UserConfig['input']>

if ('path' in input) {
  const filePath = input.path // narrowed to string
} else {
  const spec = input.data // narrowed to the spec object or string
}
```

### `logLevel`

`logLevel` is a constants object that enumerates the valid log level values. Pass one of them to the `logLevel` CLI flag.

| Level     | Usage              | Output                                  |
| --------- | ------------------ | --------------------------------------- |
| `silent`  | Production, CI     | No output                               |
| `info`    | Normal development | Status messages                         |
| `verbose` | Debugging builds   | Timing info, plugin details             |

> [!TIP]
> Use `verbose` when profiling plugin performance. To write a log file, pick the `file` reporter with [`--reporter file`](/docs/5.x/reference/commands/generate#reporters).

## Public types

`@kubb/core` re-exports its public types from the `types.ts` barrel. Import them to type your own build runners and event listeners.

#### Configuration

| Type                      | Purpose                                                              |
| ------------------------- | -------------------------------------------------------------------- |
| `Config` / `UserConfig`   | Resolved and user-facing configuration shapes                        |
| `PossibleConfig`          | Every accepted form of a Kubb config (object, fn, array, sync/async) |
| `CLIOptions`              | Flags passed to the CLI (`--config`, `--watch`, `--logLevel`)        |
| `InputPath` / `InputData` | Two discriminants of `Config['input']`                               |

> [!NOTE]
> `Output`, `OutputMode`, `OutputOptions`, and `Group` (the per-plugin output shape nested under `Config['output']`) moved to [`kubb/kit`](/docs/5.x/reference/kit#public-types).

#### Build

| Type                     | Purpose                                            |
| ------------------------ | -------------------------------------------------- |
| `NormalizedPlugin`       | Internal representation after driver normalization |
| `KubbBuildStartContext`  | Context passed to `kubb:build:start`               |
| `KubbBuildEndContext`    | Context passed to `kubb:build:end`                 |
| `Kubb`                   | Kubb instance returned from `createKubb`           |
| `BuildOutput`            | Return shape of `kubb.build()`                     |

> [!NOTE]
> `Plugin`, `PluginFactoryOptions`, `KubbPluginSetupContext`, and `KubbHooks` moved to [`kubb/kit`](/docs/5.x/reference/kit#public-types).

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
| `KubbDiagnosticContext`           | `kubb:diagnostic`             | `{ diagnostic: ProblemDiagnostic \| UpdateDiagnostic }`                    |
| `KubbSuccessContext`              | `kubb:success`                | `{ message: string, info?: string }`                                       |
| `KubbWarnContext`                 | `kubb:warn`                   | `{ message: string, info?: string }`                                       |

> [!NOTE]
> `KubbPluginStartContext` and `KubbPluginEndContext` stay here because the driver emits them for every plugin during a build. `kubb/kit` re-exports both for typing a plugin's own hook listeners.

#### Storage

| Type      | Purpose                            |
| --------- | ------------------------------------|
| `Storage` | Shape returned by `createStorage`  |

> [!NOTE]
> `Adapter`, `AdapterFactoryOptions`, `AdapterSource`, `Parser`, `Resolver`, `ResolverContext`, `ResolverPathParams`, `ResolverFileParams`, `ResolveBannerContext`, `ResolveBannerFile`, `BannerMeta`, `ResolveOptionsContext`, `Generator`, `GeneratorContext`, `Include`, `Exclude`, `Override`, `Renderer`, and `RendererFactory` moved to [`kubb/kit`](/docs/5.x/reference/kit#public-types).

> [!NOTE]
> `defineLogger` and the logger types (`Logger`, `UserLogger`, `LoggerOptions`, `LoggerContext`) have moved to `@kubb/cli`. They are only needed when building a custom CLI logger.

## See also

- [Kit API](/docs/5.x/reference/kit) for the plugin, generator, resolver, parser, and adapter authoring toolkit
- [Plugin concepts](/docs/5.x/guide/concepts/plugins) for lifecycle hooks, generators, resolvers, and the plugin registry
- [AST concepts](/docs/5.x/guide/concepts/ast) for `InputNode`, `OperationNode`, `SchemaNode`, and traversal helpers
- [Adapter concepts](/docs/5.x/guide/concepts/adapters) on how `createAdapter` converts specs to the universal AST
- [Barrel files](/docs/5.x/guide/concepts/barrel-files) for barrel generation with `@kubb/plugin-barrel`
- [Parser concepts](/docs/5.x/guide/concepts/parsers) on converting `FileNode` AST to source strings
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide to building a full plugin
- [Programmatic usage recipes](/docs/5.x/guide/recipes#programmatic-build) with `createKubb` usage patterns
- [Configuration reference](/docs/5.x/reference/configuration) for all `defineConfig` options
- [`@kubb/ast` package](https://www.npmjs.com/package/@kubb/ast), the node constructors re-exported under `ast.factory`
- [TypeScript handbook: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) on narrowing `config.input` with the `in` operator
- [Astro integrations reference](https://docs.astro.build/en/reference/integrations-reference/), the inspiration for the hook-style API
