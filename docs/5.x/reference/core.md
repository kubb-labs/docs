---
layout: doc
title: Programmatic API
description: The programmatic surface of Kubb, driven from your own code with createKubb and defineConfig from the kubb package, plus storage, rendering, and the public types.
outline: [2, 3]
---

# Programmatic API

Kubb runs as a build engine you can drive from your own code. This page documents that programmatic surface: `createKubb` and `defineConfig` from the `kubb` package, storage, rendering, and the public types.

Writing a plugin, generator, resolver, parser, or adapter instead? That surface is `kubb/kit`:

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

## Configuration

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

## Build

### `createKubb`

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
| `.hooks`       | `AsyncEventEmitter<KubbHooks>` | Read-only. Shared event emitter. Attach listeners before calling `build()`.                        |
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

## Plugin authoring

Writing a plugin, generator, resolver, parser, or adapter happens through `kubb/kit`. `definePlugin`, `defineGenerator`, `defineResolver`, `defineParser`, and `createAdapter` live there, alongside `createRenderer`, `createStorage`, and `Diagnostics`.

See the [Kit API](/docs/5.x/reference/kit) for the full reference, and [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide.

## Storage

Storage backends decide where generated files are written. The two built-in backends, `fsStorage` and `memoryStorage`, and the `createStorage` builder for writing a custom one, live in [`kubb/kit`](/docs/5.x/reference/kit#storage). The `Storage` interface below is the shape every backend implements, kept here because a `Storage` instance is what the engine consumes at build time and returns from `driver.storage`.

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

## Rendering

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

## Narrowing `config.input`

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

## Public types

The programmatic types come from the `kubb` package, next to `createKubb` and `defineConfig`.

| Type                    | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `Config` / `UserConfig` | Resolved and user-facing configuration shapes |
| `CreateKubbOptions`     | Options accepted by `createKubb`            |
| `Kubb`                  | Instance returned from `createKubb`         |
| `BuildOutput`           | Return shape of `kubb.build()`              |

The plugin, generator, resolver, parser, adapter, renderer, output, and lifecycle hook context types are re-exported from [`kubb/kit`](/docs/5.x/reference/kit#public-types). The logger types (`Logger`, `UserLogger`, `LoggerOptions`, `LoggerContext`) and `defineLogger` live in `@kubb/cli`, needed only when building a custom CLI logger.

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
- [AST API reference](/docs/5.x/reference/ast) for the node constructors under `ast.factory` and the rest of the AST surface
- [TypeScript handbook: narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html) on narrowing `config.input` with the `in` operator
