---
title: Migration Guide
description: Step-by-step guide for migrating from Kubb v4 to v5. Covers every breaking change in core and every plugin, with verified before/after examples for both configuration and generated output.
layout: doc
outline: [2, 3, 4]
---

# Migration Guide: v4 → v5

Kubb v5 introduces a layered architecture that splits responsibilities between [adapters](/docs/5.x/concepts/adapters), [plugins](/docs/5.x/concepts/plugins), [parsers](/docs/5.x/concepts/parsers), and [storage](/docs/5.x/concepts/storage). This guide lists every user-facing breaking change with the matching v5 syntax. Each section gives a short rationale, a before/after diff, and a link to the reference.

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

v5 generates code faster than v4. Benchmarks compare `@kubb/core@4.37.8` with the v5 `kubb` meta-package, with file writing disabled to focus on the generation pipeline.

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

The gap widens on bigger specs. In v4, every plugin bootstrapped its own `pluginOas` instance, so parsing ran once per plugin. The `adapterOas` in v5 parses the spec once and shares the result across all plugins.

## System requirements

|         | v4   | v5   |
| ------- | ---- | ---- |
| Node.js | ≥ 18 | ≥ 22 |

Update your CI pipelines, the `engines` field in `package.json`, and any `Dockerfile` `FROM node` lines. See [Installation](/docs/5.x/getting-started/installation) for the full setup.

## Packages

### Plugins moved to a separate repository

In v4, every plugin lived in [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb). v5 extracted them into [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins), but the npm package names are unchanged, so no rename is required.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-client@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-client@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [npm]
npm install -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-client@beta \
               @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
               @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
               @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-client@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

:::

### Removed plugins

The following plugins have no v5 equivalent. Remove them from your config and uninstall the packages.

| v4 package                  |
| --------------------------- |
| `@kubb/plugin-solid-query`  |
| `@kubb/plugin-svelte-query` |

> [!NOTE]
> `@kubb/plugin-swr` was unavailable during the early v5 betas but is supported again in v5. See [Migration: @kubb/plugin-swr](/docs/5.x/migration-guide/plugin-swr).

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
| `parsers`    | [`@kubb/parser-ts`](/parsers/parser-ts)                     | Converts AST nodes to `.ts`, `.tsx`, and `.md` files. | `[parserTs, parserTsx, parserMd]` |
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

v4 chose between a folder and a single file from the `output.path` extension: a path ending in `.ts` produced one file, anything else a folder. v5 removes that guess and states the layout outright with `output.mode`.

| `output.mode` | Layout                                                            |
| ------------- | ----------------------------------------------------------------- |
| `'directory'` | One file per operation or schema. The default.                    |
| `'file'`      | One file for the whole plugin.                                    |

To keep a single-file layout from v4, add `mode: 'file'`. The `output.path` must include the extension, since Kubb uses it as-is.

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

With `group: { type: 'tag' }`, every plugin now writes each tag to a folder named after the camelCased tag. v4 appended a `Controller` suffix (and `Requests` for the Cypress and MCP plugins), so `pet` operations landed in `petController/`. v5 drops the suffix and uses `pet/`. Nothing in the generated output referenced the suffix, so only the folder layout changes.

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

The `--debug` flag and the `debug` value of `--logLevel` are gone. v5 renders a run through reporters, picked on the CLI with `--reporter` (comma-separated) or in the config with `reporters`. The CLI flag wins. Three ship built in:

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

## Per-extension changes

Each extension keeps its configuration changes on its own page. Open the one you use.

- [`@kubb/adapter-oas`](/docs/5.x/migration-guide/adapter-oas)
- [`@kubb/plugin-ts`](/docs/5.x/migration-guide/plugin-ts)
- [`@kubb/plugin-zod`](/docs/5.x/migration-guide/plugin-zod)
- [`@kubb/plugin-faker`](/docs/5.x/migration-guide/plugin-faker)
- [`@kubb/plugin-client`](/docs/5.x/migration-guide/plugin-client)
- [`@kubb/plugin-react-query`](/docs/5.x/migration-guide/plugin-react-query)
- [`@kubb/plugin-vue-query`](/docs/5.x/migration-guide/plugin-vue-query)
- [`@kubb/plugin-msw`](/docs/5.x/migration-guide/plugin-msw)
- [`@kubb/plugin-swr`](/docs/5.x/migration-guide/plugin-swr)
- [`@kubb/plugin-cypress`](/docs/5.x/migration-guide/plugin-cypress)
- [`@kubb/plugin-mcp`](/docs/5.x/migration-guide/plugin-mcp)
- [`@kubb/parser-ts`](/docs/5.x/migration-guide/parser-ts)

The adapter page also covers the schema options that moved off the plugins, and each plugin page lists that extension's generated-output changes.

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

## Generated output

v5 also changes what the generators emit, so update any code that imports from the generated files. Two changes apply to every generator:

- The banner (`/* Generated by Kubb */`) is controlled by [`output.defaultBanner`](/docs/5.x/reference/configuration#output-defaultbanner) on the root config (default `'simple'`). Use [`output.banner`](/docs/5.x/reference/configuration#output-banner) (and [`output.footer`](/docs/5.x/reference/configuration#output-footer)) on individual plugins to override the text for a specific plugin's files. A string applies to every file. Pass a function to receive per-file context (`isBarrel`, `isAggregation`, `filePath`, `baseName`) and skip the banner on re-export files, for example to add `'use server'` to source files but not to barrel or group aggregation files.
- All response status types are suffixed with `Status<code>`.

The output changes specific to each generator live on its [per-extension page](#per-extension-changes).

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
