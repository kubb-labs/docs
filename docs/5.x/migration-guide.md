---
title: Migration Guide
description: Step-by-step guide for migrating from Kubb v4 to v5. Covers every breaking change in core and every plugin, with verified before/after examples for both configuration and generated output.
layout: doc
outline: [2, 3, 4]
---

# Migration Guide: v4 → v5

Kubb v5 introduces a layered architecture that splits responsibilities between [adapters](/docs/5.x/concepts/adapters), [plugins](/docs/5.x/concepts/plugins), [parsers](/docs/5.x/concepts/parsers), and [storage](/docs/5.x/concepts/storage). This guide lists every user-facing breaking change and shows the matching v5 syntax. Each section follows the same pattern: a short rationale, a before/after diff, and a link to the relevant reference.

> [!TIP]
> Start with the [Upgrade prompt](#upgrade-prompt) to migrate most configurations automatically, then walk through this page to verify the result.

## Upgrade prompt

Copy the prompt below, paste it into any LLM ([Claude](https://claude.ai), [ChatGPT](https://chat.openai.com), [Gemini](https://gemini.google.com), …), and append your `kubb.config.ts` at the end.

::: details Expand upgrade prompt

```text
You are migrating a kubb.config.ts from Kubb v4 to v5.
Apply every rule below in order, then output the complete updated file.

## 1. Import source
- Change: import { defineConfig } from '@kubb/core'
+ To:     import { defineConfig } from 'kubb'

## 2. Remove @kubb/plugin-oas from plugins[]
- Remove pluginOas() from the plugins array entirely.
- Move its options (validate, serverIndex, serverVariables, discriminator,
  contentType) to a top-level `adapter` key using adapterOas() from
  '@kubb/adapter-oas'. If no options were passed, omit the adapter key
  (it defaults automatically when importing from `kubb`).

## 3. Move per-plugin schema options to adapterOas
Delete these from every plugin and set them once on adapterOas():
  - dateType        (from plugin-ts, plugin-faker, and plugin-zod)
  - integerType     (from plugin-ts, plugin-zod, plugin-faker)
  - unknownType     (from plugin-ts, plugin-zod, plugin-faker)
  - emptySchemaType (from plugin-ts, plugin-zod, plugin-faker)
  - enumSuffix      (from plugin-ts only)
  - contentType     (from plugin-ts and plugin-msw)

## 4. Rename transformers.name → resolver.<resolveSpecificName>
- plugin-ts:    resolver: { resolveTypeName(name) { return … } }
- plugin-zod:   resolver: { resolveSchemaName(name) { return … } }
- all others:   resolver: { resolveName(name) { return … } }
Inside a method, call `this.default(name, 'function')` to invoke the
built-in logic as a fallback.

## 5. Rename transformers.schema → macros
- schema transforms are now macros:
    macros: [{ name: 'strip-descriptions', schema(node) { return … } }]

## 6. plugin-ts specific
- Remove `mapper` (use printer or macros instead).
- Remove `UNSTABLE_NAMING` (v5 always uses the new naming convention).

## 7. plugin-zod specific
- Remove `version` (always Zod v4 in v5).
- Remove `mapper` (use printer or macros instead).
- Set zod dependency to ^4.

## 8. Rename output.barrelType → output.barrel (object)
Replace every `barrelType` string with the `barrel` object:
  - output.barrelType: 'named'     → output.barrel: { type: 'named' }
  - output.barrelType: 'all'       → output.barrel: { type: 'all' }
  - output.barrelType: 'propagate' → output.barrel: { type: 'named', nested: true }
    (or { type: 'all', nested: true } if the original intent was wildcard exports)
  - output.barrelType: false        → output.barrel: false
This applies at both the root output level and per-plugin output levels.

## 9. Preserve everything else
All other plugin options (output, group, include, exclude, override,
generators, client, infinite, suspense, query, mutation,
paramsCasing, paramsType, pathParamsType, parser, dataReturnType,
clientType, bundle, baseURL, urlType, operations, typed, inferred,
coercion, guidType, mini, wrapOutput, dateParser, regexGenerator,
seed, handlers, etc.) are unchanged.

## 10. New v5 defaults (informational, do not edit the config)

With `group: { type: 'tag' }`, v5 names each tag folder after the plain
camelCased tag instead of `${tag}Controller`. Do not add `group.name`
during migration. Mention to the user that
`group: { type: 'tag', name: ({ group }) => `${group}Controller` }`
restores the v4 folder layout.

## 11. Single-file output now needs output.mode
v5 no longer infers a single file from an `output.path` that ends in `.ts`.
For every plugin whose `output.path` points at a file (ends in `.ts`), add
`mode: 'file'` to its `output` and keep the extension in the path:
  - output: { path: 'models.ts' } → output: { path: 'models.ts', mode: 'file' }
The extension is required — do not drop it. Leave folder paths unchanged;
they default to `mode: 'directory'`. `output.mode` only accepts
`'directory'` or `'file'`.

Now migrate the following kubb.config.ts:
```

:::

## Performance

v5 generates code faster than v4. Benchmarks compare `@kubb/core@4.37.8` with the v5 `kubb` meta-package, using `write: false` to focus on the generation pipeline.

> [!NOTE]
> Measured on a 4-core Intel Xeon @ 2.80 GHz, Linux. Speedup is the headline. Absolute milliseconds are hardware-dependent.

**`petStore.yaml`**, 19 operations

| Plugins                                                       | v4 mean   | v5 mean  | Speedup   |
| ------------------------------------------------------------- | --------- | -------- | --------- |
| `plugin-ts`                                                   | 130.53 ms | 66.03 ms | **+98%**  |
| `plugin-ts` + `plugin-client`                                 | 198.64 ms | 76.77 ms | **+159%** |
| `plugin-ts` + `plugin-client` + `plugin-zod` + `plugin-faker` | 331.90 ms | 99.07 ms | **+235%** |

**`twitter.json`**, 80 operations, 374 KB

| Plugins                                                       | v4 mean  | v5 mean | Speedup   |
| ------------------------------------------------------------- | -------- | ------- | --------- |
| `plugin-ts`                                                   | 1,486 ms | 375 ms  | **+296%** |
| `plugin-ts` + `plugin-client`                                 | 1,743 ms | 401 ms  | **+335%** |
| `plugin-ts` + `plugin-client` + `plugin-zod` + `plugin-faker` | 2,997 ms | 711 ms  | **+322%** |

**`openai.yaml`**, 242 operations, 2.7 MB ([openai/openai-openapi](https://github.com/openai/openai-openapi))

| Plugins                                                       | v4 mean   | v5 mean  | Speedup   |
| ------------------------------------------------------------- | --------- | -------- | --------- |
| `plugin-ts`                                                   | 6,033 ms  | 1,450 ms | **+316%** |
| `plugin-ts` + `plugin-client`                                 | 7,662 ms  | 1,544 ms | **+396%** |
| `plugin-ts` + `plugin-client` + `plugin-zod` + `plugin-faker` | 14,943 ms | 2,461 ms | **+507%** |

The gap widens on bigger specs. In v4, every plugin bootstrapped its own `pluginOas` instance, so OAS parsing ran once per plugin. The `adapterOas` in v5 parses the spec once and shares the result across all plugins.

## System requirements

|         | v4   | v5   |
| ------- | ---- | ---- |
| Node.js | ≥ 18 | ≥ 22 |

Update your CI pipelines, the `engines` field in `package.json`, and any `Dockerfile` `FROM node` lines. See [Installation](/docs/5.x/getting-started/installation) for the full setup.

## Packages

### Plugins moved to a separate repository

In v4, every plugin lived in [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb). In v5 the plugins were extracted into [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins) but keep the same npm package names, so no rename is required.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts @kubb/plugin-zod @kubb/plugin-client \
            @kubb/plugin-react-query @kubb/plugin-vue-query @kubb/plugin-swr \
            @kubb/plugin-faker @kubb/plugin-msw \
            @kubb/plugin-mcp @kubb/plugin-cypress @kubb/plugin-redoc
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts @kubb/plugin-zod @kubb/plugin-client \
            @kubb/plugin-react-query @kubb/plugin-vue-query @kubb/plugin-swr \
            @kubb/plugin-faker @kubb/plugin-msw \
            @kubb/plugin-mcp @kubb/plugin-cypress @kubb/plugin-redoc
```

```shell [npm]
npm install -D @kubb/plugin-ts @kubb/plugin-zod @kubb/plugin-client \
               @kubb/plugin-react-query @kubb/plugin-vue-query @kubb/plugin-swr \
               @kubb/plugin-faker @kubb/plugin-msw \
               @kubb/plugin-mcp @kubb/plugin-cypress @kubb/plugin-redoc
```

```shell [yarn]
yarn add -D @kubb/plugin-ts @kubb/plugin-zod @kubb/plugin-client \
            @kubb/plugin-react-query @kubb/plugin-vue-query @kubb/plugin-swr \
            @kubb/plugin-faker @kubb/plugin-msw \
            @kubb/plugin-mcp @kubb/plugin-cypress @kubb/plugin-redoc
```

:::

### Removed plugins

The following plugins have no v5 equivalent. Remove them from your config and uninstall the packages.

| v4 package                  |
| --------------------------- |
| `@kubb/plugin-solid-query`  |
| `@kubb/plugin-svelte-query` |

> [!NOTE]
> `@kubb/plugin-swr` was unavailable during the early v5 betas but is **supported again in v5**. See [@kubb/plugin-swr](#kubb-plugin-swr) below.

### New packages in v5

| Package                                                     | Purpose                                                                                              |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`@kubb/adapter-oas`](/adapters/adapter-oas)                | Replaces `@kubb/plugin-oas`. See [Adapters](/docs/5.x/concepts/adapters).                            |
| [`@kubb/plugin-barrel`](/plugins/plugin-barrel) | Barrel-file generation, auto-included via `kubb`. See [Barrel files](/docs/5.x/concepts/middlewares). |
| [`@kubb/parser-ts`](/parsers/parser-ts)                     | TypeScript and TSX printer, auto-included via `kubb`. See [Parsers](/docs/5.x/concepts/parsers).     |

## Core configuration

### Import source

Always import [`defineConfig`](/docs/5.x/api/core) from the top-level `kubb` package. The `kubb` package wires the OpenAPI [adapter](/docs/5.x/concepts/adapters), TypeScript [parsers](/docs/5.x/concepts/parsers), and the barrel [plugin](/plugins/plugin-barrel) automatically.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
```

:::

### Layered architecture

v5 introduces three top-level keys that replace behaviour previously embedded in each plugin. When you import from `kubb`, all three defaults are applied automatically.

| Option       | Package                                                     | Purpose                                       | Default                 |
| ------------ | ----------------------------------------------------------- | --------------------------------------------- | ----------------------- |
| `adapter`    | [`@kubb/adapter-oas`](/adapters/adapter-oas)                | Parses the input spec into a universal AST.   | `adapterOas()`          |
| `parsers`    | [`@kubb/parser-ts`](/parsers/parser-ts)                     | Converts AST nodes to `.ts` and `.tsx` files. | `[parserTs, parserTsx]` |
| `plugins` (post) | [`@kubb/plugin-barrel`](/plugins/plugin-barrel) | Post-processes output, like barrel files.     | `[pluginBarrel()]`  |

### `@kubb/plugin-oas` removed

`pluginOas()` no longer belongs in `plugins`. Its configuration moves to the top-level `adapter` key.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginOas } from '@kubb/plugin-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginOas({
      validate: true,
      serverIndex: 0,
      serverVariables: { env: 'prod' },
      discriminator: 'inherit',
    }),
    pluginTs(),
  ],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({
    validate: true,
    serverIndex: 0,
    serverVariables: { env: 'prod' },
    discriminator: 'inherit',
  }),
  plugins: [pluginTs()],
})
```

:::

> [!NOTE]
> Uninstall `@kubb/plugin-oas`. The `adapter` defaults to `adapterOas()` when importing from `kubb`, so the `adapter:` line is only required when you pass options.

### `output.format` and `output.lint`: new auto-detection

Both options gained an `'auto'` value that detects available tools, and `'oxfmt'` / `'oxlint'` joined the formatter and linter lists.

| Option          | New v5 values        | Detection order                                                                          |
| --------------- | -------------------- | ---------------------------------------------------------------------------------------- |
| `output.format` | `'auto'`, `'oxfmt'`  | [oxfmt](https://oxc.rs) → [biome](https://biomejs.dev) → [prettier](https://prettier.io) |
| `output.lint`   | `'auto'`, `'oxlint'` | [oxlint](https://oxc.rs) → [biome](https://biomejs.dev) → [eslint](https://eslint.org)   |

### `output.barrelType` → `output.barrel`

The string-based `barrelType` option is replaced by an object-based `barrel` option with a `type` field. At the plugin level, a `nested` flag replaces the old `'propagate'` string.

| v4 (old) `output.barrelType`  | v5 (new) `output.barrel`          |
| ----------------------------- | --------------------------------- |
| `'named'`                     | `{ type: 'named' }`               |
| `'all'`                       | `{ type: 'all' }`                 |
| `'propagate'` _(plugin only)_ | `{ type: 'named', nested: true }` |
| `false`                       | `false`                           |

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen', barrelType: 'named' },
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named' } },
})
```

