---
title: Migration guide
description: Step-by-step guide for migrating from Kubb v4 to v5.
layout: doc
outline: [2, 3]
---

# Migration guide: v4 → v5

Kubb v5 splits responsibilities across [adapters](/docs/5.x/guide/concepts/adapters), [plugins](/docs/5.x/guide/concepts/plugins), [parsers](/docs/5.x/guide/concepts/parsers), and [storage](/docs/5.x/guide/concepts/storage), so the upgrade is more than a version bump. The guide runs in upgrade order: [requirements](#before-you-start), packages, config, generated-code imports, then [verify](#verify-the-upgrade). Plugin-specific changes live on each [per-extension page](#per-extension-changes).

> [!TIP]
> In a hurry? Run the [upgrade prompt](#upgrade-prompt) against your config to migrate most of it automatically, then read on to verify the result.

## Before you start

### System requirements

| Version | v4   | v5   |
|---------| ---- | ---- |
| Node.js | ≥ 18 | ≥ 22 |

Update your CI pipelines, the `engines` field in `package.json`, and any `Dockerfile` `FROM node` lines. See [Installation](/docs/5.x/getting-started/installation) for the full setup.

### Install the v5 packages

In v4, the code-generating plugins lived in [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb). v5 moves them into [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins). The npm package names stay the same, so you do not need to rename anything. The infrastructure packages that `kubb` wires in for you, `@kubb/adapter-oas`, `@kubb/parser-ts`, `@kubb/parser-md`, and `@kubb/plugin-barrel`, stay in `kubb-labs/kubb`.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta @kubb/plugin-fetch@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta @kubb/plugin-fetch@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [npm]
npm install -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta @kubb/plugin-fetch@beta \
               @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
               @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
               @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta @kubb/plugin-zod@beta @kubb/plugin-axios@beta @kubb/plugin-fetch@beta \
            @kubb/plugin-react-query@beta @kubb/plugin-vue-query@beta @kubb/plugin-swr@beta \
            @kubb/plugin-faker@beta @kubb/plugin-msw@beta \
            @kubb/plugin-mcp@beta @kubb/plugin-cypress@beta @kubb/plugin-redoc@beta
```

:::

### Removed plugins

These plugins have no v5 equivalent. Remove them from your config and uninstall the packages.

| v4 package                  |
| --------------------------- |
| `@kubb/plugin-solid-query`  |
| `@kubb/plugin-svelte-query` |

## Pick your upgrade path

Two ways to migrate `kubb.config.ts`: run the automated prompt, or follow the manual checklist. Either way, [Migrate the config](#migrate-the-config) explains each change and [verify](#verify-the-upgrade) confirms the result.

### Automated: the upgrade prompt {#upgrade-prompt}

Copy the prompt below, paste it into any LLM ([Claude](https://claude.ai), [ChatGPT](https://chat.openai.com), [Gemini](https://gemini.google.com), …), and add your `kubb.config.ts` at the end.

::: details Expand upgrade prompt

```text [Upgrade prompt]
Migrate this kubb.config.ts from Kubb v4 to v5. Apply every rule, output the full updated file, and delete any import left unused after a removal.

Config:
1. Import `defineConfig` from `kubb/config`; if the config uses `memoryStorage`/`fsStorage`, import them from `kubb/kit`.
2. `input: { path }` / `input: { data }` → a single `input` value (path, URL, spec, or object).
3. `hooks.done` → `output.postGenerate` (array); drop top-level `hooks`. Move `output.storage` → top-level `storage`.
4. Remove `pluginOas()`; move its options to top-level `adapter: adapterOas({…})` from `@kubb/adapter-oas` (omit `adapter` if it had none — it defaults to `adapterOas()`). `serverIndex`/`serverVariables` → `server: { index, variables }`; `discriminator` `'strict'`→`'preserve'`, `'inherit'`→`'propagate'`.
5. Move onto `adapterOas` (one value each; if plugins disagreed, keep the value you want): `dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, `contentType`.

Output:
6. `output.barrelType` → `output.barrel`, at root and per plugin: `'named'`→`{type:'named'}`, `'all'`→`{type:'all'}`, `'propagate'`→`{type:'named',nested:true}`, `false`→`false`. v5 defaults `output.barrel` to `false`, so add `barrel:{type:'named'}` at the root if v4 relied on the old `'named'` default.
7. On each plugin, an `output.path` ending in `.ts` keeps the default `mode:'file'`; a folder path needs `mode:'directory'`. The root `output` takes no `mode`.
8. `output.format`/`output.lint` now default to `false` (were `'prettier'`/`'auto'`); keep any explicit value.

Remove `output.override` (root and per-plugin). Remove from every plugin: `generators`, `bundle`, `paramsType`, `pathParamsType`, `paramsCasing`, `dataReturnType`, `urlType`, `importPath`, `mapper` — and on plugin-swr also `mutation.paramsToTrigger`.

Plugins:
9. `transformers.name` → `resolver: { name(name) { … } }`, keeping your original logic and calling the plugin's exported resolver preset for the default casing (import it: `resolverTs` from `@kubb/plugin-ts`, `resolverZod` from `@kubb/plugin-zod`, …; `this.default.name` is the plain camelCase default). `transformers.schema` → `macros: [{ name: '<label>', schema(node) { … } }]` (name each macro).
10. plugin-zod: remove `version` and `typed`; drop `wrapOutput`, leaving a `// TODO: reintroduce wrapOutput via a printer override` comment; bump `zod` to `^4`.
11. Clients. `@kubb/plugin-client` is removed → `pluginAxios` (`@kubb/plugin-axios`, when old `client` was `'axios'`/unset) or `pluginFetch` (`@kubb/plugin-fetch`, when `'fetch'`), dropping `client`; `clientType: 'class'` → `sdk: {}` and `wrapper: { name }` → `sdk: { name }` (merge into one `sdk`). react-query/vue-query/swr/mcp no longer embed a client: if the v4 `client` was an object, register one `pluginAxios`/`pluginFetch` in `plugins[]` (shared by all consumers), move its `baseURL` there, and set `client: 'axios' | 'fetch'` on the query/mcp plugin (optional when only one client plugin is registered). On plugin-axios/plugin-fetch rename `parser` → `validator` (`false` | `'zod'` | `{ request, response }`; `'client'` → `false`); if a query plugin had `parser`, put `validator: 'zod'` on the client plugin. Leave plugin-msw `parser` (`'data'`/`'faker'`) unchanged.
12. Remove `pluginSolidQuery` (`@kubb/plugin-solid-query`) and `pluginSvelteQuery` (`@kubb/plugin-svelte-query`) — no v5 equivalent.
13. Keep every other option unchanged (group, include, exclude, override array, infinite, suspense, query, mutation, coercion, mini, seed, handlers, …).

Now migrate the following kubb.config.ts:
```

:::

### Manual: the quick-path checklist

The highest-impact edits, in order. Each step links to its full explanation below.

1. Bump Node to 22 and [install the v5 packages](#install-the-v5-packages) at `@beta`.
2. Change the import from `@kubb/core` to [`kubb/config`](#import-defineconfig-from-kubb-config).
3. Give [`input`](#give-input-a-single-value) a single value instead of `{ path }` / `{ data }`.
4. Remove `pluginOas()` and [move its options to `adapter: adapterOas(...)`](#kubb-plugin-oas-removed), along with the [schema options](#move-schema-options-to-the-adapter) that lived on each plugin.
5. Replace `pluginClient` with [`pluginAxios` or `pluginFetch`](/docs/5.x/migration/plugin-client), and point query and MCP plugins at a client with [`client: 'axios' | 'fetch'`](#client-becomes-a-selector).
6. Convert [`output.barrelType` to `output.barrel`](#output-barreltype-output-barrel), and add `barrel: { type: 'named' }` if you relied on the old default.
7. Add [`mode: 'directory'`](#set-output-mode-for-folder-output) to every plugin that writes a folder.
8. Replace [`transformers.name` with `resolver`](#transformersname-resolver) and [`transformers.schema` with `macros`](#transformersschema-macros); remove [`mapper`](#mapper-removed) and [`generators`](#generators-removed).
9. Move [`hooks.done` to `output.postGenerate`](#move-hooks-done-to-output-postgenerate) and [`storage`](#replace-output-override-with-storage) to the top level.
10. Bump the `zod` dependency to `^4` (see [Migration: @kubb/plugin-zod](/docs/5.x/migration/plugin-zod)).
11. Opt back into [formatting, linting](#formatting-and-linting-are-off-by-default), and a [barrel](#output-barreltype-output-barrel) if you want them, since all three now default to off.

## Defaults that changed

The most dangerous changes are the silent ones: options whose default flipped, so the same config produces different output. Each row links to the section with the full explanation and a before/after example.

| Option | v4 default | v5 default | Details |
| --- | --- | --- | --- |
| `output.format` | `'prettier'` | `false` | [Formatting and linting are off by default](#formatting-and-linting-are-off-by-default) |
| `output.lint` | `'auto'` | `false` | [Formatting and linting are off by default](#formatting-and-linting-are-off-by-default) |
| `output.barrel` (`barrelType` in v4) | `'named'` | `false` | [`output.barrelType` → `output.barrel`](#output-barreltype-output-barrel) |
| `output.mode` | Guessed from the `output.path` extension | `'file'` | [Set `output.mode` for folder output](#set-output-mode-for-folder-output) |
| `group: { type: 'tag' }` folder name | `<tag>Controller` | `<tag>` | [Group folders drop the `Controller` suffix](#group-folders-drop-the-controller-suffix) |
| `pluginReactQuery`/`pluginVueQuery` `hooks` | `true` | `false` | [`@kubb/plugin-react-query`](/docs/5.x/migration/plugin-react-query#hooks-defaults-to-false), [`@kubb/plugin-vue-query`](/docs/5.x/migration/plugin-vue-query#hooks-defaults-to-false) |
| `pluginAxios`/`pluginFetch` `throwOnError` | Errors returned on the result, never thrown | `true` | [`@kubb/plugin-client` removed](/docs/5.x/migration/plugin-client) |
| `adapterOas` `integerType` | `'number'` | `'bigint'` | [Move schema options to the adapter](#move-schema-options-to-the-adapter) |
| `pluginSwr` mutation trigger shape (`mutation.paramsToTrigger` in v4) | Off, option opt-in | Always on, option removed | [`@kubb/plugin-swr`](/docs/5.x/migration/plugin-swr) |

## Migrate the config

Every change to `kubb.config.ts`, grouped by the part of the config it touches. Work top to bottom.

### Import `defineConfig` from `kubb/config`

Import [`defineConfig`](/docs/5.x/reference/kit/engine#defineconfig) from the top-level `kubb` package. That package wires up the OpenAPI [adapter](/docs/5.x/guide/concepts/adapters), the TypeScript [parsers](/docs/5.x/guide/concepts/parsers), and the barrel [plugin](/plugins/plugin-barrel/) for you.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
```

:::

### Give `input` a single value

The two-shape `input` object collapses into a single value. Give `input` a file path, a URL, an inline spec, or a parsed object, and Kubb works out which one it is.

| v4 (old)                        | v5 (new)              |
| ------------------------------- | --------------------- |
| `input: { path: './api.yaml' }` | `input: './api.yaml'` |
| `input: { data: spec }`         | `input: spec`         |

```diff [kubb.config.ts]
export default defineConfig({
-  input: { path: './petstore.yaml' },
+  input: './petstore.yaml',
  output: { path: './src/gen' },
})
```

### Adopt the layered keys

v5 adds three top-level keys that replace behavior each plugin used to carry itself. Importing from `kubb` applies all three defaults, so set them only to change the defaults.

| Option       | Package                                                     | Purpose                                       | Default                 |
| ------------ | ----------------------------------------------------------- | --------------------------------------------- | ----------------------- |
| `adapter`    | [`@kubb/adapter-oas`](/adapters/adapter-oas/)                | Parses the input spec into a universal AST.   | `adapterOas()`          |
| `parsers`    | [`@kubb/parser-ts`](/parsers/parser-ts/), `@kubb/parser-md`  | Converts AST nodes to `.ts`, `.tsx`, and `.md` files. | `[parserTs(), parserTsx(), parserMd()]` |
| `plugins` (post) | [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) | Post-processes output, like barrel files.     | `[pluginBarrel()]`  |

### Move `pluginOas` options to the adapter {#kubb-plugin-oas-removed}

`pluginOas()` no longer belongs in `plugins`. Its options move to the top-level `adapter` key.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginOas } from '@kubb/plugin-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
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
import { defineConfig } from 'kubb/config'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
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

The `discriminator` values were also renamed: `'strict'` → `'preserve'` (now the default) and `'inherit'` → `'propagate'`.

> [!NOTE]
> Uninstall `@kubb/plugin-oas`. The `adapter` defaults to `adapterOas()` when importing from `kubb`, so the `adapter:` line is only required when you pass options.

### Move schema options to the adapter

Several schema-level options that v4 accepted on each plugin now live once on `adapterOas`: `dateType`, `integerType`, `unknownType`, and `emptySchemaType` (from plugin-ts, plugin-zod, plugin-faker), `enumSuffix` (plugin-ts), and `contentType` (plugin-ts, plugin-zod, plugin-msw). Remove them from every plugin and set them once on the adapter.

> [!IMPORTANT]
> The `integerType` default changed from `'number'` to `'bigint'`, so OpenAPI `int64` fields now map to `bigint`. Set `integerType: 'number'` on `adapterOas` to keep the old output.

The [adapter page](/docs/5.x/migration/adapter-oas) has the full table and before/after example.

### Formatting and linting are off by default

`output.format` and `output.lint` both default to `false` in v5, so generation skips formatting and linting unless you opt in (v4 defaulted `format` to `'prettier'` and `lint` to `'auto'`). The accepted values are unchanged (`'auto'`, `'prettier'`, `'biome'`, `'oxfmt'`, `false` for format; `'auto'`, `'eslint'`, `'biome'`, `'oxlint'`, `false` for lint), but `'auto'` now prefers the oxc tools first.

| Option          | v4 default   | v5 default | `'auto'` detection order                                                                 |
| --------------- | ------------ | ---------- | ---------------------------------------------------------------------------------------- |
| `output.format` | `'prettier'` | `false`    | [oxfmt](https://oxc.rs) → [biome](https://biomejs.dev) → [prettier](https://prettier.io) |
| `output.lint`   | `'auto'`     | `false`    | [oxlint](https://oxc.rs) → [biome](https://biomejs.dev) → [eslint](https://eslint.org)   |

### `output.barrelType` → `output.barrel` {#output-barreltype-output-barrel}

The string `barrelType` option becomes an object `barrel` option with a `type` field. At the plugin level, a `nested` flag replaces the old `'propagate'` string.

| v4 (old) `output.barrelType`  | v5 (new) `output.barrel`          |
| ----------------------------- | --------------------------------- |
| `'named'`                     | `{ type: 'named' }`               |
| `'all'`                       | `{ type: 'all' }`                 |
| `'propagate'` _(plugin only)_ | `{ type: 'named', nested: true }` |
| `false`                       | `false`                           |

> [!IMPORTANT]
> `output.barrel` also defaults to `false`, where v4's `barrelType` defaulted to `'named'`. If your v4 config relied on that default, add `output.barrel: { type: 'named' }` to keep the barrel, or drop it since each plugin's output is already directly importable.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen', barrelType: 'named' },
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
})
```

:::

The plugin-level `'propagate'` string becomes `{ type: 'named', nested: true }` on that plugin's own `output`:

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { barrelType: 'propagate' } })],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { barrel: { type: 'named', nested: true } } })],
})
```

:::

See [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) for the full `barrel` option reference.

### Set `output.mode` for folder output

v4 guessed the layout from the `output.path` extension: `.ts` meant one file, anything else a folder. v5 drops the guess, so state the layout with `output.mode`.

| `output.mode` | Layout                                                            |
| ------------- | ----------------------------------------------------------------- |
| `'file'`      | One file for the whole plugin. The default.                       |
| `'directory'` | One file per operation or schema.                                 |

A `.ts` `output.path` needs no change, since `mode: 'file'` is the default. A folder `output.path` needs `mode: 'directory'` added, or the output silently consolidates into one file.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'types' } })],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginTs({ output: { path: 'types', mode: 'directory' } })],
})
```

:::

`mode: 'file'` forbids `group`, since a single file has nothing to group, and pairing them stops the build with `KUBB_INVALID_PLUGIN_OPTIONS`. To organize `'directory'` output into per-tag or per-path subfolders, keep `mode: 'directory'` and add `group` (covered next).

### Group folders drop the `Controller` suffix

With `group: { type: 'tag' }`, each tag now writes to a folder named after the camelCased tag. v4 appended a `Controller` suffix (`Requests` for Cypress and MCP), so `pet` operations landed in `petController/`. v5 uses `pet/`. Nothing referenced the suffix, so only the folder layout changes.

Your config stays the same. Only the output folders change:

```text [Output folders]
v4: src/gen/clients/petController/  →  v5: src/gen/clients/pet/
```

To keep the v4 layout, set `group.name` on the plugin:

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petstore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      output: { mode: 'directory' },
      group: { type: 'tag', name: ({ group }) => `${group}Controller` },
    }),
  ],
})
```

