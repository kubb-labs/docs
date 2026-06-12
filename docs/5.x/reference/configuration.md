---
layout: doc
title: Configuration
description: Reference for kubb.config.ts with every option, default and example for the Kubb v5 UserConfig.
outline: [2, 3]
---

# Configuration

`kubb.config.ts` is the single source of truth for a Kubb run. The file default-exports an object (or a function returning one, or an array of configs) wrapped in `defineConfig`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  name: 'petStore',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
})
```

> [!TIP]
> `defineConfig` from the `kubb` package automatically includes the OpenAPI adapter and TypeScript parsers, so you don't need to import them separately.

## Config formats

`defineConfig` accepts an object, a function, or an array:

### Single config object

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  name: 'petStore',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
})
```

### Config function

Pass a function to access context like `watch` or `logLevel`. Useful for conditional config:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig(({ watch, logLevel }) => ({
  name: 'petStore',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: !watch },
}))
```

Context parameters:

- `input` (`string`): positional input passed to `kubb generate <input>`. Overrides `config.input.path` when set.
- `watch` (`boolean`): whether running in watch mode.
- `logLevel` (`'silent' | 'info' | 'verbose'`): current log level.
- `config` (`string`): path to the config file being used.

### Multiple configurations (array)

Pass an array to generate from multiple specs in one command:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig([
  {
    name: 'petStore',
    input: { path: './petStore.yaml' },
    output: { path: './src/gen/petStore' },
    plugins: [pluginTs()],
  },
  {
    name: 'stripe',
    input: { path: './stripe.yaml' },
    output: { path: './src/gen/stripe' },
    plugins: [pluginTs()],
  },
])
```

### Multiple configurations with function

Combine array and function formats:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig(({ watch }) => [
  {
    name: 'petStore',
    input: { path: './petStore.yaml' },
    output: { path: './src/gen/petStore', clean: !watch },
    plugins: [pluginTs()],
  },
  {
    name: 'stripe',
    input: { path: './stripe.yaml' },
    output: { path: './src/gen/stripe', clean: !watch },
    plugins: [pluginTs()],
  },
])
```

## Top-level options

### `name`

Friendly name for this config. It shows in the CLI output as `Generating <name>...`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### `input`

Where Kubb reads your spec from. Use **either** `path` **or** `data`, not both. Required when an adapter is configured; omit when running in plugin-only mode (no `adapter`).

#### `input.path`

Local path or URL to your OpenAPI document.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

#### `input.data`

OpenAPI specification provided in-memory (string or parsed object). Useful for programmatic builds.

|           |                     |
| --------: | :------------------ |
|     Type: | `string \| unknown` |
| Required: | `true`              |

> [!NOTE]
> When `input` is provided, exactly one of `input.path` or `input.data` must be set. `input` itself is optional when running without an adapter (plugin-only mode).

### `output`

Controls where and how files are written.

#### `output.path`

Directory for generated files (absolute or relative to `root`).

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

#### `output.mode`

How a plugin consolidates its generated code into files. Set this on a plugin's `output`, not on the root `output`.

|           |                          |
| --------: | :----------------------- |
|     Type: | `'directory' \| 'file'`  |
| Required: | `false`                  |
|  Default: | `'directory'`            |

`'directory'` writes one file per operation or schema under `output.path`. `'file'` writes everything into a single file — `output.path` must include the file extension (e.g. `'types.ts'`). Pair `'directory'` with the `group` option to organize that output into per-tag or per-path subdirectories.

```typescript
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({ output: { path: 'types.ts', mode: 'file' } }),
    pluginClient({ output: { path: 'clients', mode: 'directory' }, group: { type: 'tag' } }),
  ],
})
```

The config above writes every type into `src/gen/types.ts` and one client file per operation, organized into a folder per tag (`src/gen/clients/pet/`, `src/gen/clients/store/`).

> [!TIP]
> `mode: 'file'` forbids the `group` option, since a single file has nothing to group. Pairing them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### `output.clean`

Wipe `output.path` before regenerating.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!WARNING]
> Only use `clean: true` with a dedicated output folder since the entire directory will be removed.

#### `output.format`

Formatter to run on every generated file.

|           |                                                       |
| --------: | :---------------------------------------------------- |
|     Type: | `'auto' \| 'prettier' \| 'biome' \| 'oxfmt' \| false` |
| Required: | `false`                                               |
|  Default: | `false`                                               |

Use `'auto'` to detect the first available formatter ([oxfmt](https://oxc.rs) → [Biome](https://biomejs.dev) → [Prettier](https://prettier.io)), force one with `'prettier'`, `'biome'`, or `'oxfmt'`, or set `false` to skip formatting. Kubb respects your local `.prettierrc` or `biome.json`.

#### `output.lint`

Linter to run after generation.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `'auto' \| 'eslint' \| 'biome' \| 'oxlint' \| false` |
| Required: | `false`                                              |
|  Default: | `false`                                              |

Use `'auto'` to detect the first available linter ([oxlint](https://oxc.rs) → [Biome](https://biomejs.dev) → [ESLint](https://eslint.org)), force one with `'oxlint'`, `'biome'`, or `'eslint'`, or set `false` to skip linting.

#### `output.extension`

Override file extensions emitted by `import` / `export` statements.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Record<KubbFile.Extname, KubbFile.Extname>` |
| Required: | `false`                                      |
|  Default: | `{ '.ts': '.ts' }`                           |