:::

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen', barrelType: 'propagate' },
  plugins: [pluginTs()],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen', barrel: { type: 'named', nested: true } },
  plugins: [pluginTs()],
})
```

:::

See [`@kubb/plugin-barrel`](/plugins/plugin-barrel) for the full `barrel` option reference.

### Single-file output uses `output.mode`

v4 decided between a folder and a single file by looking at the `output.path` extension: a path ending in `.ts` produced one file, anything else produced a folder. v5 removes that guess. The new `output.mode` option states the layout outright.

| `output.mode` | Layout                                                            |
| ------------- | ----------------------------------------------------------------- |
| `'directory'` | One file per operation or schema. The default.                    |
| `'file'`      | One file for the whole plugin.                                    |

To keep a single-file layout from v4, add `mode: 'file'`. The `output.path` must include the extension — Kubb uses it as-is.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'models.ts' } })],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'models.ts', mode: 'file' } })],
})
```

:::

`mode: 'file'` forbids the `group` option, since a single file has nothing to group. Pairing them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error. To organize `'directory'` output into per-tag or per-path subfolders, keep `mode: 'directory'` and add the `group` option (covered next).

### Group folders use the plain tag

With `group: { type: 'tag' }`, every plugin now writes each tag to a folder named after the camelCased tag. v4 appended a `Controller` suffix (and `Requests` for the Cypress and MCP plugins), so `pet` operations landed in `petController/`. v5 drops the suffix and uses `pet/`. Nothing in the generated output referenced the suffix, so the change is folder layout only.

