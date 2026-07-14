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
| [`exclude`](#exclude) | `Array<Exclude>` | `[]` | Skip operations that match |
| [`override`](#override) | `Array<Override>` | `[]` | Apply different options per pattern |
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

> [!IMPORTANT]
> `mode: 'file'` forbids the `group` option, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` barrel re-exports the plugin's output. It accepts `{ type: 'named' | 'all', nested?: boolean }` or `false`, defaulting to `{ type: 'named' }`.

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

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverClient`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverClientPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  className?(name: string): string
  groupName?(name: string): string     // → 'PetClient'
  propertyName?(name: string): string
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