> [!TIP]
> Use `{ '.ts': '.js' }` for ESM compatibility when the consumer transpiles to JavaScript.

#### `output.barrel`

Behavior of the root `index.ts` barrel file at `output.path`.

Provided by [`@kubb/plugin-barrel`](/plugins/plugin-barrel).

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

- `{ type: 'all' }`: generates `export * from '...'` for every file.
- `{ type: 'named' }`: generates `export { … } from '...'` using each file's named exports.
- `false`: disables the root barrel.

::: code-group

```typescript [named]
// src/gen/index.ts
export { CreatePetRequest, Pet } from './pet'
export { User } from './user'
export type { GetPetQuery } from './operations/getPet'
```

```typescript [all]
// src/gen/index.ts
export * from './pet'
export * from './user'
export * from './operations/getPet'
```

```typescript [false]
// no index.ts generated
```

:::

Individual plugins keep their own `output.barrel` for their sub-folder and can override the root setting. Setting `barrel: false` on a plugin both disables that plugin's barrel and excludes its files from the root barrel. Use `{ nested: true }` at the plugin level to propagate exports up to the root barrel instead of generating a local barrel.

> [!NOTE]
> The `{ type: 'named' }` default is only applied when `pluginBarrel` is present in `config.plugins`. Configs that omit `pluginBarrel` entirely leave barrel generation untouched.

#### `output.defaultBanner`

Auto-generated banner injected at the top of each file.

|           |                               |
| --------: | :---------------------------- |
|     Type: | `'simple' \| 'full' \| false` |
| Required: | `false`                       |
|  Default: | `'simple'`                    |

- `'simple'`: adds a short "Generated by Kubb" notice.
- `'full'`: adds the notice plus `Source`, `Title`, `Description`, and `OpenAPI spec version` from the spec.
- `false`: no banner.

::: code-group

```typescript [simple]
/**
 * Generated by Kubb (https://kubb.dev/).
 * Do not edit manually.
 */
```

```typescript [full]
/**
 * Generated by Kubb (https://kubb.dev/).
 * Do not edit manually.
 * Source: petStore.yaml
 * Title: Pet Store
 * Description: A sample API that uses a petstore as an example.
 * OpenAPI spec version: 1.0.0
 */
```

```typescript [false]
// no banner
```

:::

#### `output.banner`

