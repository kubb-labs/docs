---
layout: doc
title: Configuration
description: Reference for kubb.config.ts with every option, default and example for the Kubb v5 UserConfig.
outline: [2, 3]
---

# Configuration

`kubb.config.ts` drives a Kubb run. The file default-exports a `defineConfig` call. Pass it an object, a function that returns one, or an array of configs.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  name: 'petStore',
  input: './petStore.yaml',
  output: { path: './src/gen' },
})
```

> [!TIP]
> `defineConfig` from the `kubb` package adds the OpenAPI adapter and the TypeScript parsers for you, so you don't import them yourself.

## Config formats

`defineConfig` accepts an object, a function, or an array.

### Single config object

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  name: 'petStore',
  input: './petStore.yaml',
  output: { path: './src/gen' },
})
```

### Config function

Pass a function when the config depends on the run context, such as `watch` or `logLevel`:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig(({ watch, logLevel }) => ({
  name: 'petStore',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: !watch },
}))
```

The context carries five parameters:

|             | Type | Description |
| ----------: | :--- | :---------- |
|     `input` | `string` | Positional input from `kubb generate <input>`. Overrides `config.input` when set. |
|     `watch` | `boolean` | `true` in watch mode. |
|  `logLevel` | `'silent' \| 'info' \| 'verbose'` | Current log level. |
|    `config` | `string` | Path to the config file in use. |
| `reporters` | `Array<ReporterName>` | Reporters selected via `--reporter`, overriding `config.reporters`. |

### Multiple configurations (array)

Pass an array to generate from several specs in one command:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig([
  {
    name: 'petStore',
    input: './petStore.yaml',
    output: { path: './src/gen/petStore' },
    plugins: [pluginTs()],
  },
  {
    name: 'stripe',
    input: './stripe.yaml',
    output: { path: './src/gen/stripe' },
    plugins: [pluginTs()],
  },
])
```

### Multiple configurations with a function

Combine the array and function forms:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig(({ watch }) => [
  {
    name: 'petStore',
    input: './petStore.yaml',
    output: { path: './src/gen/petStore', clean: !watch },
    plugins: [pluginTs()],
  },
  {
    name: 'stripe',
    input: './stripe.yaml',
    output: { path: './src/gen/stripe', clean: !watch },
    plugins: [pluginTs()],
  },
])
```

## Top-level options

### `name`

A name for this config. The CLI prints it as `Generating <name>...`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### `input`

Where Kubb reads your spec. Pass a local file path, a URL, inline OpenAPI content as a JSON or YAML string, or an already-parsed object. Kubb detects which one you gave it. Required when an adapter is configured. Omit it in plugin-only mode, when there is no `adapter`.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `string \| Record<string, unknown>`  |
| Required: | `false`                              |

A string that starts with `{` or `[`, spans multiple lines, or opens with a YAML `openapi:` or `swagger:` key is read as inline content. Anything else is a file path or a URL, and a relative path resolves against the config file.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  // a path, a URL, an inline JSON/YAML string, or a parsed object
  input: './petStore.yaml',
  output: { path: './src/gen' },
})
```

### `output`

Controls where and how files are written.

#### `output.path`

Directory for generated files, absolute or relative to `root`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

#### `output.mode`

How a plugin consolidates its code into files. Set it on a plugin's `output`, not on the root `output`.

|           |                          |
| --------: | :----------------------- |
|     Type: | `'file' \| 'directory'`  |
| Required: | `false`                  |
|  Default: | `'file'`                 |

`'file'` writes everything into a single file, so `output.path` must include the extension (`'types.ts'`). `'directory'` writes one file per operation or schema under `output.path`. Pair `'directory'` with `group` to split the output into per-tag or per-path subdirectories.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs({ output: { path: 'types.ts' } }),
    pluginAxios({ output: { path: 'clients', mode: 'directory' }, group: { type: 'tag' } }),
  ],
})
```

This writes every type into `src/gen/types.ts` and one client file per operation, grouped by tag (`src/gen/clients/pet/`, `src/gen/clients/store/`).

> [!TIP]
> `group` requires `mode: 'directory'`, since a single file has nothing to group. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### `output.clean`

Wipe `output.path` before regenerating.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!WARNING]
> Only use `clean: true` with a dedicated output folder. Kubb removes the entire directory.

#### `output.format`

Formatter to run on every generated file.

|           |                                                       |
| --------: | :---------------------------------------------------- |
|     Type: | `'auto' \| 'prettier' \| 'biome' \| 'oxfmt' \| false` |
| Required: | `false`                                               |
|  Default: | `false`                                               |

`'auto'` detects the first formatter it finds ([oxfmt](https://oxc.rs) then [Biome](https://biomejs.dev) then [Prettier](https://prettier.io)). A named tool forces that one. `false` skips formatting. Kubb reads your local `.prettierrc` or `biome.json`.

#### `output.lint`

Linter to run after generation.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `'auto' \| 'eslint' \| 'biome' \| 'oxlint' \| false` |
| Required: | `false`                                              |
|  Default: | `false`                                              |

`'auto'` detects the first linter it finds ([oxlint](https://oxc.rs) then [Biome](https://biomejs.dev) then [ESLint](https://eslint.org)). A named tool forces that one. `false` skips linting.

#### `output.postGenerate`

Shell commands to run after the generated files are formatted and linted, such as a type check or a custom script. Commands run from the `root` directory, in sequence. Pass a command string, or `{ name, command }` to label a step in the CLI output.

|           |                                                       |
| --------: | :---------------------------------------------------- |
|     Type: | `Array<string \| { name?: string; command: string }>` |
| Required: | `false`                                               |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
    postGenerate: [{ name: 'types', command: 'npm run typecheck' }, 'biome check --write ./src/gen'],
  },
})
```

