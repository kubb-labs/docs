---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-fetch.
outline: deep
---

# Options

Pass these options to `pluginFetch()` to control what it generates and where the files go.

## Options overview

Select an option to see its type, default, and examples. Nested settings link to their own section or the parent option.

| Option | Purpose |
| --- | --- |
| [`output`](#output) | Where the generated files are written and exported. |
| ↳ [`output.path`](#output-path) | Choose the output folder or file. |
| ↳ [`output.mode`](#output-mode) | Write a single file or a directory of files. |
| ↳ [`output.barrel`](#output-barrel) | Configure barrel exports. |
| ↳ [`output.barrel.type`](#output-barrel) | Use named exports or wildcard exports. |
| ↳ [`output.barrel.nested`](#output-barrel) | Choose whether barrels reference subdirectory barrels. |
| ↳ [`output.banner`](#output-banner) | Add content before generated code. |
| ↳ [`output.footer`](#output-footer) | Add content after generated code. |
| [`group`](#group) | Split output into per-tag or per-path folders. |
| ↳ [`group.type`](#group-type) | Group operations by tag or URL path. |
| ↳ [`group.name`](#group-name) | Customize output group names. |
| [`baseURL`](#baseurl) | Base URL prepended to every request. |
| [`throwOnErrorDefault`](#throwonerrordefault) | Default error behavior and return type for generated operations. |
| [`validator`](#validator) | Validate request and response bodies with Zod. |
| ↳ [`validator.request`](#validator) | Validate request bodies with Zod. |
| ↳ [`validator.response`](#validator) | Validate response bodies with Zod. |
| [`comments`](#comments) | How much of each description reaches the JSDoc. |
| [`sdk`](#sdk) | Generate a class-based SDK instead of functions. |
| ↳ [`sdk.mode`](#sdk) | Generate one SDK class per tag or a flat SDK. |
| ↳ [`sdk.name`](#sdk) | Name the composed or flat SDK class. |
| [`returnType`](#returntype) | Shape of the value a generated call resolves to. |
| [`include`](#include) | Keep only operations that match. |
| [`exclude`](#exclude) | Skip operations that match. |
| [`override`](#override) | Apply different options per pattern. |
| [`resolver`](#resolver) | Customize generated names and file paths. |
| [`macros`](#macros) | Rewrite AST nodes before printing. |

## Option details

### output

Where the plugin writes its generated `.ts` files and how it exports them.

| | |
| --- | --- |
| Type | `Output` |
| Required | `false` |
| Default | `{ path: 'clients', barrel: { type: 'named' } }` |

#### output.path

Folder for the plugin's files, resolved against the global `output.path` on `defineConfig` and defaulting to `'clients'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

#### output.mode

How the plugin consolidates its code into files, either `'file'` or `'directory'`.

- `'file'` writes everything into a single file, so `output.path` must include the extension (see above).
- `'directory'` writes one file per operation under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` requires directory output. Kubb infers the mode from `output.path`. Set `mode: 'directory'` to override that inference. Combining `group` with `mode: 'file'` stops generation with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

Split output into per-tag or per-path folders.

| | |
| --- | --- |
| Type | `Group` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name. It defaults to the camelCased tag for a `'tag'` group or the first path segment for a `'path'` group, and a `group.name` you pass always wins.

### baseURL

Base URL prepended to every request. When omitted, no host is prepended and each request uses the operation's relative path from the spec. A value containing a `${...}` interpolation is emitted as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable at runtime.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |

### throwOnErrorDefault

Set `throwOnErrorDefault: false` to return documented error responses as values by default. This sets the fallback on each generated request and the default `ThrowOnError` type parameter on standalone functions and SDK methods. A call with `throwOnError: true` still throws for a non-2xx response and narrows its return type to successful responses.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `true` |

```typescript
pluginFetch({ throwOnErrorDefault: false })

const result = await getPetById({ path: { petId: 1 } })
if (result.error) console.error(result.error)
```

This setting applies to the whole plugin and cannot be set in `override`. Generated operations use it even when the client config changes; pass `throwOnError` on a call to override it. Query hooks continue to set `throwOnError: true` explicitly.

### validator

Runtime validator applied to request and response bodies using schemas from `@kubb/plugin-zod`, defaulting to `false`.

| | |
| --- | --- |
| Type | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required | `false` |
| Default | `false` |

- `false` does no validation and returns the response cast to the generated type.
- `'zod'` validates the success response body, and the error body when a non-2xx call does not throw.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction, validating the request body before the call and the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`. With validation on the generated function throws a `ParseError` when a body fails its schema.

Add the schema plugin alongside the client. The following configuration validates both directions:

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginFetch({ validator: { request: 'zod', response: 'zod' } }),
  ],
})
```

### comments

Controls generated JSDoc. `'full'` (default) keeps complete descriptions. `'brief'` keeps the first sentence and other tags. Descriptions over 150 characters without a sentence ending are cut at the last word before 120. `'none'` omits JSDoc but keeps the generated-by banner.

| | |
| --- | --- |
| Type | `'full' \| 'brief' \| 'none'` |
| Required | `false` |
| Default | `'full'` |

### sdk

Generates a class-based SDK instead of standalone functions, accepting `{ mode?: 'tag' | 'flat'; name?: string }`. Each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. Leave `sdk` unset to keep the per-operation functions that the query plugins consume.

| | |
| --- | --- |
| Type | `{ mode?: 'tag' \| 'flat'; name?: string }` |
| Required | `false` |

`mode: 'tag'` (the default) emits one class per tag, such as `PetClient` and `StoreClient`. Set `sdk.name` alongside it to also emit a composed root class that instantiates every tag client from one shared config, reached as `new PetStore(config).pet.getPetById(...)`. `mode: 'flat'` emits a single class named by `sdk.name` with every operation as a direct method.

`mode: 'tag'` needs one file per tag, so pairing it with a single-file `output` (`output.mode: 'file'`, or an `output.path` that already names a file such as `'clients.ts'`) throws [`KUBB_INVALID_PLUGIN_OPTIONS`](/docs/5.x/reference/diagnostics#kubb-invalid-plugin-options). Use `mode: 'flat'` for a single-file SDK, or give `output.path` a directory so `mode: 'tag'` can split per tag.

```typescript [kubb.config.ts]
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ sdk: { mode: 'tag' } })
```

Construct a class with a client config, then call a method with the grouped options object (`{ path, query, headers, body }`). Each call resolves to `{ status, data, error, contentType, request, response }`. With the default `throwOnErrorDefault: true` setting, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` to get the discriminated union instead, keyed on the top-level `status`:

```typescript
import { PetClient } from './src/gen/clients/petClient'

const pet = new PetClient({ baseURL: 'https://petstore.swagger.io/v2' })
const { status, data, error } = await pet.getPetById({ path: { petId: 1 }, throwOnError: false })

if (status === 200) {
  console.log(data) // data is the success body, error is undefined
} else {
  console.error(status, error) // status is the documented error code, error is its parsed body
}
```

### returnType

Shape of the value a generated call resolves to. `'full'` (the default) keeps `{ status, data, error, contentType, request, response }`. `'data'` unwraps that down to the bare success body when `throwOnError` is `true`, and falls back to the full result when `throwOnError` is `false`, since that result still needs `error` to tell success from failure.

| | |
| --- | --- |
| Type | `'full' \| 'data'` |
| Required | `false` |
| Default | `'full'` |

```typescript
pluginFetch({ returnType: 'data' })
```

```typescript
const pet = await getPetById({ path: { petId: 1 } }) // Pet, not { status, data, ... }
```

This applies to the standalone functions and the class-based SDK. `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`, and `@kubb/plugin-mcp` read the same option, so their hooks and tool handlers give you the success body as `data` either way.

To read response headers such as `ETag` under `'data'`, pass `throwOnError: false` on the call. It then resolves to the full result, and a non-2xx comes back on `error` instead of throwing:

```typescript
const result = await getPetById({ path: { petId: 1 }, throwOnError: false })

if (result.error === undefined) {
  const etag = result.response.headers.get('etag')
}
```

Dependent plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`, and `@kubb/plugin-mcp`) also honor per-operation `returnType` set through [`override`](#override), so their generated hooks and handlers match the shape of the resolved `<op>`.

### include

Keep only operations that match.

| | |
| --- | --- |
| Type | `Array<Include>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

Skip operations that match.

| | |
| --- | --- |
| Type | `Array<Exclude>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

Apply different options per pattern.

| | |
| --- | --- |
| Type | `Array<Override>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverClient>` |
| Required | `false` |

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

| | |
| --- | --- |
| Type | `Array<Macro>` |
| Required | `false` |
