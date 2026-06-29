---
title: Migration Guide
description: Step-by-step guide for migrating from Kubb v4 to v5. Covers every breaking change in core and every plugin, with verified before/after examples for both configuration and generated output.
layout: doc
outline: [2, 3, 4]
---

# Migration Guide: v4 → v5

Kubb v5 splits responsibilities across [adapters](/docs/5.x/guide/concepts/adapters), [plugins](/docs/5.x/guide/concepts/plugins), [parsers](/docs/5.x/guide/concepts/parsers), and [storage](/docs/5.x/guide/concepts/storage), so the upgrade touches more than a version number. This page covers the changes that affect every project: the new import path, the core config, the shared plugin API, and the package moves. Anything specific to one plugin or adapter lives on its [per-extension page](#per-extension-changes), with a before/after diff and a link to the reference.

> [!TIP]
> Start with the [Upgrade prompt](#upgrade-prompt) to migrate most configurations automatically, then read through this page to verify the result.

## Upgrade prompt

Copy the prompt below, paste it into any LLM ([Claude](https://claude.ai), [ChatGPT](https://chat.openai.com), [Gemini](https://gemini.google.com), …), and add your `kubb.config.ts` at the end.

::: details Expand upgrade prompt

```text [Upgrade prompt]
You are migrating a kubb.config.ts from Kubb v4 to v5.
Apply every rule below in order, then output the complete updated file.

## 1. Import source
- Change: import { defineConfig } from '@kubb/core'
+ To:     import { defineConfig } from 'kubb'

## 2. Remove @kubb/plugin-oas from plugins[]
- Remove pluginOas() from the plugins array entirely.
- Move its options to a top-level `adapter` key using adapterOas() from
  '@kubb/adapter-oas'. The old `serverIndex` and `serverVariables` become a
  single `server: { index, variables }` object, and `discriminator` now takes
  `'preserve'` (was `'strict'`) or `'propagate'` (was `'inherit'`). `validate`
  and `contentType` carry over unchanged. If no options were passed, omit the
  adapter key (it defaults automatically when importing from `kubb`).

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

## 9. Remove the `bundle` and `output.override` options
- Remove `bundle` from the client plugin (`plugin-axios` or `plugin-fetch`) and
  from the `client` sub-option of plugin-react-query, plugin-vue-query,
  plugin-swr, and plugin-mcp. The client is always bundled into `.kubb/client.ts`
  now.
- Remove `output.override` (the boolean) from every plugin's `output` and from
  the root `output`. It no longer exists.

## 10. Remove paramsType, pathParamsType, and paramsCasing
- Remove `paramsType` and `pathParamsType` from the client plugin
  (`plugin-axios` or `plugin-fetch`), plugin-react-query, plugin-vue-query,
  plugin-swr, and plugin-cypress.
- Remove `paramsCasing` from every plugin (including the `client` sub-option of
  the query and mcp plugins). Generated functions now always take one grouped
  options object `{ body, path, query, headers }` with camelCase parameter
  names, and the wire-name mapping is automatic.

## 11. Remove dataReturnType and adopt the RequestResult contract
- Remove `dataReturnType` from every plugin. It no longer exists.
- The client plugins (`@kubb/plugin-axios`, `@kubb/plugin-fetch`) return a
  `RequestResult` of `{ data, error, request, response }`, with `throwOnError`
  defaulting to `true`. A `dataReturnType: 'data'` call becomes a destructure:
  `const { data } = await getPet({ path: { petId: 1 } })`. A `dataReturnType: 'full'`
  call becomes `throwOnError: false`, then read `error` and `response.status` off
  the result.
- On plugin-cypress, drop `dataReturnType`. Every helper now yields the response
  body, typed `Cypress.Chainable<T>`.
- plugin-mcp handlers read `res.data`, so no config change is needed beyond
  removing the option.
- Also remove `clientType`, `urlType`, and the custom-client `importPath`: the
  query and mcp plugins now select a registered client plugin through
  `client: 'axios' | 'fetch'`, and the standalone client lives in
  `@kubb/plugin-axios` / `@kubb/plugin-fetch`. The `get<Operation>Url` helpers
  that `urlType: 'export'` produced are gone; [rebuild them with a custom
  plugin](/docs/5.x/migration/plugin-client#rebuild-the-url-helpers-with-a-custom-plugin)
  if you need them.

## 12. Preserve everything else
All other plugin options (output, group, include, exclude, override (the
per-operation array), client, infinite, suspense, query, mutation,
parser, baseURL, operations, typed, inferred,
coercion, guidType, mini, wrapOutput, dateParser, regexGenerator,
seed, handlers, etc.) are unchanged.

## 13. New v5 defaults (informational, do not edit the config)

With `group: { type: 'tag' }`, v5 names each tag folder after the plain
camelCased tag instead of `${tag}Controller`. Do not add `group.name`
during migration. Mention to the user that
`group: { type: 'tag', name: ({ group }) => `${group}Controller` }`
restores the v4 folder layout.

## 14. Single-file output now needs output.mode
v5 no longer infers a single file from an `output.path` that ends in `.ts`.
For every plugin whose `output.path` points at a file (ends in `.ts`), add
`mode: 'file'` to its `output` and keep the extension in the path:
  - output: { path: 'models.ts' } → output: { path: 'models.ts', mode: 'file' }
The extension is required, do not drop it. Leave folder paths unchanged.
They default to `mode: 'directory'`. `output.mode` only accepts
`'directory'` or `'file'`.

## 15. Remove the `generators` option
Remove `generators` from every plugin. Plugins no longer accept custom
generators as an option. To add custom output, build your own plugin.

Now migrate the following kubb.config.ts:
```

:::

## Performance

v5 generates code faster than v4. The benchmarks compare `@kubb/core@4.37.8` with the v5 `kubb` meta-package. File writing is disabled so the numbers reflect the generation pipeline alone.

> [!NOTE]
> Measured on a 4-core Intel Xeon @ 2.80 GHz, Linux. Speedup is the headline. Absolute milliseconds are hardware-dependent.

**`petStore.yaml`**, 19 operations

| Plugins                                                       | v4 mean   | v5 mean  | Speedup   |
| ------------------------------------------------------------- | --------- | -------- | --------- |
| `plugin-ts`                                                   | 130.53 ms | 66.03 ms | **+98%**  |
| `plugin-ts` + `plugin-axios`                                  | 198.64 ms | 76.77 ms | **+159%** |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`  | 331.90 ms | 99.07 ms | **+235%** |

**`twitter.json`**, 80 operations, 374 KB

| Plugins                                                       | v4 mean  | v5 mean | Speedup   |
| ------------------------------------------------------------- | -------- | ------- | --------- |
| `plugin-ts`                                                   | 1,486 ms | 375 ms  | **+296%** |
| `plugin-ts` + `plugin-axios`                                  | 1,743 ms | 401 ms  | **+335%** |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`  | 2,997 ms | 711 ms  | **+322%** |

**`openai.yaml`**, 242 operations, 2.7 MB ([openai/openai-openapi](https://github.com/openai/openai-openapi))

| Plugins                                                       | v4 mean   | v5 mean  | Speedup   |
| ------------------------------------------------------------- | --------- | -------- | --------- |
| `plugin-ts`                                                   | 6,033 ms  | 1,450 ms | **+316%** |
| `plugin-ts` + `plugin-axios`                                  | 7,662 ms  | 1,544 ms | **+396%** |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`  | 14,943 ms | 2,461 ms | **+507%** |

The gap widens on bigger specs. In v4, every plugin bootstrapped its own `pluginOas` instance, so parsing ran once per plugin. In v5, `adapterOas` parses the spec once and shares the result across all plugins.

## System requirements

| Version | v4   | v5   |
|---------| ---- | ---- |
| Node.js | ≥ 18 | ≥ 22 |

Update your CI pipelines, the `engines` field in `package.json`, and any `Dockerfile` `FROM node` lines. See [Installation](/docs/5.x/getting-started/installation) for the full setup.

## Packages

### Plugins moved to a separate repository

In v4, the code-generating plugins lived in [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb). v5 moves them into [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins). The npm package names stay the same, so you do not need to rename anything. The infrastructure packages that `kubb` wires in for you, `@kubb/adapter-oas`, `@kubb/parser-ts`, and `@kubb/plugin-barrel`, stay in `kubb-labs/kubb`.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [npm]
npm install -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta \
               @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
               @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
               @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta \
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
> `@kubb/plugin-swr` was unavailable during the early v5 betas but is supported again in v5. See [Migration: @kubb/plugin-swr](/docs/5.x/migration/plugin-swr).

### New packages in v5

| Package                                                     | Purpose                                                                                              |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| [`@kubb/adapter-oas`](/adapters/adapter-oas)                | Replaces `@kubb/plugin-oas`. See [Adapters](/docs/5.x/guide/concepts/adapters).                            |
| [`@kubb/plugin-barrel`](/plugins/plugin-barrel) | Barrel-file generation, auto-included via `kubb`. See [Barrel files](/docs/5.x/guide/concepts/barrel-files). |
| [`@kubb/parser-ts`](/parsers/parser-ts)                     | TypeScript and TSX printer, auto-included via `kubb`. See [Parsers](/docs/5.x/guide/concepts/parsers).     |

## Core configuration

### Import source

Import [`defineConfig`](/docs/5.x/api/core) from the top-level `kubb` package. That package wires up the OpenAPI [adapter](/docs/5.x/guide/concepts/adapters), the TypeScript [parsers](/docs/5.x/guide/concepts/parsers), and the barrel [plugin](/plugins/plugin-barrel) for you.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
```

:::

### Layered architecture

v5 adds three top-level keys that replace behavior each plugin used to carry on its own. When you import from `kubb`, all three defaults apply automatically.

| Option       | Package                                                     | Purpose                                       | Default                 |
| ------------ | ----------------------------------------------------------- | --------------------------------------------- | ----------------------- |
| `adapter`    | [`@kubb/adapter-oas`](/adapters/adapter-oas)                | Parses the input spec into a universal AST.   | `adapterOas()`          |
| `parsers`    | [`@kubb/parser-ts`](/parsers/parser-ts), `@kubb/parser-md`  | Converts AST nodes to `.ts`, `.tsx`, and `.md` files. | `[parserTs, parserTsx, parserMd]` |
| `plugins` (post) | [`@kubb/plugin-barrel`](/plugins/plugin-barrel) | Post-processes output, like barrel files.     | `[pluginBarrel()]`  |

### `@kubb/plugin-oas` removed

`pluginOas()` no longer belongs in `plugins`. Its options move to the top-level `adapter` key.

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
    server: { index: 0, variables: { env: 'prod' } },
    discriminator: 'propagate',
  }),
  plugins: [pluginTs()],
})
```

:::

> [!NOTE]
> Uninstall `@kubb/plugin-oas`. The `adapter` defaults to `adapterOas()` when importing from `kubb`, so the `adapter:` line is only required when you pass options.

### `output.format` and `output.lint`: new defaults and detection order

Both options default to `false` in v5, so generation skips formatting and linting unless you opt in. In v4, `format` defaulted to `'prettier'` and `lint` to `'auto'`. The accepted values are unchanged (`'auto'`, `'prettier'`, `'biome'`, `'oxfmt'`, `false` for format; `'auto'`, `'eslint'`, `'biome'`, `'oxlint'`, `false` for lint), but the `'auto'` detection order now prefers the oxc tools first.

| Option          | v4 default   | v5 default | `'auto'` detection order                                                                 |
| --------------- | ------------ | ---------- | ---------------------------------------------------------------------------------------- |
| `output.format` | `'prettier'` | `false`    | [oxfmt](https://oxc.rs) → [biome](https://biomejs.dev) → [prettier](https://prettier.io) |
| `output.lint`   | `'auto'`     | `false`    | [oxlint](https://oxc.rs) → [biome](https://biomejs.dev) → [eslint](https://eslint.org)   |

### `output.barrelType` → `output.barrel`

The string `barrelType` option becomes an object `barrel` option with a `type` field. At the plugin level, a `nested` flag replaces the old `'propagate'` string.

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

v4 chose between a folder and a single file from the `output.path` extension. A path ending in `.ts` produced one file, anything else a folder. v5 drops that guess and asks you to state the layout with `output.mode`.

| `output.mode` | Layout                                                            |
| ------------- | ----------------------------------------------------------------- |
| `'directory'` | One file per operation or schema. The default.                    |
| `'file'`      | One file for the whole plugin.                                    |

To keep a single-file layout from v4, add `mode: 'file'`. The `output.path` must include the extension, because Kubb uses it as-is.

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

`mode: 'file'` forbids the `group` option, because a single file has nothing to group. Pairing them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error. To organize `'directory'` output into per-tag or per-path subfolders, keep `mode: 'directory'` and add the `group` option (covered next).

### Group folders use the plain tag

With `group: { type: 'tag' }`, every plugin now writes each tag to a folder named after the camelCased tag. v4 appended a `Controller` suffix (and `Requests` for the Cypress and MCP plugins), so `pet` operations landed in `petController/`. v5 drops the suffix and uses `pet/`. Nothing in the generated output referenced the suffix, so only the folder layout changes.

Your config stays the same. Only the output folders change:

```text [Output folders]
v4: src/gen/clients/petController/  →  v5: src/gen/clients/pet/
```

To keep the v4 layout, set `group.name` on the plugin:

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      group: { type: 'tag', name: ({ group }) => `${group}Controller` },
    }),
  ],
})
```

### Logging: `--debug` replaced by reporters

The `--debug` flag and the `debug` value of `--logLevel` are gone. v5 renders a run through reporters, picked on the CLI with `--reporter` (comma-separated) or in the config with `reporters`. The CLI flag wins when both are set. Three reporters ship built in:

| Reporter          | Output                                                                  |
| ----------------- | ----------------------------------------------------------------------- |
| `cli` _(default)_ | The end-of-run summary in the terminal.                                 |
| `json`            | A stable machine-readable report on stdout, for CI.                     |
| `file`            | A log written to `.kubb/kubb-<name>-<timestamp>.log`. This replaces `--debug`. |

```shell [Terminal]
kubb generate --debug # [!code --]
kubb generate --reporter file # [!code ++]
```

The `kubb:debug` hook and the `createDebugger` helper go away with the flag. See [`kubb generate`](/docs/5.x/api/commands/generate) for the full flag list and [Diagnostics](/docs/5.x/api/diagnostics) for the structured problem model the reporters render.

### `output.override` removed

The `output.override` boolean is gone, both on the root `output` and on each plugin's `output`. It was meant to skip files that already existed, but the v5 write path never read it, so it had no effect. Remove it from your config.

To keep certain files from being written, supply a custom [storage](/docs/5.x/guide/concepts/storage) that no-ops `setItem` for the paths you want to protect. The storage owns every write, so this is the single place that decides what lands on disk:

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb' // [!code --]
import { defineConfig } from 'kubb' // [!code ++]
import { fsStorage } from '@kubb/core' // [!code ++]

const base = fsStorage() // [!code ++]
const protectedPaths = ['src/gen/.kubb/client.ts'] // [!code ++]

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', override: false }, // [!code --]
  output: { path: './src/gen' }, // [!code ++]
  storage: { // [!code ++]
    ...base, // [!code ++]
    async setItem(path, source) { // [!code ++]
      if (protectedPaths.some((p) => path.endsWith(p))) return // [!code ++]
      return base.setItem(path, source) // [!code ++]
    }, // [!code ++]
  }, // [!code ++]
  plugins: [],
})
```

## Shared plugin API

These changes apply to every plugin that used `transformers` in v4.

### `transformers.name` → `resolver`

Typed [resolver](/docs/5.x/guide/concepts/plugins#resolvers) methods replace the single `transformers.name(name, type)` callback. Which method you use depends on the plugin:

| Plugin                                                                                                                                                                                                                                                                                                                                                    | Resolver method           |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts)                                                                                                                                                                                                                                                                                                                   | `resolveTypeName(name)`   |
| [`@kubb/plugin-zod`](/plugins/plugin-zod)                                                                                                                                                                                                                                                                                                                 | `resolveSchemaName(name)` |
| [`@kubb/plugin-axios`](/plugins/plugin-axios), [`@kubb/plugin-fetch`](/plugins/plugin-fetch), [`@kubb/plugin-react-query`](/plugins/plugin-react-query), [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query), [`@kubb/plugin-msw`](/plugins/plugin-msw), [`@kubb/plugin-faker`](/plugins/plugin-faker), [`@kubb/plugin-cypress`](/plugins/plugin-cypress), [`@kubb/plugin-mcp`](/plugins/plugin-mcp) | `resolveName(name)`       |

Inside a resolver method, `this` is bound to the full resolver, so `this.default(name, 'function')` falls back to the built-in logic.

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

Schema-level transformations move to [macros](/docs/5.x/guide/concepts/macros). Returning `null` or `undefined` from a macro callback falls back to the built-in behavior.

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

Code-generating plugins now accept a `printer` option that overrides individual AST node renderers. Use it in place of the removed `mapper` option for type-level customizations.

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

### `generators` removed

The `generators` plugin option is gone. It accepted an array of custom `Generator` objects that ran next to the built-in ones. To add custom output, build your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

## Multiple content types

When an OpenAPI operation declares multiple content types for its `requestBody`, v5 generates one type per content type plus a union alias. v4 used only the first content type.

```typescript [Generated output]
// plugin-ts output for an operation with application/json + multipart/form-data
export type UploadFileJsonData = { url: string }
export type UploadFileFormData = { file: Blob }
export type UploadFileData = UploadFileJsonData | UploadFileFormData
```

The generated client exposes `contentType` as a typed literal union, defaulting to the first declared content type:

```typescript [Generated output]
uploadFile({ path: { petId }, body }, { contentType: 'multipart/form-data' })
```

Single-content-type operations are unchanged.

## Per-extension changes

Each extension documents its own configuration changes on its own page. Open the one you use.

- [`@kubb/adapter-oas`](/docs/5.x/migration/adapter-oas)
- [`@kubb/plugin-ts`](/docs/5.x/migration/plugin-ts)
- [`@kubb/plugin-zod`](/docs/5.x/migration/plugin-zod)
- [`@kubb/plugin-faker`](/docs/5.x/migration/plugin-faker)
- [`@kubb/plugin-client` removed](/docs/5.x/migration/plugin-client): migrate to `@kubb/plugin-axios` or `@kubb/plugin-fetch`
- [`@kubb/plugin-react-query`](/docs/5.x/migration/plugin-react-query)
- [`@kubb/plugin-vue-query`](/docs/5.x/migration/plugin-vue-query)
- [`@kubb/plugin-msw`](/docs/5.x/migration/plugin-msw)
- [`@kubb/plugin-swr`](/docs/5.x/migration/plugin-swr)
- [`@kubb/plugin-cypress`](/docs/5.x/migration/plugin-cypress)
- [`@kubb/plugin-mcp`](/docs/5.x/migration/plugin-mcp)

The adapter page also covers the schema options that moved off the plugins. Each plugin page lists that extension's generated-output changes.

## Complete before/after example

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig, memoryStorage } from '@kubb/core'
import { pluginOas } from '@kubb/plugin-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'
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
    pluginAxios({
      output: { path: 'clients' },
    }),
    pluginReactQuery({
      output: { path: 'hooks' },
      client: 'axios',
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
import { pluginAxios } from '@kubb/plugin-axios'
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
    server: { index: 0 },
    discriminator: 'propagate',
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
    pluginAxios({
      output: { path: 'clients' },
    }),
    pluginReactQuery({
      output: { path: 'hooks' },
      client: 'axios',
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

- The banner (`/* Generated by Kubb */`) is controlled by [`output.defaultBanner`](/docs/5.x/api/configuration#output-defaultbanner) on the root config (default `'simple'`). Use [`output.banner`](/docs/5.x/api/configuration#output-banner) (and [`output.footer`](/docs/5.x/api/configuration#output-footer)) on individual plugins to override the text for one plugin's files. A string applies to every file. A function receives per-file context (`isBarrel`, `isAggregation`, `filePath`, `baseName`), which lets you skip the banner on re-export files, for example to add `'use server'` to source files but not to barrel or group aggregation files.
- Response status types now carry a `Status<code>` suffix.

The output changes specific to each generator live on its [per-extension page](#per-extension-changes).

## See also

- [Adapters](/docs/5.x/guide/concepts/adapters): how the OpenAPI input is parsed into the universal AST.
- [Plugins](/docs/5.x/guide/concepts/plugins): lifecycle, generators, and resolvers.
- [Parsers](/docs/5.x/guide/concepts/parsers): how AST nodes become source files.
- [Barrel files](/docs/5.x/guide/concepts/barrel-files): barrel file generation with `@kubb/plugin-barrel`.
- [Storage](/docs/5.x/guide/concepts/storage): switching between filesystem and in-memory storage.
- [`@kubb/adapter-oas`](/adapters/adapter-oas): every option that moved here from the plugins.
- [Plugin registry](/plugins): the full list of v5 plugins.
- [Recipes](/docs/5.x/guide/recipes): copy-paste configurations for common scenarios.