#### `output.barrel`

Behavior of the root `index.ts` barrel file at `output.path`.

Provided by [`@kubb/plugin-barrel`](/plugins/plugin-barrel/).

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named' } \| false`                   |
| Required: | `false`                                                 |
|  Default: | `false`                                                 |

`{ type: 'all' }` writes `export * from '...'` for every file. `{ type: 'named' }` writes `export { … } from '...'` using each file's named exports. `false` disables the root barrel.

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

Each plugin keeps its own `output.barrel` for its sub-folder and can override the root setting. Setting `barrel: false` on a plugin disables that plugin's barrel and drops its files from the root barrel. The `nested` flag works at the plugin level only, where `{ nested: true }` writes a barrel in every subdirectory so callers can import from any depth. The root `output.barrel` ignores `nested`.

> [!NOTE]
> `pluginBarrel` ships by default and generates nothing until `output.barrel` is set, root or per-plugin. A config that omits `pluginBarrel` entirely leaves barrel generation untouched.

#### `output.defaultBanner`

Auto-generated banner injected at the top of each file.

|           |                               |
| --------: | :---------------------------- |
|     Type: | `'simple' \| 'full' \| false` |
| Required: | `false`                       |
|  Default: | `'simple'`                    |

`'simple'` adds a short "Generated by Kubb" notice. `'full'` adds the notice plus `Source`, `Title`, and `OpenAPI spec version` from the spec. `false` writes no banner.

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
 * OpenAPI spec version: 1.0.0
 */
```

```typescript [false]
// no banner
```

:::

#### `output.banner`

Text prepended to every file a plugin generates. Set it on an individual plugin. The root `output` exposes only [`output.defaultBanner`](#output-defaultbanner). Use it for license headers, lint-disable comments, or framework directives like `'use server'`.

|           |                                        |
| --------: | :------------------------------------- |
|     Type: | `string \| ((meta: BannerMeta) => string)` |
| Required: | `false`                                |

A string applies to every file the plugin generates, including barrel (`index.ts`) and group aggregation (`[dir]/[dir].ts`) re-export files. A function runs once per file and receives a `BannerMeta`, so you can vary the banner per file or return an empty string to skip it.

`BannerMeta` extends the document `InputMeta` (`title`, `description`, `version`, …) with per-file context:

|              |           |                                                          |
| -----------: | :-------- | :------------------------------------------------------- |
|   `filePath` | `string`  | Full output path of the file being generated.            |
|   `baseName` | `string`  | File name only, for example `stocks.ts`.                 |
|   `isBarrel` | `boolean` | `true` for `index.ts` re-export barrels.                 |
| `isAggregation` | `boolean` | `true` for group `[dir]/[dir].ts` aggregation files. |

The function form fits Next.js Server Actions. Add `'use server'` to source files, but skip it on re-export files, which only re-export symbols or return function references and break under the directive.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      output: {
        path: './clients',
        mode: 'directory',
        banner: (meta) => (meta.isBarrel || meta.isAggregation ? '' : "'use server'"),
      },
      group: { type: 'tag' },
    }),
  ],
})
```