The config stays the same. Only the output folders change:

```text
v4: src/gen/clients/petController/  →  v5: src/gen/clients/pet/
```

To keep the v4 layout, set `group.name` on the plugin:

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      group: { type: 'tag', name: ({ group }) => `${group}Controller` },
    }),
  ],
})
```

### Logging: `--debug` replaced by reporters

The `--debug` flag and the `debug` value of `--logLevel` are gone. v5 renders a run through reporters, picked on the CLI with `--reporter` (comma-separated) or in the config with `reporters`. The CLI flag overrides the config. Three ship built in:

| Reporter          | Output                                                                  |
| ----------------- | ----------------------------------------------------------------------- |
| `cli` _(default)_ | The end-of-run summary in the terminal.                                 |
| `json`            | A stable machine-readable report on stdout, for CI.                     |
| `file`            | A log written to `.kubb/kubb-<timestamp>.log`. This replaces `--debug`. |

::: code-group

```shell [v4]
kubb generate --debug
```

```shell [v5]
kubb generate --reporter file
```

:::

The `kubb:debug` hook and the `createDebugger` helper are removed alongside the flag. See [`kubb generate`](/docs/5.x/api/commands/generate) for the full flag list and [Diagnostics](/docs/5.x/reference/diagnostics) for the structured problem model the reporters render.

## Options moved to `adapterOas`

Schema-level options that previously had to be repeated on every plugin now live on [`adapterOas`](/adapters/adapter-oas) and apply globally. Remove them from each plugin and set them once on the adapter.

| Option            | Removed from                              | v5 location                       |
| ----------------- | ----------------------------------------- | --------------------------------- |
| `dateType`        | `plugin-ts`, `plugin-faker`, `plugin-zod` | `adapterOas({ dateType })`        |
| `integerType`     | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ integerType })`     |
| `unknownType`     | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ unknownType })`     |
| `emptySchemaType` | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ emptySchemaType })` |
| `enumSuffix`      | `plugin-ts`                               | `adapterOas({ enumSuffix })`      |
| `contentType`     | `plugin-ts`, `plugin-msw`                 | `adapterOas({ contentType })`     |

