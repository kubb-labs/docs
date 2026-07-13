---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'cypress', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverCypress>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'cypress.ts'`).

> [!IMPORTANT]
> Pairing `mode: 'file'` with the `group` option stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error, since a single file has nothing to group.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

- `{ type: 'named' }` re-exports each symbol by name, best for tree-shaking.
- `{ type: 'all' }` uses `export *` to re-export everything.
- `{ nested: true }` creates a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel entirely, and excludes the plugin's files from the root `index.ts`.

```typescript ['named' (default)]
// src/gen/cypress/index.ts
export { getPetById } from './getPetById'
export { addPet } from './addPet'
```

#### output.banner

Text added to the top of every generated file, such as license headers, lint disables, or a `@ts-nocheck` directive. Pass a string, or a function that receives a `BannerMeta` object (document info `title`, `description`, `version`, `baseURL` plus per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`) and returns the text, so a directive such as `'use server'` can skip barrel files.

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. Only applies to `output.mode: 'directory'` (the default).

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

#### group.name

Function that turns a group key into a folder name, used as the subdirectory under `output.path`. By default the key is the camelCased tag, or the first path segment for `'path'` groups.

### baseURL

Base URL prepended to every request in the generated helpers. When omitted, no host is prepended and each helper uses the operation's relative path from the spec. Set it to point the helpers at a different environment, such as staging or production.

```typescript [baseURL: 'https://staging.petstore.dev']
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `https://staging.petstore.dev/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'GET'`.
- `contentType`: the request or response media type.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

Pass `include: [{ type: 'tag', pattern: 'pet' }]` to keep only the `pet` tag.

### exclude

Skips any operation that matches at least one entry, the opposite of `include`. Entries use the same `type` and `pattern` fields, and when an operation matches both `include` and `exclude`, `exclude` wins.

Pass `exclude: [{ type: 'tag', pattern: 'store' }]` to drop the `store` tag.

### override

Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom, and the first match merges onto the plugin defaults while later entries do not stack.

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

For example, `override: [{ type: 'tag', pattern: 'user', options: { baseURL: 'https://users.petstore.dev' } }]` points the `user` tag at a different host.

### resolver

Changes how the plugin names generated files and symbols, for example to add a prefix or suffix or swap the casing. Override only the methods you want, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so `this.default.name(name)` reuses the built-in name.

> [!TIP]
> For changing the AST nodes themselves instead of names, use `macros`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context.

For example, `resolver: { name(name) { return \`api${this.default.name(name)}\` } }` prefixes every generated helper name with `api`.

### macros

Rewrites AST nodes before printing, for example to rename operation IDs or drop descriptions. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object and returns a replacement, or `undefined` to keep it. Omitted callbacks keep their defaults, and macros run in order so a later one sees an earlier one's output.

```typescript [A macros array]
import { pluginCypress } from '@kubb/plugin-cypress'

pluginCypress({
  macros: [
    {
      name: 'prefix-operation-id',
      operation(node) {
        return { ...node, operationId: `api_${node.operationId}` }
      },
    },
  ],
})
```