`group` requires `output.mode: 'directory'`, since v5 now defaults to `'file'`.

### Replace `output.override` with storage

The `output.override` boolean is gone from the root and every plugin's `output`. It was meant to skip existing files, but v5 never read it, so remove it.

To keep certain files from being written, and to move `storage` from `output.storage` to the top-level `storage` key, supply a custom [storage](/docs/5.x/guide/concepts/storage) that no-ops `setItem` for the paths you protect:

```diff [kubb.config.ts]
 import { defineConfig } from 'kubb/config'
+import { fsStorage } from 'kubb/kit'

+const base = fsStorage()
+const protectedPaths = ['src/gen/.kubb/client.ts']

export default defineConfig({
  input: './petStore.yaml',
-  output: { path: './src/gen', override: false },
+  output: { path: './src/gen' },
+  storage: {
+    ...base,
+    async setItem(path, source) {
+      if (protectedPaths.some((p) => path.endsWith(p))) return
+      return base.setItem(path, source)
+    },
+  },
  plugins: [],
})
```

Import `memoryStorage` and `fsStorage` from `kubb/kit`, not `@kubb/core`.

### Move `hooks.done` to `output.postGenerate`

The top-level `hooks` option is gone. Move its `done` commands into [`output.postGenerate`](/docs/5.x/reference/configuration#output-postgenerate). A single string becomes a one-item array, and `{ name, command }` labels a step in the CLI output. The failure diagnostic is renamed `KUBB_HOOK_FAILED` → `KUBB_POST_GENERATE_FAILED`.

```diff [kubb.config.ts]
export default defineConfig({
  input: './petstore.yaml',
  output: {
    path: './src/gen',
+    postGenerate: ['npm run typecheck'],
  },
-  hooks: {
-    done: ['npm run typecheck'],
-  },
})
```

### `--debug` becomes reporters

The `--debug` flag and the `debug` value of `--logLevel` are gone. v5 renders a run through reporters. The `--reporter` flag (comma-separated) selects which run, defaulting to `cli`, and the config `reporters` key registers the ones available. `defineConfig` registers the three built-ins for you.

| Reporter          | Output                                                                  |
| ----------------- | ----------------------------------------------------------------------- |
| `cli` _(default)_ | The end-of-run summary in the terminal.                                 |
| `json`            | A stable machine-readable report on stdout, for CI.                     |
| `file`            | A log written to `.kubb/kubb-<name>-<timestamp>.log`. This replaces `--debug`. |

```diff [Terminal]
-kubb generate --debug
+kubb generate --reporter file
```

The `kubb:debug` hook and the `createDebugger` helper go away with the flag. See [`kubb generate`](/docs/5.x/reference/commands/generate) for the full flag list and [Diagnostics](/docs/5.x/reference/diagnostics) for the structured problem model the reporters render.

## Update the shared plugin API

These changes apply to every plugin that used `transformers` in v4, plus the way query and MCP plugins reach a client.

### `transformers.name` becomes `resolver` {#transformersname-resolver}

A typed [resolver](/docs/5.x/guide/concepts/resolvers) replaces the single `transformers.name(name, type)` callback. Every plugin exposes a top-level `name(name)` method that sets identifier casing, so `resolver: { name(name) { … } }` is the shape for [`@kubb/plugin-ts`](/plugins/plugin-ts/), [`@kubb/plugin-zod`](/plugins/plugin-zod/), [`@kubb/plugin-axios`](/plugins/plugin-axios/), [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), [`@kubb/plugin-react-query`](/plugins/plugin-react-query/), [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/), [`@kubb/plugin-swr`](/plugins/plugin-swr/), [`@kubb/plugin-msw`](/plugins/plugin-msw/), [`@kubb/plugin-faker`](/plugins/plugin-faker/), [`@kubb/plugin-cypress`](/plugins/plugin-cypress/), and [`@kubb/plugin-mcp`](/plugins/plugin-mcp/). Plugins that emit multiple symbols per operation add more resolver methods, listed on each plugin's reference page.

Call the plugin's exported preset (`resolverTs.name`, `resolverZod.name`, and so on) to keep the default casing. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for renaming and relocating generated files.

After porting a `transformers.name` callback, verify the generated identifiers: a v5 resolver can receive a differently-cased input than v4, so a custom transform may produce different names.

::: code-group

```typescript [v4]
pluginTs({
  transformers: {
    name: (name) => `Api${name}`,
  },
})
```

```typescript twoslash [v5]
import { pluginTs, resolverTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    name(name) {
      return `Api${resolverTs.name(name)}`
    },
  },
})
```

:::

### `transformers.schema` becomes `macros` {#transformersschema-macros}

Schema-level transformations move to [macros](/docs/5.x/guide/going-further/macros).

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

### `mapper` is removed {#mapper-removed}

The `mapper` option is gone from every code-generating plugin. Override a node renderer with the `printer` option or rewrite nodes with [`macros`](#transformersschema-macros) instead. See [Override a printer](/docs/5.x/guide/going-further/printers).

### `generators` is removed {#generators-removed}

The `generators` plugin option is gone. To add custom output, build your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

### Query and MCP plugins select a client {#client-becomes-a-selector}

In v4, the `client` option on `pluginReactQuery`, `pluginVueQuery`, `pluginSwr`, and `pluginMcp` was an object that configured a bundled client (`clientType`, `dataReturnType`, `baseURL`, `bundle`, `importPath`). In v5 those plugins call a registered client plugin instead, so `client` is a single string that names it: `'axios'` or `'fetch'`. Register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), set `baseURL` there, and point `client` at it. The client plugin returns the response body, so the generated code reads `res.data` and there is no `dataReturnType`. When exactly one client plugin is registered, Kubb auto-detects it and the string is optional. Each plugin's page shows the before/after for its own config.

## Per-extension changes

Open the page for each extension you use. The table lists the headline change so you can tell at a glance whether a plugin needs work.

| Extension | Headline change |
| --- | --- |
| [`@kubb/adapter-oas`](/docs/5.x/migration/adapter-oas) | Schema options moved here; `integerType` default is now `'bigint'`; `discriminator` values renamed. |
| [`@kubb/plugin-ts`](/docs/5.x/migration/plugin-ts) | Request params grouped into one `*Options` object; `enum` options restructured; `mapper`/`paramsCasing` removed. |
| [`@kubb/plugin-zod`](/docs/5.x/migration/plugin-zod) | Zod v4 only; `typed` → `inferred`; `wrapOutput`/`operations`/`mapper` removed; response schema names gain a `Status<code>` segment. |
| [`@kubb/plugin-faker`](/docs/5.x/migration/plugin-faker) | `paramsCasing`/`mapper` removed; `createX` is now generic over its return type. |
| [`@kubb/plugin-client`](/docs/5.x/migration/plugin-client) _(removed)_ | Migrate to `@kubb/plugin-axios` or `@kubb/plugin-fetch`; `clientType` → `sdk`; `parser` → `validator`; `throwOnError` defaults to `true`. |
| [`@kubb/plugin-react-query`](/docs/5.x/migration/plugin-react-query) | `client` is a string selector; `hooks` defaults to `false`; params grouped; `parser` removed. |
| [`@kubb/plugin-vue-query`](/docs/5.x/migration/plugin-vue-query) | Same as react-query, with hook arguments wrapped in `MaybeRefOrGetter`. |
| [`@kubb/plugin-swr`](/docs/5.x/migration/plugin-swr) | `client` is a string selector; `mutation.paramsToTrigger` removed; requests key off `shouldFetch`. |
| [`@kubb/plugin-msw`](/docs/5.x/migration/plugin-msw) | No config changes; handlers are typed against the request body and headers. |
| [`@kubb/plugin-cypress`](/docs/5.x/migration/plugin-cypress) | Request params grouped into one `*Options` object; `dataReturnType` removed; HTTP methods uppercased. |
| [`@kubb/plugin-mcp`](/docs/5.x/migration/plugin-mcp) | `client` is a string selector; now depends on `plugin-ts` and `plugin-zod`; `paramsCasing` removed. |

## Generated output

v5 also changes what the generators emit, so update code that imports the generated files. Two changes apply to every generator:

- The banner (`/* Generated by Kubb */`) is set by [`output.defaultBanner`](/docs/5.x/reference/configuration#output-defaultbanner) on the root config (default `'simple'`). Override it per plugin with [`output.banner`](/docs/5.x/reference/configuration#output-banner) and [`output.footer`](/docs/5.x/reference/configuration#output-footer), each taking a string or a per-file function.
- Response status types now carry a `Status<code>` suffix.

Operations that declare more than one `requestBody` content type now generate one type per content type plus a union alias, and the generated client takes a typed `contentType` argument. v4 used only the first content type, so single-content-type operations are unchanged.

The output changes specific to each generator live on its [per-extension page](#per-extension-changes).

## Complete before/after example

A realistic multi-plugin config. Expand it to see every change from this guide applied together.

:::: details Show the full v4 → v5 config

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
  input: './petstore.yaml',
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
      dateType: 'date', // → adapterOas
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
import { defineConfig } from 'kubb/config'
import { memoryStorage } from 'kubb/kit'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs, resolverTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: './petstore.yaml',
  output: {
    path: './src/gen',
    format: 'prettier',
    barrel: { type: 'named' },
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
      output: { path: 'types', mode: 'directory' },
      resolver: {
        name(name) {
          return `Api${resolverTs.name(name)}`
        },
      },
    }),
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
    }),
    pluginAxios({
      output: { path: 'clients', mode: 'directory' },
    }),
    pluginReactQuery({
      output: { path: 'hooks', mode: 'directory' },
      client: 'axios',
    }),
    pluginFaker({
      output: { path: 'mocks', mode: 'directory' },
    }),
  ],
})
```

:::

::::

Every plugin adds `mode: 'directory'` to keep v4's one-file-per-operation layout. Omit it to consolidate into a single file, the v5 default. The root `output.barrel` is set explicitly to keep v4's barrel.

## Verify the upgrade

Once the config compiles, confirm the output:

- Run `kubb generate` and review the diff against your previous output.
- Type-check the generated code, and wire that check into [`output.postGenerate`](#move-hooks-done-to-output-postgenerate) so it runs on every generate.
- Watch for a `KUBB_INVALID_PLUGIN_OPTIONS` error, which usually means a plugin pairs `mode: 'file'` with `group`.
- Update imports of renamed symbols: response types now carry a `Status<code>` suffix, and Zod inferred types end in `Type`.

## Performance

v5 generates code faster than v4, and the gap widens as the spec grows. The numbers below come from
[`scripts/benchmark/v4-vs-v5`](https://github.com/kubb-labs/kubb/tree/main/scripts/benchmark/v4-vs-v5)
in the kubb repository, a harness anyone can run and reproduce. It benchmarks `@kubb/core@4.39.2`
against the v5 beta (`@kubb/core@5.0.0-beta.104`, plugins at `5.0.0-beta.103`), median of three runs
per configuration, both versions writing to a fresh directory so the comparison stays apples-to-apples.

<SpeedComparison />

> [!NOTE]
> Measured on the CI runner that generated this page. Absolute milliseconds and megabytes are
> hardware-dependent. Treat the speedup and memory-reduction percentages as the portable takeaway.

**`petStore.yaml`**, 21 operations

| Plugins                                                      | v4 time | v5 time | Speedup   | v4 memory | v5 memory | Memory     |
| ------------------------------------------------------------- | ------- | ------- | --------- | --------- | --------- | ---------- |
| `plugin-ts`                                                    | 579 ms  | 345 ms  | **+68%**  | 13.0 MB   | 23.4 MB   | -80%       |
| `plugin-ts` + `plugin-axios`                                   | 630 ms  | 384 ms  | **+64%**  | 15.8 MB   | 24.5 MB   | -55%       |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`   | 954 ms  | 398 ms  | **+140%** | 19.5 MB   | 25.1 MB   | -29%       |