> [!NOTE]
> Barrel `index.ts` files stay banner-free by default. They get a banner only when the plugin sets `output.banner`, at which point the function runs with `isBarrel: true`.

#### `output.footer`

Text appended to the end of every file a plugin generates. Mirror of [`output.banner`](#output-banner), with the same `string | ((meta: BannerMeta) => string)` type.

|           |                                        |
| --------: | :------------------------------------- |
|     Type: | `string \| ((meta: BannerMeta) => string)` |
| Required: | `false`                                |

### `plugins`

Array of Kubb plugins. A plugin can declare dependencies, and Kubb throws at startup when one is missing.

|           |                         |
| --------: | :---------------------- |
|     Type: | `Array<Plugin>`         |
| Required: | `false`                 |

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'models' },
    }),
  ],
})
```

### `adapter`

Adapter that converts your input into the universal AST. With `defineConfig` from the `kubb` package this defaults to `adapterOas()` from [`@kubb/adapter-oas`](/adapters/adapter-oas/).

See the [Adapter concept](/docs/5.x/guide/concepts/adapters) for the full picture.

|           |                                       |
| --------: | :------------------------------------ |
|     Type: | `Adapter`                             |
| Required: | `false`                               |
|  Default: | `adapterOas()` (included with `kubb`) |

Pass options to customize the adapter:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: true }),
})
```

### `parsers`

Array of parsers that turn the in-memory file representation into source code. Each parser declares which file extensions it handles through `extNames`.

See the [Parser concept](/docs/5.x/guide/concepts/parsers) and [`@kubb/parser-ts`](/parsers/parser-ts/) for the built-in parsers.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Array<Parser>`                                |
| Required: | `false`                                        |
|  Default: | `[parserTs(), parserTsx(), parserMd()]` (included with `kubb`) |

Import parsers explicitly to override the default set:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [parserTs(), parserTsx()],
})
```

### `storage`

Storage driver that persists generated files. Defaults to `fsStorage()` (filesystem).

See the [Storage concept](/docs/5.x/guide/concepts/storage) for the built-in drivers and how to write a custom backend.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Storage`                            |
| Required: | `false`                              |
|  Default: | `fsStorage()` (included with `kubb`) |


```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { memoryStorage } from 'kubb/kit'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  storage: memoryStorage(),
})
```

### `root`

Project root, absolute or relative to the config file location.

|           |                 |
| --------: | :-------------- |
|     Type: | `string`        |
| Required: | `false`         |
|  Default: | `process.cwd()` |

### `reporters`

Reporters available to the run, registered as instances. `defineConfig` registers the built-in `cli`, `json`, and `file` reporters by default. The CLI [`--reporter`](/docs/5.x/reference/commands/generate#reporters) flag picks which ones fire by name, defaulting to `cli` when omitted. `cli` writes the end-of-run summary to the terminal. `json` writes a machine-readable report to stdout for CI. `file` writes the run's diagnostics to `.kubb/kubb-<name>-<timestamp>.log`.

|           |                                             |
| --------: | :------------------------------------------ |
|     Type: | `Array<Reporter>`                           |
|  Default: | `[cli, json, file]`                         |
| Required: | `false`                                     |

The built-in reporters are registered by default. Pick which ones fire by name on the CLI with `--reporter <name>`, so most configs never set this option.