Text prepended to every file a plugin generates. Configure it on an individual plugin (the root `output` only exposes [`output.defaultBanner`](#output-defaultbanner)) to add license headers, lint-disable comments, or framework directives such as `'use server'`.

|           |                                        |
| --------: | :------------------------------------- |
|     Type: | `string \| ((meta: BannerMeta) => string)` |
| Required: | `false`                                |

- A **string** is applied to every file the plugin generates, including barrel (`index.ts`) and group aggregation (`[dir]/[dir].ts`) re-export files.
- A **function** runs once per file and receives a `BannerMeta`, so you can vary the banner per file or return an empty string to skip it.

`BannerMeta` extends the document `InputMeta` (`title`, `description`, `version`, …) with per-file context:

|              |           |                                                          |
| -----------: | :-------- | :------------------------------------------------------- |
|   `filePath` | `string`  | Full output path of the file being generated.            |
|   `baseName` | `string`  | File name only, for example `stocks.ts`.                 |
|   `isBarrel` | `boolean` | `true` for `index.ts` re-export barrels.                 |
| `isAggregation` | `boolean` | `true` for group `[dir]/[dir].ts` aggregation files. |

The function form is useful for Next.js Server Actions: add `'use server'` to source files, but skip it on re-export files, which only re-export symbols or return function references and break under the directive.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      output: {
        path: './clients',
        banner: (meta) => (meta.isBarrel || meta.isAggregation ? '' : "'use server'"),
      },
      group: { type: 'tag' },
    }),
  ],
})
```

> [!NOTE]
> Barrel `index.ts` files stay banner-free by default. They only receive a banner when the plugin sets `output.banner`, at which point the function runs with `isBarrel: true`.

#### `output.footer`

Text appended to the end of every file a plugin generates. Mirror of [`output.banner`](#output-banner), accepting the same `string \| ((meta: BannerMeta) => string)`.

|           |                                        |
| --------: | :------------------------------------- |
|     Type: | `string \| ((meta: BannerMeta) => string)` |
| Required: | `false`                                |

#### `output.override`

Controls whether Kubb overwrites files that already exist on disk at the output path.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

When `false` (default), Kubb skips any file that already exists, preserving manual edits or files created by other tools. Set to `true` to always write generated files regardless of what is already on disk.

Setting this at the root level makes all plugins inherit the same behaviour. Each plugin also has its own `output.override` that takes precedence over the root value for that plugin only.

#### `output.write`

Set to `false` to run a dry-run where files are kept in memory only.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `true`    |

> [!WARNING]
> Deprecated in favour of root-level `storage`, but still supported.

### `plugins`

Array of Kubb plugins. Plugins may declare dependencies, and Kubb throws an error at startup if any are missing.

|           |                         |
| --------: | :---------------------- |
|     Type: | `Array<KubbUserPlugin>` |
| Required: | `false`                 |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'models' },
    }),
  ],
})
```

### `adapter`

Adapter that converts your input into the universal AST. When using `defineConfig` from the `kubb` package, this defaults to `adapterOas()` from [`@kubb/adapter-oas`](/adapters/adapter-oas).

Omit `adapter` (and `input`) to run Kubb in **plugin-only mode**: the spec-parsing step is skipped entirely, but `kubb:plugin:setup` hooks still fire and `injectFile` can be used to inject arbitrary files into the build. This is useful for code-generation scripts that don't consume an OpenAPI spec.

See the [Adapter concept](/docs/5.x/concepts/adapters) for a deeper explanation.

|           |                                       |
| --------: | :------------------------------------ |
|     Type: | `Adapter`                             |
| Required: | `false`                               |
|  Default: | `adapterOas()` (included with `kubb`) |

To customize the adapter, explicitly pass options:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: true }),
})
```

Plugin-only mode (no spec, no adapter):

```typescript twoslash [kubb.config.ts (plugin-only)]
import { createKubb, definePlugin, ast } from '@kubb/core'

