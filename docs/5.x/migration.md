---
title: Migration guide
description: Step-by-step guide for migrating from Kubb v4 to v5, ordered the way you upgrade: requirements, packages, config, the shared plugin API, per-extension changes, and generated output, with verified before/after examples.
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
You are migrating a kubb.config.ts from Kubb v4 to v5. Apply every rule, then output the complete updated file.

1. Import: `import { defineConfig } from '@kubb/core'` → `from 'kubb/config'`.
2. Remove `pluginOas()` from `plugins[]`; move its options to a top-level `adapter: adapterOas({ … })` from `@kubb/adapter-oas`. `serverIndex`/`serverVariables` → `server: { index, variables }`; `discriminator` `'strict'`→`'preserve'`, `'inherit'`→`'propagate'`; `validate`/`contentType` unchanged. Omit `adapter` if `pluginOas` had no options.
3. Move these schema options off every plugin onto `adapterOas()`: `dateType`, `integerType`, `unknownType`, `emptySchemaType` (ts/zod/faker), `enumSuffix` (ts), `contentType` (ts/msw).
4. `transformers.name` → `resolver: { name(name) { return … } }` (call an exported preset such as `resolverTs.name(name)` to wrap its casing; `this.default.name(name)` always uses the core `camelCase` default).
5. `transformers.schema` → `macros: [{ name, schema(node) { return … } }]`.
6. Remove `mapper` from plugin-ts, plugin-zod, plugin-faker.
7. plugin-zod: remove `version` and `typed`; drop `wrapOutput` and leave a `// TODO: reintroduce wrapOutput via a printer override` comment (do not invent a `printer`). Bump the `zod` package to `^4` in package.json (a dependency change, not a config option).
8. `output.barrelType` → `output.barrel`, root and per-plugin: `'named'`→`{ type: 'named' }`, `'all'`→`{ type: 'all' }`, `'propagate'`→`{ type: 'named', nested: true }`, `false`→`false`. If a v4 config never set `barrelType` (relying on its `'named'` default), add `barrel: { type: 'named' }` explicitly, since v5 defaults `output.barrel` to `false`.
9. If a plugin's `output.path` ends in `.ts`, keep the extension (`mode: 'file'` is now the default, so stating it is optional but fine). Folder paths need `mode: 'directory'` added explicitly, since `'directory'` is no longer the default.
10. Remove entirely from every plugin: `generators`, `bundle`, `output.override` (boolean, root and per-plugin), `paramsType`, `pathParamsType`, `paramsCasing`, `dataReturnType`, `clientType` (except on `pluginClient`, handled by rule 15), `urlType`, `importPath`.
11. `input: { path }` / `input: { data }` → a single `input` value (file path, URL, inline spec, or parsed object).
12. `hooks.done` → `output.postGenerate` (array); remove the top-level `hooks`.
13. Move `storage` from `output.storage` to a top-level `storage`, and import `memoryStorage`/`fsStorage` from `kubb/kit` (not `@kubb/core`).
14. On plugin-axios/plugin-fetch rename `parser` → `validator` (`false` | `'zod'` | `{ request, response }`); `parser: 'client'` → `false`. On plugin-react-query/plugin-vue-query/plugin-swr delete `parser` and put `validator: 'zod'` on the client plugin. Leave plugin-msw `parser` (`'data'`/`'faker'`) unchanged.
15. `@kubb/plugin-client` is removed: replace `pluginClient()` with `pluginAxios` (`@kubb/plugin-axios`) when its old `client` was `'axios'` or unset, or `pluginFetch` (`@kubb/plugin-fetch`) when `'fetch'`; drop `client`. `clientType: 'class'` (+ `wrapper`) → `sdk`. Query/mcp plugins select a client via `client: 'axios' | 'fetch'`.
16. Remove these plugins and their imports (no v5 equivalent): `pluginSolidQuery` (`@kubb/plugin-solid-query`), `pluginSvelteQuery` (`@kubb/plugin-svelte-query`).
17. Keep every other option unchanged (group, include, exclude, override array, client, infinite, suspense, query, mutation, baseURL, coercion, mini, seed, handlers, …).

Informational, do not edit the config: v5 defaults `output.format` and `output.lint` to `false` (were `'prettier'`/`'auto'`), and `group: { type: 'tag' }` folders drop the `Controller` suffix.

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

To keep certain files from being written, and to move `storage` from `output.storage` to the top-level `storage` key, supply a custom [storage](/docs/5.x/guide/concepts/storage) that no-ops `setItem` for the paths you protect. Storage owns every write, so it is the single place that decides what lands on disk:

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

