---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-msw.
outline: deep
---

# Options

Every option below is a key on `pluginMsw({ ... })`.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'handlers', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every handler's request |
| [`handlers`](#handlers) | `boolean` | `false` | Emit a `handlers.ts` that re-exports every handler |
| [`parser`](#parser) | `'data' \| 'faker'` | `'data'` | Source of the response body each handler returns |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverMsw>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated handler files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig` and defaulting to `'handlers'`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'handlers.ts'`.

#### output.mode

How the plugin consolidates its generated code into files. `'directory'` (the default) writes one file per operation under `output.path`. `'file'` writes everything into a single file, so `output.path` must include the extension. Pair `'directory'` with `group` to organize output into subdirectories.

> [!IMPORTANT]
> `mode: 'file'` forbids `group` and stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` barrel re-exports the plugin's output, defaulting to `{ type: 'named' }`. Use `{ type: 'named' }` to re-export each symbol by name for better tree-shaking, `{ type: 'all' }` for a smaller `export *` barrel, `{ nested: true }` to add a barrel in every subdirectory, or `false` to skip the barrel and drop these files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, useful for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string, or a function that builds the text from a `BannerMeta` object carrying the document info (`title`, `description`, `version`, `baseURL`) plus the per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`, so a directive such as `'use server'` can skip barrel files.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, taking the same string or `BannerMeta` function. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'`.

#### group.type

Property used to assign each operation to a group, required whenever `group` is set. `'tag'` uses the operation's first tag and `'path'` uses the first URL segment, such as `pet` for `/pet/{petId}`. An operation with no tag goes in the `default` group.

#### group.name

Function that turns a group key into the subdirectory name, used also as a suffix when naming aggregate files. It defaults to `({ group }) => camelCase(group)` for tag groups, while `type: 'path'` groups use the first URL segment as-is.

### baseURL

Base URL prepended to every handler's request. When omitted, no host is prepended and each handler matches the operation's relative path from the spec. Set it to point at a different environment than the spec.

### handlers

Emits a `handlers.ts` file that re-exports every generated handler in operation order. Spread it into your MSW `setupServer(...handlers)` or `setupWorker(...handlers)` call.

```typescript [gen/handlers.ts]
import { getPetHandler } from './getPetHandler'
import { addPetHandler } from './addPetHandler'

export const handlers = [getPetHandler(), addPetHandler()] as const
```

### parser

Source of the response body each handler returns. `'data'` (the default) returns a typed payload from `@kubb/plugin-ts` that you fill in from tests, so the handler body is `new Response(JSON.stringify(data), ...)`. `'faker'` falls back to a value built by `@kubb/plugin-faker` when you pass no data. Register `pluginFaker()` in the plugins array, since the plugin depends on Faker only for this value.

```typescript ['faker']
export function getPetHandler(data?: GetPetQueryResponse | ((info: Parameters<Parameters<typeof http.get>[1]>[0]) => Response | Promise<Response>)) {
  return http.get(`/pet/:petId`, function handler(info) {
    if (typeof data === 'function') return data(info)

    return new Response(JSON.stringify(data || getPetQueryResponse(data)), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols, for a prefix, suffix, or casing change without forking the plugin. Override only the methods you want, since anything you omit keeps its default behavior. Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in name. The default suffixes every handler with `Handler` and names the aggregate export `handlers`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for how a patch layers over the plugin default.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