**`twitter.json`**, 80 operations, 374 KB

| Plugins                                                      | v4 time  | v5 time  | Speedup    | v4 memory | v5 memory | Memory |
| ------------------------------------------------------------- | -------- | -------- | ---------- | --------- | --------- | ------ |
| `plugin-ts`                                                    | 2,993 ms | 1,071 ms | **+179%**  | 110.6 MB  | 60.2 MB   | **+46%** |
| `plugin-ts` + `plugin-axios`                                   | 3,560 ms | 1,160 ms | **+207%**  | 115.5 MB  | 59.7 MB   | **+48%** |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`   | 5,928 ms | 1,674 ms | **+254%**  | 179.3 MB  | 68.5 MB   | **+62%** |

**`openai.yaml`**, 281 operations, 2.7 MB ([openai/openai-openapi](https://github.com/openai/openai-openapi))

| Plugins                                                      | v4 time   | v5 time  | Speedup    | v4 memory | v5 memory | Memory |
| ------------------------------------------------------------- | --------- | -------- | ---------- | --------- | --------- | ------ |
| `plugin-ts`                                                    | 14,775 ms | 3,600 ms | **+310%**  | 442.4 MB  | 146.3 MB  | **+67%** |
| `plugin-ts` + `plugin-axios`                                   | 16,611 ms | 3,891 ms | **+327%**  | 501.8 MB  | 148.0 MB  | **+70%** |
| `plugin-ts` + `plugin-axios` + `plugin-zod` + `plugin-faker`   | 31,205 ms | 5,887 ms | **+430%**  | 898.0 MB  | 149.3 MB  | **+83%** |

The gap widens on bigger specs. In v4, every plugin bootstrapped its own `pluginOas` instance, so
parsing ran once per plugin. In v5, `adapterOas` parses the spec once and shares the result across
all plugins, which is why memory stays close to flat for v5 as the spec grows while v4's climbs with
every additional plugin.

Memory is more nuanced than speed. On the small `petStore.yaml` spec, v5 actually uses more memory
than v4. The shared adapter and its AST layer carry fixed overhead that a 21-operation spec is too
small to amortize. That overhead shrinks in relative terms as the spec grows: at 80 operations, v5
already uses less memory than v4, and by 281 operations v5 holds a roughly flat memory footprint
while v4's grows linearly with the plugin count. The memory savings compound alongside the speed
gains.

The `openai.yaml` operation count above reflects the spec's current size, and will keep growing since
the harness fetches it live from the upstream repository. Re-running the benchmark later means
comparing against a bigger spec than this page shows, which is expected.

## See also

- [Adapters](/docs/5.x/guide/concepts/adapters): how the OpenAPI input is parsed into the universal AST.
- [Plugins](/docs/5.x/guide/concepts/plugins): lifecycle, generators, and resolvers.
- [Parsers](/docs/5.x/guide/concepts/parsers): how AST nodes become source files.
- [Override a resolver](/docs/5.x/guide/going-further/resolvers): rename symbols and files through the `resolver` option.
- [Override a printer](/docs/5.x/guide/going-further/printers): change the code a plugin emits for a schema type.
- [Barrel files](/docs/5.x/guide/going-further/barrel-files): barrel file generation with `@kubb/plugin-barrel`.
- [Storage](/docs/5.x/guide/concepts/storage): switching between filesystem and in-memory storage.
- [`@kubb/adapter-oas`](/adapters/adapter-oas/): every option that moved here from the plugins.
- [Plugin registry](/plugins): the full list of v5 plugins.
- [Recipes](/docs/5.x/guide/recipes): copy-paste configurations for common scenarios.