A typed [resolver](/docs/5.x/guide/concepts/resolvers) replaces the single `transformers.name(name, type)` callback. Every plugin exposes a top-level `name(name)` method that sets identifier casing, so `resolver: { name(name) { … } }` is the shape for [`@kubb/plugin-ts`](/plugins/plugin-ts/), [`@kubb/plugin-zod`](/plugins/plugin-zod/), [`@kubb/plugin-axios`](/plugins/plugin-axios/), [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), [`@kubb/plugin-react-query`](/plugins/plugin-react-query/), [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/), [`@kubb/plugin-swr`](/plugins/plugin-swr/), [`@kubb/plugin-msw`](/plugins/plugin-msw/), [`@kubb/plugin-faker`](/plugins/plugin-faker/), [`@kubb/plugin-cypress`](/plugins/plugin-cypress/), and [`@kubb/plugin-mcp`](/plugins/plugin-mcp/). Plugins that emit more than one symbol per operation add namespaced methods on top, such as `response.status` or `query.name`, documented on each plugin's reference page.

Resolver methods bind `this` to the full resolver. `this.default.name(name)` always applies Kubb's core `camelCase` default, not the plugin preset's casing, so call an exported preset like `resolverTs.name(name)` to wrap that preset. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for renaming or relocating files through `file.baseName` and `file.path`.

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

Schema-level transformations move to [macros](/docs/5.x/guide/going-further/macros). Returning `null` or `undefined` from a macro callback falls back to the built-in behavior.

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

The `mapper` option is gone from every code-generating plugin. Override individual AST node renderers with the `printer` option for type-level customizations, or rewrite nodes with [`macros`](#transformersschema-macros). See [Override a printer](/docs/5.x/guide/going-further/printers) for the handler context.

```typescript [v5]
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

### `generators` is removed {#generators-removed}

The `generators` plugin option is gone. It accepted an array of custom `Generator` objects that ran next to the built-in ones. To add custom output, build your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

### Query and MCP plugins select a client {#client-becomes-a-selector}

In v4, the `client` option on `pluginReactQuery`, `pluginVueQuery`, `pluginSwr`, and `pluginMcp` was an object that configured a bundled client (`clientType`, `dataReturnType`, `baseURL`, `bundle`, `importPath`). In v5 those plugins call a registered client plugin instead, so `client` is a single string that names it: `'axios'` or `'fetch'`. Register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), set `baseURL` there, and point `client` at it. When exactly one client plugin is registered, Kubb auto-detects it and the string is optional. Each plugin's page shows the before/after for its own config.

## What hasn't changed

Leave these as they are. The npm package names are the same, so no renames in `package.json` beyond the version bump. `adapterOas` still validates by default. plugin-msw keeps its `parser` (`'data'`/`'faker'`). And these options carry over untouched: `group`, `include`, `exclude`, the array form of `override`, `client`, `infinite`, `suspense`, `query`, `mutation`, `baseURL`, `coercion`, `mini`, `seed`, and `handlers`.

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

- The banner (`/* Generated by Kubb */`) is set by [`output.defaultBanner`](/docs/5.x/reference/configuration#output-defaultbanner) on the root config (default `'simple'`). Override it per plugin with [`output.banner`](/docs/5.x/reference/configuration#output-banner) and [`output.footer`](/docs/5.x/reference/configuration#output-footer): a string applies to every file, while a function receives per-file context (`isBarrel`, `isAggregation`, `filePath`, `baseName`) so you can skip re-export files, for example adding `'use server'` to source files but not barrels.
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

## Plugin authoring

For people who write custom plugins, generators, or resolvers. Application configs can skip this section.

### Authoring imports moved to `kubb/kit` {#authoring-imports-moved-to-kubb-kit}

The helpers for authoring plugins, generators, resolvers, parsers, and adapters now live in the `kubb/kit` subpath. In v4 they were spread across `@kubb/core` (`definePlugin`), `@kubb/ast` (visitors, factory functions, guards), and `@kubb/plugin-oas` (`createGenerator`, `createReactGenerator`).

The AST helpers move onto the `ast` namespace. Reach them through `kubb/kit` as `ast.extractRefName` and friends. You no longer import `@kubb/ast` directly, and its async `walk` visitor is gone: use `ast.collect` for inspection passes and `ast.transform` for rewrites.

::: code-group

```typescript twoslash [before]
import { definePlugin } from '@kubb/core'
import { collect, transform, walk } from '@kubb/ast'
import { createReactGenerator } from '@kubb/plugin-oas'
```

```typescript twoslash [after]
import { ast, definePlugin, defineGenerator } from 'kubb/kit'
```

:::

See [Kit](/docs/5.x/guide/concepts/kit) and the [Kit reference](/docs/5.x/reference/kit), which also covers the full AST surface.

## Performance

v5 generates code faster than v4. The benchmarks compare `@kubb/core@4.37.8` with the v5 `kubb` meta-package, with file writing disabled so the numbers reflect the generation pipeline alone.

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
