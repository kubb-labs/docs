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
| [`throwOnErrorDefault`](#throwonerrordefault) | `boolean` | `true` | Default error behavior and return type for generated operations |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` | `false` | Validate request and response bodies with Zod |
| [`comments`](#comments) | `'full' \| 'brief' \| 'none'` | `'full'` | How much of each description reaches the JSDoc |
| [`sdk`](#sdk) | `{ mode?: 'tag' \| 'flat'; name?: string }` | — | Generate a class-based SDK instead of functions |
| [`returnType`](#returntype) | `'full' \| 'data'` | `'full'` | Shape of the value a generated call resolves to |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | `[]` | Skip operations that match |
| [`override`](#override) | `Array<Override>` | `[]` | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverClient>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the plugin writes its generated `.ts` files and how it exports them.

#### output.path

Folder for the plugin's files, resolved against the global `output.path` on `defineConfig` and defaulting to `'clients'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

#### output.mode

How the plugin consolidates its code into files, either `'file'` or `'directory'`.

- `'file'` writes everything into a single file, so `output.path` must include the extension (see above).
- `'directory'` writes one file per operation under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` works with the inferred directory mode, no `mode` needed. Set `mode: 'directory'` yourself only to override the inference, such as a directory name that carries a dot (`path: 'clients.v2'`). An explicit `mode: 'file'` still forbids `group` and stops the build with `KUBB_INVALID_PLUGIN_OPTIONS`, since a single file has nothing to group.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name. It defaults to the camelCased tag for a `'tag'` group or the first path segment for a `'path'` group, and a `group.name` you pass always wins.

### baseURL

Base URL prepended to every request. When omitted, no host is prepended and each request uses the operation's relative path from the spec. A value containing a `${...}` interpolation is emitted as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable at runtime.

### throwOnErrorDefault

Set `throwOnErrorDefault: false` to return documented error responses as values by default. This sets the fallback on each generated request and the default `ThrowOnError` type parameter on standalone functions and SDK methods. A call with `throwOnError: true` still throws for a non-2xx response and narrows its return type to successful responses.

```typescript
pluginFetch({ throwOnErrorDefault: false })

const result = await getPetById({ path: { petId: 1 } })
if (result.error) console.error(result.error)
```

This setting applies to the whole plugin and cannot be set in `override`. Generated operations use it even when the client config changes; pass `throwOnError` on a call to override it. Query hooks continue to set `throwOnError: true` explicitly.

### validator

Runtime validator applied to request and response bodies using schemas from `@kubb/plugin-zod`, defaulting to `false`.

- `false` does no validation and returns the response cast to the generated type.
- `'zod'` validates the success response body, and the error body when a non-2xx call does not throw.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction, validating the request body before the call and the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`. With validation on the generated function throws a `ParseError` when a body fails its schema.

### comments

How much of each OpenAPI `description` reaches the JSDoc above each generated operation. Defaults to `'full'`, which emits every description in full, however many paragraphs the spec carries. `'brief'` keeps the opening sentence and leaves every other tag such as `@summary` and the `{@link}` in place, cutting a description that runs on for 150 characters without a sentence ending at the last word before 120. `'none'` emits no JSDoc, leaving the generated-by banner untouched. Descriptions are a third of the output on a large spec, so pick `'brief'` or `'none'` when file size matters more than editor hovers.

### sdk

Generates a class-based SDK instead of standalone functions, accepting `{ mode?: 'tag' | 'flat'; name?: string }`. Each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. Leave `sdk` unset to keep the per-operation functions that the query plugins consume.

`mode: 'tag'` (the default) emits one class per tag, such as `PetClient` and `StoreClient`. Set `sdk.name` alongside it to also emit a composed root class that instantiates every tag client from one shared config, reached as `new PetStore(config).pet.getPetById(...)`. `mode: 'flat'` emits a single class named by `sdk.name` with every operation as a direct method.

Construct a class with a client config, then call a method with the grouped options object (`{ path, query, headers, body }`). Each call resolves to `{ status, data, error, contentType, request, response }`. With the default `throwOnErrorDefault: true` setting, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` to get the discriminated union instead, keyed on the top-level `status`:

```typescript
const { status, data, error } = await pet.getPetById({ path: { petId: 1 }, throwOnError: false })

if (status === 200) {
  console.log(data) // data is the success body, error is undefined
} else {
  console.error(status, error) // status is the documented error code, error is its parsed body
}
```

### returnType

Shape of the value a generated call resolves to. `'full'` (the default) keeps `{ status, data, error, contentType, request, response }`. `'data'` unwraps that down to the bare success body when `throwOnError` is `true`, and falls back to the full result when `throwOnError` is `false`, since that result still needs `error` to tell success from failure.

```typescript
pluginFetch({ returnType: 'data' })
```

```typescript
const pet = await getPetById({ path: { petId: 1 } }) // Pet, not { status, data, ... }
```

This applies to the standalone functions and the class-based SDK. `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-swr` read the same option, so their hooks give you the success body as `data` either way.

To read response headers such as `ETag` under `'data'`, pass `throwOnError: false` on the call. It then resolves to the full result, and a non-2xx comes back on `error` instead of throwing:

```typescript
const result = await getPetById({ path: { petId: 1 }, throwOnError: false })

if (result.error === undefined) {
  const etag = result.response.headers.get('etag')
}
```

Dependent plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`, and `@kubb/plugin-mcp`) also honor per-operation `returnType` set through [`override`](#override), so their generated hooks and handlers match the shape of the resolved `<op>`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols by accepting a partial patch. Override only the members you want, and anything you omit keeps `resolverClient`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

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
