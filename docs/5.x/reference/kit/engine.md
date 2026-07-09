---
layout: doc
title: Engine and configuration
description: The engine that runs your plugins comes from the kubb package and its kubb/config subpath. Covers defineConfig, createKubb, the Kubb instance, BuildOutput, and narrowing config.input.
outline: [2, 3]
---

# Engine and configuration

The engine that runs your plugins comes from the `kubb` package and its `kubb/config` subpath, backed by the internal `@kubb/core` library. This page documents that surface: `defineConfig`, `createKubb`, and the build types they share.

## `defineConfig`

`defineConfig` adds TypeScript type-checking to a `kubb.config.ts` file. It comes from the `kubb` package and fills in defaults for any field you omit.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
})
```

It accepts a config object, an array of configs, a Promise, or a function. The function form receives the [CLI options](/docs/5.x/reference/commands/) at runtime, so you can toggle behavior on flags like `--watch`:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig(({ watch }) => ({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: !watch },
}))
```

### Defaults applied for omitted fields

| Field            | Default                                  |
| ---------------- | ---------------------------------------- |
| `root`           | `process.cwd()`                          |
| `adapter`        | [`adapterOas()`](/docs/5.x/guide/concepts/adapters) |
| `parsers`        | `[parserTs(), parserTsx(), parserMd()]`  |
| `reporters`      | `[cli, json, file]`                      |
| `plugins`        | `pluginBarrel()` appended when not already present |
| `output.barrel`  | `{ type: 'named' }`, only when `pluginBarrel` is in `plugins` |
| `output.format`  | `false`                                  |
| `output.lint`    | `false`                                  |

> [!IMPORTANT]
> `defineConfig` comes from the `kubb` package. Import it from `kubb` or the `kubb/config` subpath.

> [!TIP]
> The `output.barrel` default of `{ type: 'named' }` applies only when `pluginBarrel` is present in `plugins`. A plugins list without `pluginBarrel` leaves barrel generation untouched.

### Related

- [Configuration reference](/docs/5.x/reference/configuration)
- [CLI options](/docs/5.x/reference/commands/)
- [`@kubb/plugin-barrel`](/plugins/plugin-barrel/)

## `createKubb` {#createkubb}

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
  parsers: [parserTs(), parserTsx()],
  input: './petStore.yaml',
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

### `Kubb` instance members (all getters are read-only)

| Member         | Type                           | Description                                                                                        |
| -------------- | ------------------------------ | -------------------------------------------------------------------------------------------------- |
| `.setup()`     | `() => Promise<void>`          | Initializes the driver and storage. `build()` calls this automatically.                            |
| `.build()`     | `() => Promise<BuildOutput>`   | Runs the full pipeline and throws a `BuildError` when any diagnostic is an error.                  |
| `.safeBuild()` | `() => Promise<BuildOutput>`   | The canonical call. Runs the full pipeline and collects problems in `BuildOutput.diagnostics` instead of throwing. |
| `.hooks`       | `Hookable<KubbHooks>`          | Read-only. Shared hook emitter. Call `.hook(name, handler)` before `build()` to attach a listener. |
| `.config`      | `Config`                       | Read-only. Resolved config, available right after `createKubb` since it resolves in the constructor. |
| `.storage`     | `Storage`                      | Read-only getter. Final source code keyed by absolute path. Available after `setup()`, throws before. |
| `.driver`      | read-only getter               | Advanced plugin driver handle, available after `setup()`. Throws if accessed before `setup()`.     |

### `BuildOutput` fields

| Field         | Type                | Description                                                                |
| ------------- | ------------------- | -------------------------------------------------------------------------- |
| `files`       | `Array<FileNode>`   | Generated files with paths, names, and content                                  |
| `storage`     | `Storage`           | Generated source code accessible via the `Storage` API                          |
| `driver`      | driver handle       | Advanced plugin driver handle for introspection                                 |
| `diagnostics` | `Array<Diagnostic>` | Problems collected during the build, plus a `performance` diagnostic per plugin |

Each `Diagnostic` carries a `code`, a `severity` (`error`, `warning`, or `info`), a `message`, and the `plugin` that produced it. Failed-plugin diagnostics keep the original error on `cause`. A `performance` diagnostic (`kind: 'performance'`) carries a `duration` in milliseconds. Use the `Diagnostics.isProblem`, `Diagnostics.isPerformance`, and `Diagnostics.isUpdate` guards to narrow by kind.

> [!WARNING]
> After `safeBuild()`, check `Diagnostics.hasError(diagnostics)` before processing files. Plugins can fail without `safeBuild()` throwing. `build()` throws a `BuildError` in that case.

### Related

- [Programmatic usage recipe](/docs/5.x/guide/recipes#programmatic-build)

## Narrowing `config.input`

`config.input` is either a string (a path, a URL, or inline content) or a parsed object. Narrow between them with a [`typeof` check](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#typeof-type-guards):

```typescript twoslash [narrow.ts]
import type { UserConfig } from 'kubb'

declare const input: NonNullable<UserConfig['input']>

if (typeof input === 'string') {
  const pathUrlOrContent = input // a path, a URL, or inline spec content
} else {
  const spec = input // the parsed spec object
}
```