> [!IMPORTANT]
> The default value of `integerType` changed from `'number'` to `'bigint'`. OpenAPI `int64` fields now map to `bigint` by default. To keep the previous behavior, set `integerType: 'number'` explicitly on `adapterOas`.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
      emptySchemaType: 'unknown',
      enumSuffix: 'enum',
    }),
    pluginZod({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
    }),
    pluginFaker({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
    }),
  ],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({
    dateType: 'date',
    integerType: 'number',
    unknownType: 'unknown',
    emptySchemaType: 'unknown',
    enumSuffix: 'enum',
  }),
  plugins: [pluginTs(), pluginZod(), pluginFaker()],
})
```

:::

## Shared plugin API

These changes apply to every plugin that defined `transformers` in v4.

### `transformers.name` → `resolver`

The single `transformers.name(name, type)` callback is replaced by typed [resolver](/docs/5.x/concepts/plugins#resolvers) methods. The exact method depends on the plugin:

| Plugin                                                                                                                                                                                                                                                                                                                                                    | Resolver method           |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts)                                                                                                                                                                                                                                                                                                                   | `resolveTypeName(name)`   |
| [`@kubb/plugin-zod`](/plugins/plugin-zod)                                                                                                                                                                                                                                                                                                                 | `resolveSchemaName(name)` |
| [`@kubb/plugin-client`](/plugins/plugin-client), [`@kubb/plugin-react-query`](/plugins/plugin-react-query), [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query), [`@kubb/plugin-msw`](/plugins/plugin-msw), [`@kubb/plugin-faker`](/plugins/plugin-faker), [`@kubb/plugin-cypress`](/plugins/plugin-cypress), [`@kubb/plugin-mcp`](/plugins/plugin-mcp) | `resolveName(name)`       |

Inside a resolver method, `this` is bound to the full resolver, so `this.default(name, 'function')` falls back to the preset logic.

::: code-group

```typescript [v4]
pluginTs({
  transformers: {
    name: (name) => `Api${name}`,
  },
})
```

```typescript twoslash [v5]
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    resolveTypeName(name) {
      return `Api${this.default(name, 'function')}`
    },
  },
})
```

:::

### `transformers.schema` → `macros`

Schema-level transformations move to [macros](/docs/5.x/concepts/macros). Returning `null` or `undefined` from a macro callback falls back to the preset behavior.

::: code-group

```typescript [v4]
pluginZod({
  transformers: {
    schema: (schema) => ({ ...schema, description: undefined }),
  },
})
```

```typescript twoslash [v5]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  macros: [
    {
      name: 'strip-descriptions',
      schema(node) {
        return { ...node, description: undefined }
      },
    },
  ],
})
```

:::

### New: `printer`

Code-generating plugins now accept a `printer` option for overriding individual AST node renderers. Use it instead of the removed `mapper` option for type-level customizations.

```typescript twoslash [v5]
import ts from 'typescript'
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  printer: {
    nodes: {
      date() {
        return ts.factory.createTypeReferenceNode('Date', [])
      },
    },
  },
})
```

## Multiple content types

When an OpenAPI operation declares multiple content types for its `requestBody`, v5 generates a separate type per content type and a union alias. In v4, only the first content type was used.

```typescript
// plugin-ts output for an operation with application/json + multipart/form-data
export type UploadFileJsonData = { url: string }
export type UploadFileFormData = { file: Blob }
export type UploadFileData = UploadFileJsonData | UploadFileFormData
```

The generated client exposes `contentType` as a typed literal union and defaults to the first declared content type:

```typescript
uploadFile(petId, data, { contentType: 'multipart/form-data' })
```

Single-content-type operations are unchanged.

## @kubb/plugin-ts

See the full reference in [`@kubb/plugin-ts`](/plugins/plugin-ts).

### Removed: `mapper`

```typescript [v4 kubb.config.ts]
pluginTs({ mapper: { status: 'string' } })
```

Use [`printer.nodes`](/plugins/plugin-ts#printer) to override specific schema-type renderers, or [`macros`](/plugins/plugin-ts#macros) to rewrite AST nodes before printing.

### Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, and `contentType` moved to [`adapterOas`](/adapters/adapter-oas). See [Options moved to adapterOas](#options-moved-to-adapteroas).

## @kubb/plugin-zod

See the full reference in [`@kubb/plugin-zod`](/plugins/plugin-zod).

### Zod v3 no longer supported

The `version` option (`'3' | '4'`) is removed. v5 always generates [Zod v4](https://zod.dev) schemas.

Upgrade your `zod` dependency:

::: code-group

```shell [bun]
bun add zod@^4
```

```shell [pnpm]
pnpm add zod@^4
```

```shell [npm]
npm install zod@^4
```

```shell [yarn]
yarn add zod@^4
```

:::

### Removed: `mapper`

Use [`macros`](/plugins/plugin-zod#macros) or [`printer`](/plugins/plugin-zod#printer) instead.

### Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). See [Options moved to adapterOas](#options-moved-to-adapteroas).

### New: `mini`

Generate [Zod Mini](https://zod.dev/packages/mini)'s functional syntax for better tree-shaking. When `mini: true`, `importPath` defaults to `'zod/mini'`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginZod({ mini: true })],
})
```

### Changed: inferred type names end with `Type`

With `inferred: true`, the `z.infer<typeof schema>` alias now carries a `SchemaType` suffix. `petSchema` exports `PetSchemaType` instead of `PetSchema`.

Before, the schema value and its inferred type differed only by casing (`petSchema` and `PetSchema`). An all-uppercase schema name such as `SUV`, `URL`, or `API` produced the same identifier for both, so the generated barrel re-exported it twice and failed to compile with `TS2300: Duplicate identifier`. The `Type` suffix keeps the value and the type distinct regardless of casing.

```typescript [zod/petSchema.ts]
export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})

export type PetSchemaType = z.infer<typeof petSchema> // [!code ++]
export type PetSchema = z.infer<typeof petSchema> // [!code --]
```

Update any imports that referenced the old name:

```typescript
import type { PetSchemaType } from './gen/zod/petSchema.ts' // [!code ++]
import type { PetSchema } from './gen/zod/petSchema.ts' // [!code --]
```

## @kubb/plugin-faker

