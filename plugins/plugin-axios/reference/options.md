---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-axios.
outline: deep
---

# Options

Options for `@kubb/plugin-axios`, which generates a type-safe HTTP client pinned to axios.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'clients' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` | `false` | Validate request and response bodies with Zod |
| [`sdk`](#sdk) | `{ mode?: 'tag' \| 'flat'; name?: string }` | — | Emit a class-based SDK instead of standalone functions |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | `[]` | Skip operations that match |
| [`override`](#override) | `Array<Override>` | `[]` | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverClient>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, defaulting to `'clients'` and resolved against the global `output.path` on `defineConfig`. For a single file, set `output.mode: 'file'` and give `path` a name with its extension, such as `'clients.ts'`.

#### output.mode

`'file'` (the default) writes everything into a single file whose `output.path` must include the extension. `'directory'` writes one file per operation under `output.path`.

> [!IMPORTANT]
> `group` requires `mode: 'directory'`. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name and wins over the default, which camelCases the tag or uses the first path segment.

### baseURL

Base URL prepended to every request. When omitted, no host is prepended and each request uses the operation's relative path from the spec, with no server-URL fallback. A value containing a `${...}` interpolation is emitted as a template literal, so `baseURL: '${process.env.API_URL}'` reads the environment variable at runtime.

### validator

Validates request and response bodies with schemas from `@kubb/plugin-zod`, which you add to the plugins list when either direction is `'zod'`. `false` (the default) skips validation and returns the response cast to the generated type. `'zod'` validates the success response body, plus the error body when a non-2xx call does not throw. `{ request?: 'zod', response?: 'zod' }` opts in per direction, and with validation on the generated function throws a `ParseError` on invalid data.

### sdk

Generates a class-based SDK instead of standalone functions, where each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. `mode: 'tag'` (the default) emits one class per tag such as `PetClient` and `StoreClient`. Add `sdk.name` to also emit a composed root that instantiates every tag client from one shared config, reached as `new PetStore(config).pet.getPetById(...)`. `mode: 'flat'` emits a single class named by `sdk.name` with every operation as a direct method. Leave `sdk` unset to keep the per-operation functions the query plugins consume.

Construct a class with a `ClientConfig` (`baseURL`, `headers`, and so on), then call a method with the grouped options object (`{ path, query, headers, body }`) and read `data` off the result.

```typescript
import { PetClient } from './src/gen/clients/petClient'

const pet = new PetClient({ baseURL: 'https://petstore.swagger.io/v2' })
const { data } = await pet.getPetById({ path: { petId: 1 } })
```

Each call resolves to `{ status, data, error, contentType, request, response }`. Because `throwOnError` defaults to `true`, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` to get the discriminated union instead, keyed on the top-level `status`.

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