const kubb = createKubb({
  root: process.cwd(),
  output: { path: './src/gen', format: false },
  plugins: [
    definePlugin(() => ({
      name: 'my-file-injector',
      hooks: {
        'kubb:plugin:setup'({ injectFile }) {
          injectFile({
            baseName: 'hello.ts',
            path: './src/gen/hello.ts',
            sources: [ast.createSource({ nodes: [ast.createText('export const hello = "world"')] })],
          })
        },
      },
    }))(),
  ],
})
await kubb.build()
```

> [!NOTE]
> `adapterOas()` validates OpenAPI specs by default (`validate: true`). Pass `adapterOas({ validate: false })` to skip validation for faster startup or to work with non-conforming specs.

See the [`@kubb/adapter-oas`](/adapters/adapter-oas) reference for every adapter option (`validate`, `contentType`, `serverIndex`, `serverVariables`, `discriminator`, `dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, …).

### `parsers`

Array of parsers that turn the in-memory file representation into source code. Each parser declares which file extensions it handles via `extNames`.

See the [Parser concept](/docs/5.x/concepts/parsers) and [`@kubb/parser-ts`](/parsers/parser-ts) for details on the built-in parsers.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Array<Parser>`                                |
| Required: | `false`                                        |
|  Default: | `[parserTs, parserTsx, parserMd]` (included with `kubb`) |

To customize parsers, explicitly import them:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx],
})
```

Use `defineParser` from `@kubb/core` to write your own.

### `storage`

Storage driver for persisting generated files. Defaults to `fsStorage()` (filesystem).

See the [Storage concept](/docs/5.x/concepts/storage) for built-in drivers and how to write a custom backend.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Storage`                            |
| Required: | `false`                              |
|  Default: | `fsStorage()` (included with `kubb`) |

Use `createStorage` from `@kubb/core` to plug in S3, Redis, an in-memory map or any other backend.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { memoryStorage } from '@kubb/core'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: memoryStorage(),
})
```

### `cache`

Incremental build cache. Kubb fingerprints the inputs (spec content, config, plugin options, package versions) and, when nothing changed since the last run, restores the previously generated output instead of regenerating it.

`defineConfig` enables `fsCache()` by default, which stores snapshots on local disk under `node_modules/.cache/kubb`. Pass another `Cache` backend to change where snapshots live, or `false` to turn caching off.

|           |                                    |
| --------: | :--------------------------------- |
|     Type: | `Cache \| false`                   |
| Required: | `false`                            |
|  Default: | `fsCache()` (included with `kubb`) |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { fsCache } from '@kubb/core'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  cache: fsCache({ dir: '.kubb-cache' }),
})
```

Turn it off when you want every run to regenerate from scratch, for example while debugging a custom plugin:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  cache: false,
})
```

### `root`

Project root, absolute or relative to the config file location.

|           |                 |
| --------: | :-------------- |
|     Type: | `string`        |
| Required: | `false`         |
|  Default: | `process.cwd()` |

### `hooks`

Lifecycle hooks executed after generation finishes.

#### `hooks.done`

Shell command(s) to run when the build finishes. Useful for triggering a formatter or test run.

|           |                           |
| --------: | :------------------------ |
|     Type: | `string \| Array<string>` |
| Required: | `false`                   |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  hooks: {
    done: ['biome check --write ./src/gen'],
  },
})
```

### `reporters`

The reporters available to the run, registered as instances. `defineConfig` registers the built-in `cli`, `json`, and `file` reporters by default, and the CLI [`--reporter`](/docs/5.x/api/commands/generate#reporters) flag selects which ones to trigger by name (`cli` when the flag is omitted). `cli` writes the end-of-run summary to the terminal, `json` writes a machine-readable report to stdout for CI, and `file` writes the run's diagnostics to `.kubb/kubb-<timestamp>.log`.

|           |                                             |
| --------: | :------------------------------------------ |
|     Type: | `Array<Reporter>`                           |
|  Default: | `[cliReporter, jsonReporter, fileReporter]` |
| Required: | `false`                                     |

Register extra reporters (or your own, built with [`createReporter`](/docs/5.x/api/core)) by adding them to the array, then select them on the CLI with `--reporter <name>`.

```typescript [kubb.config.ts]
import { cliReporter, jsonReporter } from '@kubb/core'
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  reporters: [cliReporter, jsonReporter],
})
```