See the full reference in [`@kubb/plugin-faker`](/plugins/plugin-faker).

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). The `transformers.name` → [`resolver.resolveName`](#transformersname-resolver) pattern applies. All other options are unchanged.

## @kubb/plugin-client

See the full reference in [`@kubb/plugin-client`](/plugins/plugin-client).

`transformers.name` is replaced by [`resolver.resolveName`](#transformersname-resolver). The `wrapper` option is renamed to `sdk`.

Class clients (`clientType: 'class'`, `clientType: 'staticClass'`, and `sdk`) now name each tag class with a `Client` suffix. A `pet` tag generates `class PetClient` instead of `class Pet`. The old name matched the schema model of the same name, so the barrel re-exported both and `tsc` failed with `TS2300: Duplicate identifier`. The suffix keeps the class and the model apart.

```ts
// Before
export class Pet { /* ... */ }

// After
export class PetClient { /* ... */ }
```

To keep the previous names, override `resolveGroupName` on the `resolver` option. `this` is bound to the full resolver, so `this.resolveClassName` restores the old behavior.

```ts
pluginClient({
  clientType: 'class',
  resolver: {
    resolveGroupName(name) {
      return this.resolveClassName(name)
    },
  },
})
```

All other options are unchanged.

## @kubb/plugin-react-query and @kubb/plugin-vue-query

See [`@kubb/plugin-react-query`](/plugins/plugin-react-query) and [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query).

`transformers.name` is replaced by [`resolver.resolveName`](#transformersname-resolver). The `client` sub-object for HTTP client configuration is unchanged. All other options are unchanged.

## @kubb/plugin-msw

See the full reference in [`@kubb/plugin-msw`](/plugins/plugin-msw).

`transformers.name` is replaced by [`resolver.resolveName`](#transformersname-resolver). The `contentType` option moved to [`adapterOas`](/adapters/adapter-oas). All other options are unchanged.

## @kubb/plugin-swr

See the full reference in [`@kubb/plugin-swr`](/plugins/plugin-swr).

`@kubb/plugin-swr` is supported again in v5. It now follows the same conventions as the React Query and Vue Query plugins: `transformers.name` is replaced by [`resolver.resolveName`](#transformersname-resolver), and the `client` sub-object for HTTP client configuration is unchanged. Because SWR has no `enabled` option, the param-presence guard is folded into the null-key gate (`useSWR(shouldFetch && !!(petId) ? queryKey : null, ...)`), so passing `undefined` disables the request.

## Removed plugins: Solid Query, Svelte Query

`@kubb/plugin-solid-query` and `@kubb/plugin-svelte-query` have no v5 equivalents. Remove them from your config and uninstall the packages.

## Complete before/after example

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig, memoryStorage } from '@kubb/core'
import { pluginOas } from '@kubb/plugin-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: {
    path: './src/gen',
    format: 'prettier',
    storage: memoryStorage(), // → top-level `storage`
  },
  plugins: [
    pluginOas({
      // → top-level `adapter` with adapterOas()
      validate: true,
      serverIndex: 0,
      discriminator: 'inherit',
    }),
    pluginTs({
      output: { path: 'types' },
      dateType: 'date', // → adapterOas
      integerType: 'number', // → adapterOas
      unknownType: 'unknown', // → adapterOas
      enumSuffix: 'enum', // → adapterOas
      UNSTABLE_NAMING: true, // removed (no replacement)
      mapper: {}, // removed (use printer or macros)
      transformers: {
        name: (name) => `Api${name}`,
      },
    }),
    pluginZod({
      output: { path: 'zod' },
      version: '3', // removed (always Zod v4 in v5)
      dateType: 'string', // → adapterOas
      integerType: 'number', // → adapterOas
      mapper: {}, // removed
    }),
    pluginClient({
      output: { path: 'clients' },
      client: 'axios',
    }),
    pluginReactQuery({
      output: { path: 'hooks' },
      client: { importPath: './src/client.ts' },
    }),
    pluginFaker({
      output: { path: 'mocks' },
      dateType: 'date', // → adapterOas
      integerType: 'number', // → adapterOas
    }),
  ],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { memoryStorage } from '@kubb/core'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: {
    path: './src/gen',
    format: 'prettier',
  },
  storage: memoryStorage(),
  adapter: adapterOas({
    validate: true,
    serverIndex: 0,
    discriminator: 'inherit',
    dateType: 'date',
    integerType: 'number',
    unknownType: 'unknown',
    enumSuffix: 'enum',
  }),
  plugins: [
    pluginTs({
      output: { path: 'types' },
      resolver: {
        resolveTypeName(name) {
          return `Api${this.default(name, 'function')}`
        },
      },
    }),
    pluginZod({
      output: { path: 'zod' },
    }),
    pluginClient({
      output: { path: 'clients' },
      client: 'axios',
    }),
    pluginReactQuery({
      output: { path: 'hooks' },
      client: { importPath: './src/client.ts' },
    }),
    pluginFaker({
      output: { path: 'mocks' },
    }),
  ],
})
```

:::

## Generated output changes per plugin

Beyond config changes, v5 also changes what the generators emit. Update any code that imports from the generated files accordingly.

### [`@kubb/plugin-ts`](/plugins/plugin-ts)

#### Enums: object literal instead of `enum`

v5 emits a `const`-asserted object plus a `*Key` type union. This avoids the runtime cost of TypeScript `enum` and is tree-shakable.

::: code-group

```typescript [v4]
export enum ParamsStatusEnum {
  placed = 'placed',
  approved = 'approved',
  delivered = 'delivered',
}

status: ParamsStatusEnum
```

```typescript [v5]
export enum orderParamsStatusEnum {
  placed = 'placed',
  approved = 'approved',
  delivered = 'delivered',
}

status: OrderParamsStatusEnumKey
```

:::

- Enum names are now operation-scoped (`orderParamsStatusEnum`, `customerParamsStatusEnum`, …) instead of suffix-deduplicated (`ParamsStatusEnum`, `ParamsStatusEnum2`, …). Numeric collisions are gone.
- Configure with [`enum`](/plugins/plugin-ts) on `pluginTs` when you need `enum`, `constEnum`, `literal`, or a different const and type casing.

#### Enum options grouped under `enum`

The loose `enumType`, `enumTypeSuffix`, and `enumKeyCasing` options now live inside one `enum` object, and a new `enum.constCasing` sets the casing of the generated const. The old `enumType: 'asPascalConst'` is gone. Reach for `constCasing: 'pascalCase'` instead.

| v4 (old)                              | v5 (new)                                               |
| ------------------------------------- | ------------------------------------------------------ |
| `enumType: 'asConst'`                 | `enum: { type: 'asConst' }`                            |
| `enumType: 'asPascalConst'`           | `enum: { type: 'asConst', constCasing: 'pascalCase' }` |
| `enumTypeSuffix: 'Value'`             | `enum: { typeSuffix: 'Value' }`                        |
| `enumKeyCasing: 'screamingSnakeCase'` | `enum: { keyCasing: 'screamingSnakeCase' }`            |

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enumType: 'asConst',
      enumTypeSuffix: 'Key',
      enumKeyCasing: 'none',
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enum: { type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' },
    }),
  ],
})
```

:::

> [!TIP]
> Set `constCasing: 'pascalCase'` together with `typeSuffix: ''` to emit a const and a type that share the schema's exact name. This is the convention most hand-written codebases use, so migrating an existing project keeps every annotation and value reference working.
>
> ```typescript
> pluginTs({ enum: { type: 'asConst', constCasing: 'pascalCase', typeSuffix: '' } })
> ```
>
> ```typescript
> export const VehicleType = {
>   Sedan: 'Sedan',
>   SUV: 'SUV',
> } as const
>
> export type VehicleType = (typeof VehicleType)[keyof typeof VehicleType]
> ```

#### `int64` maps to `bigint` by default

`adapterOas` now defaults `integerType` to `'bigint'`. OpenAPI fields with `format: int64` generate `bigint` instead of `number`.

```diff
- petId?: number
+ petId?: bigint
```

Set `integerType: 'number'` on `adapterOas` to restore the previous output.

#### Open string unions use `(string & {})`

To preserve IntelliSense suggestions, v5 writes the well-known TypeScript trick.

```diff
- status?: 'accepted' | string
+ status?: 'accepted' | (string & {})
```

#### JSDoc

- `@type integer | undefined, int64` → `@type integer | undefined` (format suffix removed; format is documented through the schema, not the type comment).
- `@example` is emitted from the OpenAPI `example` field.
- Object schemas now carry an `@type object` JSDoc tag.

#### Discriminated unions are factored

Common fields shared by every variant of a `oneOf`/`anyOf` are factored out:

```diff
- export type Pet =
-   | { id?: number; name: string; status?: StatusEnum; ... }
-   | { id?: number; name: string; status?: StatusEnum; ... }
+ export type Pet = ({ ... } | { ... }) & {
+   id?: number
+   name: string
+   status?: PetStatusEnumKey
+   ...
+ }
```

### [`@kubb/plugin-zod`](/plugins/plugin-zod)

#### Chained syntax instead of functional wrappers

v5 prefers the chained Zod 4 syntax. `.optional()` always sits at the end of the chain, before `.describe()`.

::: code-group

```typescript [v4]
id: z.optional(z.int()),
shipDate: z.optional(z.iso.datetime()),
status: z.optional(z.enum(['placed', 'approved']).describe('Order Status')),
```

```typescript [v5]
id: z.int().optional(),
shipDate: z.iso.datetime().optional(),
status: z.enum(['placed', 'approved']).optional().describe('Order Status'),
```

:::

The functional form (`z.optional(...)`) is now reserved for `mini: true` output, which lives in its own configured `output.path`.

#### Self-referencing getters only for true cycles

v4 wrapped almost every nested ref in a getter. v5 only does so when the schema is genuinely circular (a schema that references itself or its parent).

```diff
- get category() {
-   return categorySchema.optional()
- },
- get tags() {
-   return z.array(tagSchema).optional()
- },
+ category: categorySchema.optional(),
+ tags: z.array(tagSchema).optional(),
  get parent() {
    return z.array(petSchema).optional()
  },
```

### [`@kubb/plugin-faker`](/plugins/plugin-faker)

#### Stricter return type and intermediate variable

The `create` prefix is **kept** in v5 (e.g. `createPet` stays `createPet`), matching the naming used by `plugin-msw`. What changes is the return type and the internal structure:

```diff
- export function createPet(data?: Partial<Pet>): Pet {
-   return {
-     ...{
-       id: faker.number.int(),
-       ...
-     },
-     ...(data || {}),
-   }
- }
+ export function createPet(data?: Partial<Pet>): Required<Pet> {
+   const defaultFakeData = {
+     id: faker.number.int(),
+     ...
+   }
+   return {
+     ...defaultFakeData,
+     ...(data || {}),
+   } as Required<Pet>
+ }
```

`Required<Pet>` guarantees that downstream consumers see populated fields even when the schema marks them optional.

### [`@kubb/plugin-client`](/plugins/plugin-client)

#### Operation type names

The naming scheme dropped the `Mutation` infix and unified status responses under `Status<code>`.

| v4 type                      | v5 type               |
| ---------------------------- | --------------------- |
| `AddPet200`                  | `AddPetStatus200`     |
| `AddPet405`                  | `AddPetStatus405`     |
| `AddPetMutationRequest`      | `AddPetData`          |
| `AddPetMutationResponse`     | `AddPetResponse`      |
| `AddPetMutation` (container) | _removed_ (see below) |
| _did not exist_              | `AddPetResponses`     |
| _did not exist_              | `AddPetRequestConfig` |

The single `AddPetMutation` aggregate is replaced by three explicit types:

```typescript
export type AddPetRequestConfig = {
  data?: AddPetData
  pathParams?: never
  queryParams?: never
  headerParams?: never
  url: '/pet'
}

export type AddPetResponses = {
  '200': AddPetStatus200
  '405': AddPetStatus405
}

export type AddPetResponse = AddPetStatus200 | AddPetStatus405
```

**GET operation example:**

```typescript
export type GetPetQueryParams = { limit?: number; offset?: number }
export type GetPetRequestConfig = {
  data?: never
  pathParams?: { petId: string }
  queryParams?: GetPetQueryParams
  headerParams?: never
  url: '/pet/{petId}'
}
export type GetPetResponses = { '200': Pet; '404': ErrorResponse }
export type GetPetResponse = Pet | ErrorResponse
```

This naming pattern applies consistently across all HTTP methods and is inherited by `plugin-react-query`, `plugin-vue-query`, `plugin-cypress`, `plugin-msw`, and `plugin-mcp`.

#### Client return type narrows to 2xx responses

The generic on the generated client function now references the union of `2xx` response status types (`AddPetStatus200`) instead of the full response alias (`AddPetResponse`). The returned `Promise` resolves to the success body only; non-`2xx` responses surface through the client's error path.

```diff
- const res = await request<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
+ const res = await request<AddPetStatus200, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
```

`AddPetResponse`, `AddPetResponses`, and the per-status `AddPetStatus<code>` aliases are still emitted by `plugin-ts`; only the generic threaded into the client changes.

This matches the default behavior of axios, ky, and Kubb's bundled fetch client, which all throw on non-`2xx`. If you pass raw native `fetch` as the client without a throwing wrapper, narrow with a type guard at the call site or wrap the client to throw on error responses. The previous union type masked the same runtime mismatch.

#### Bundled client runtime exports `client`

The bundled HTTP client runtime exports its request function as `client` for both the `axios` and `fetch` adapters. This name is consistent across bundled and non-bundled output (`@kubb/plugin-client/clients/fetch`, `@kubb/plugin-client/clients/axios`, and the generated `.kubb/client.ts`), so the generated root barrel re-exports a valid `client` symbol. The bundled file is always written to `.kubb/client.ts`; `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-mcp` previously emitted `.kubb/fetch.ts`.

Generated code imports the runtime as a default import, so most projects need no changes. If you import the request function as a **named** export, rename it to `client`:

```diff
- import { fetch } from '@kubb/plugin-client/clients/fetch'
+ import { client } from '@kubb/plugin-client/clients/fetch'
```

The default import can still bind to any local name:

```typescript
import client from '@kubb/plugin-client/clients/fetch'
```

### [`@kubb/plugin-react-query`](/plugins/plugin-react-query) and [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query)

The exported `*MutationKey` type alias is gone. Keep using the runtime helper if you need the key:

```diff
- export type CreateUserMutationKey = ReturnType<typeof createUserMutationKey>
- export const createUserMutationKey = () => [{ url: '/user' }] as const
+ export const createUserMutationKey = () => [{ url: '/user' }] as const
```

All other generated APIs only inherit the renames from `plugin-client` (`*Data`, `*Response`, `*Status<code>`).

#### Mutation and query `TData` narrows to 2xx responses

The `TData` generic on `useMutation`, `useQuery`, `useInfiniteQuery`, `useSuspenseQuery`, and their `*Options` helpers now references the union of `2xx` response status types instead of the full response alias. This aligns with TanStack Query's contract that `TData` is the resolved success value and errors flow through `TError`.

```diff
  export function useAddPet<TContext>(
    options: {
      mutation?: MutationObserverOptions<
-       AddPetResponse,
+       AddPetStatus200,
        ResponseErrorConfig<AddPetStatus405>,
        { data: AddPetData },
        TContext
      > & { client?: QueryClient }
      client?: Partial<RequestConfig<AddPetData>> & { client?: typeof client }
    } = {},
  ) { /* ... */ }
```

Call sites that previously needed `as` casts or `'id' in res` checks compile directly:

```ts
const pet = await mutateAsync({ data: { name: 'Rex' } })
pet.id // typed as Pet.id — no narrowing required
```

The change applies to `queryFn`, `queryOptions`, and the hook generics in a single pass. No config flag toggles the old behavior. If your client returns non-`2xx` bodies as resolved data instead of throwing, wrap it to throw on error responses so TanStack Query's `error` / `onError` path fires correctly. The previous typing made this silently broken at runtime.

#### `enabled`-guarded params are now optional

`*QueryOptions` and `*InfiniteQueryOptions` emit an `enabled` guard derived from the required path and query parameters (`enabled: !!petId` in React Query, `enabled: () => !!toValue(petId)` in Vue Query). In v4 those parameters stayed required in the generated type, so a caller could never pass `undefined` to reach the disabled state the guard already implements. The type contradicted the runtime.

v5 makes those parameters optional in the generated `queryKey`, `queryOptions`, and hook signatures, and the `queryFn` calls the client with a non-null assertion. The `enabled` guard is unchanged.

```diff
- export function getPetByIdQueryOptions({ petId }: { petId: GetPetByIdPathPetId }, config: Partial<RequestConfig> & { client?: Client } = {}) {
+ export function getPetByIdQueryOptions({ petId }: { petId?: GetPetByIdPathPetId } = {}, config: Partial<RequestConfig> & { client?: Client } = {}) {
    const queryKey = getPetByIdQueryKey({ petId })
    return queryOptions<GetPetByIdStatus200, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>, GetPetByIdStatus200, typeof queryKey>({
      enabled: !!petId,
      queryKey,
      queryFn: async ({ signal }) => {
-       return getPetById({ petId }, { ...config, signal: config.signal ?? signal })
+       return getPetById({ petId: petId! }, { ...config, signal: config.signal ?? signal })
      },
    })
  }
```

You can now pass a not-yet-available value (for example a route param or the result of a dependent query) and rely on the existing guard to keep the query disabled until it resolves:

```ts
// type-checks in v5; the query stays disabled until petId is defined
useGetPetById({ petId: route.params.petId })
```

> [!NOTE]
> This is a type-only change. The `?` and `!` are erased at compile time, so the emitted JavaScript (including the `enabled` guard) is identical to v4. Suspense hooks cannot be disabled, so their parameters stay required.

### [`@kubb/plugin-msw`](/plugins/plugin-msw)

Handlers are now strongly typed against the request body and headers, and accept an `HttpResponseResolver` callback instead of an inline MSW handler signature.

::: code-group

```typescript [v4]
export function createUserHandler(
  data?: string | number | boolean | null | object | ((info: Parameters<Parameters<typeof http.post>[1]>[0]) => Response | Promise<Response>),
) {
  return http.post('http://localhost:3000/user', function handler(info) {
    ...
  })
}
```

```typescript [v5]
import type { HttpResponseResolver } from 'msw'
import type { CreateUserData } from '../../../models/CreateUser.ts'

export function createUserHandler(
  data?: string | number | boolean | null | object | HttpResponseResolver<Record<string, string>, CreateUserData, any>,
) {
  return http.post<Record<string, string>, CreateUserData, any>(`http://localhost:3000/user`, function handler(info) {
    ...
  })
}
```

:::

### [`@kubb/plugin-cypress`](/plugins/plugin-cypress)

- HTTP method constants are uppercased (`'post'` → `'POST'`).
- Imports follow the new `*Data` / `*Response` naming.

```diff
- import type { AddPetMutationRequest, AddPetMutationResponse } from '../../models/AddPet.ts'
- export function addPet(data: AddPetMutationRequest): Cypress.Chainable<AddPetMutationResponse> {
-   return cy.request<AddPetMutationResponse>({
-     method: 'post',
-     url: 'http://localhost:3000/pet',
+ import type { AddPetData, AddPetResponse } from '../../models.ts'
+ export function addPet(data: AddPetData): Cypress.Chainable<AddPetResponse> {
+   return cy.request<AddPetResponse>({
+     method: 'POST',
+     url: `http://localhost:3000/pet`,
```

### [`@kubb/plugin-mcp`](/plugins/plugin-mcp)

Handlers receive the MCP `RequestHandlerExtra` object as a second argument and forward it to the underlying client. Existing tools must be updated to thread it through.

::: code-group

```typescript [v4]
import type { CallToolResult } from '@modelcontextprotocol/sdk/types'

export async function addPetHandler({ data }: { data: AddPetMutationRequest }): Promise<CallToolResult> {
  const res = await fetch<AddPetMutationResponse, ResponseErrorConfig<AddPet405>, AddPetMutationRequest>({
    method: 'POST',
    url: '/pet',
    baseURL: 'https://petstore.swagger.io/v2',
    data,
  })
  ...
}
```

```typescript [v5]
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types'
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol'

export async function addPetHandler(
  { data }: { data: AddPetData },
  request: RequestHandlerExtra<ServerRequest, ServerNotification>,
): Promise<CallToolResult> {
  const res = await client<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>(
    { method: 'POST', url: `/pet`, baseURL: `https://petstore.swagger.io/v2`, data },
    request,
  )
  ...
}
```

:::

### Cross-cutting changes

These apply to every generator unless explicitly disabled:

- The banner (`/* Generated by Kubb */`) is controlled by [`output.defaultBanner`](/docs/5.x/reference/configuration#output-defaultbanner) on the root config (default `'simple'`). Use [`output.banner`](/docs/5.x/reference/configuration#output-banner) (and [`output.footer`](/docs/5.x/reference/configuration#output-footer)) on individual plugins to override the text for a specific plugin's files. A string applies to every file. Pass a function to receive per-file context (`isBarrel`, `isAggregation`, `filePath`, `baseName`) and skip the banner on re-export files, for example to add `'use server'` to source files but not to barrel or group aggregation files.
- All response status types are suffixed with `Status<code>`.

## Plugin author migration

If you maintain a custom plugin or generator, update the following:

### `PluginManager` → `PluginDriver`

The internal orchestration class was renamed. Update every import and usage:

```diff
- import { PluginManager } from '@kubb/core'
+ import { PluginDriver } from '@kubb/core'

- const manager = new PluginManager(config)
+ const driver = new PluginDriver(config)

- ctx.pluginManager.getPlugin(name)
+ ctx.driver.getPlugin(name)
```

The generator context property follows the same rename: `pluginManager` → `driver`.

### `pluginKey` → `pluginName`

Each plugin now has a single `pluginName` identifier. The `pluginKey` array property is removed.

```diff
- export const myPlugin = definePlugin(() => ({
-   pluginKey: ['my-plugin'],
+ export const myPlugin = definePlugin(() => ({
+   pluginName: 'my-plugin',
```

Duplicate plugins (same `pluginName` registered twice) now throw at startup.

## See also

- [Adapters](/docs/5.x/concepts/adapters): how the OpenAPI input is parsed into the universal AST.
- [Plugins](/docs/5.x/concepts/plugins): lifecycle, generators, and resolvers.
- [Parsers](/docs/5.x/concepts/parsers): how AST nodes become source files.
- [Barrel files](/docs/5.x/concepts/middlewares): barrel file generation with `@kubb/plugin-barrel`.
- [Storage](/docs/5.x/concepts/storage): switching between filesystem and in-memory storage.
- [`@kubb/adapter-oas`](/adapters/adapter-oas): every option that moved here from the plugins.
- [Plugin registry](/plugins): the full list of v5 plugins.
- [Recipes](/docs/5.x/recipes): copy-paste configurations for common scenarios.
