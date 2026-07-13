---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-fetch.
outline: deep
---

# Options

Pass these options to `pluginFetch()` to control what it generates and where the files go.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'clients', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` | `false` | Validate request and response bodies with Zod |
| [`sdk`](#sdk) | `{ mode?: 'tag' \| 'flat'; name?: string }` | — | Generate a class-based SDK instead of functions |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverClient>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the plugin writes its generated `.ts` files and how it exports them.

#### output.path

Folder for the plugin's files, resolved against the global `output.path` on `defineConfig` and defaulting to `'clients'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

#### output.mode

How the plugin consolidates its code into files, either `'directory'` or `'file'`, defaulting to `'directory'`.

- `'directory'` writes one file per operation under `output.path`.
- `'file'` writes everything into a single file, so `output.path` must include the extension such as `'clients.ts'`.

`mode: 'file'` forbids the `group` option, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` barrel re-exports the plugin's output. It accepts `{ type: 'named' | 'all', nested?: boolean }` or `false`, defaulting to `{ type: 'named' }`.

- `{ type: 'named' }` re-exports each symbol by name, favoring tree-shaking.
- `{ type: 'all' }` uses `export *` for a smaller barrel that exports everything.
- `{ nested: true }` adds a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel and excludes the plugin's files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, for license headers or a `@ts-nocheck` directive. Pass a string, or a function that builds one from a `BannerMeta` object holding the document info and per-file context (`filePath`, `baseName`, `isBarrel`, `isAggregation`), so a directive such as `'use server'` can skip barrel files.

#### output.footer

Mirror of `banner` for closing comments such as re-enabling a lint rule, taking the same string or `BannerMeta` function. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a disable to the generated file.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each group under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'` and is not valid with `output.mode: 'file'`.

#### group.type

Property that assigns each operation to a group, required whenever `group` is set. Use `'tag'` for the operation's first tag, or `'path'` for the first segment of the operation's URL. An operation with no tag goes in the `default` group.

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name. It defaults to the camelCased tag for a `'tag'` group or the first path segment for a `'path'` group, and a `group.name` you pass always wins.

### baseURL

Base URL prepended to every request. When omitted, no host is prepended and each request uses the operation's relative path from the spec. A value containing a `${...}` interpolation is emitted as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable at runtime.

### validator

Runtime validator applied to request and response bodies using schemas from `@kubb/plugin-zod`, defaulting to `false`.

- `false` does no validation and returns the response cast to the generated type.
- `'zod'` validates the success response body, and the error body when a non-2xx call does not throw.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction, validating the request body before the call and the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`. With validation on the generated function throws a `ParseError` when a body fails its schema.

### sdk

Generates a class-based SDK instead of standalone functions, accepting `{ mode?: 'tag' | 'flat'; name?: string }`. Each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. Leave `sdk` unset to keep the per-operation functions that the query plugins consume.

`mode: 'tag'` (the default) emits one class per tag, such as `PetClient` and `StoreClient`. Set `sdk.name` alongside it to also emit a composed root class that instantiates every tag client from one shared config, reached as `new PetStore(config).pet.getPetById(...)`. `mode: 'flat'` emits a single class named by `sdk.name` with every operation as a direct method.

Construct a class with a client config, then call a method with the grouped options object (`{ path, query, headers, body }`). Each call resolves to `{ status, data, error, contentType, request, response }`. Because `throwOnError` defaults to `true`, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` to get the discriminated union instead, keyed on the top-level `status`:

```typescript
const { status, data, error } = await pet.getPetById({ path: { petId: 1 }, throwOnError: false })

if (status === 200) {
  console.log(data) // data is the success body, error is undefined
} else {
  console.error(status, error) // status is the documented error code, error is its parsed body
}
```

### include

Generates only the operations that match at least one entry. Each entry filters by one `type`:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'GET'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts a string for an exact match or a `RegExp` for fuzzy matches. Stack entries to narrow, such as a `method` `'GET'` entry with a `path` `/^\/pet/` entry.

### exclude

Skips any operation that matches at least one entry, the opposite of `include`. Entries use the same six `type` values and the same `pattern` (string or `RegExp`). When an operation matches both `include` and `exclude`, `exclude` wins.

### override

Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom, the first match merges onto the plugin defaults, and later entries do not stack. For example, `override: [{ type: 'tag', pattern: 'user', options: { validator: 'zod' } }]` turns on Zod validation for the `user` tag.

### resolver

Changes how the plugin names generated files and functions. Override only the methods you want to change, since anything you omit keeps its default. Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in name. For example, `resolver: { name(name) { return \`api${this.default.name(name)}\` } }` prefixes every generated function name with `api`. To change the AST nodes themselves, use `macros` instead. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context.

### macros

Rewrites AST nodes before they are printed to source. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default, and macros run in order so a later one sees the output of an earlier one.

```typescript [A macros array]
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({
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
