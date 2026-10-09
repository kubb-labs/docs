---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-axios.
outline: deep
---

# Options

Pass these options to `pluginAxios()`. Shared options link to [Shared plugin options](/docs/5.x/reference/plugin-options), which documents their behavior once.

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`output`](/docs/5.x/reference/plugin-options#output) | Where the generated files are written and exported. | `{ path: 'clients', barrel: { type: 'named' } }` |
| ↳ [`output.path`](/docs/5.x/reference/plugin-options#output-path) | Choose the output folder or file. | `'clients'` |
| ↳ [`output.mode`](/docs/5.x/reference/plugin-options#output-mode) | Write a single file or a directory of files. | Inferred from `output.path` |
| ↳ [`output.barrel`](/docs/5.x/reference/plugin-options#output-barrel) | Configure barrel exports. | `{ type: 'named' }` |
| ↳ [`output.banner`](/docs/5.x/reference/plugin-options#output-banner) | Add content before generated code. | None |
| ↳ [`output.footer`](/docs/5.x/reference/plugin-options#output-footer) | Add content after generated code. | None |
| [`group`](/docs/5.x/reference/plugin-options#group) | Split output into per-tag or per-path folders. | None |
| ↳ [`group.type`](/docs/5.x/reference/plugin-options#group-type) | Group operations by tag or URL path. | Required with `group` |
| ↳ [`group.name`](/docs/5.x/reference/plugin-options#group-name) | Customize output group names. | camelCased tag or raw path segment |
| [`baseURL`](#baseurl) | Base URL prepended to every request. | None |
| [`throwOnErrorDefault`](#throwonerrordefault) | Default error behavior and return type for generated operations. | `true` |
| [`validator`](#validator) | Validate request and response bodies with Zod. | `false` |
| ↳ [`validator.request`](#validator) | Validate request bodies with Zod. | None |
| ↳ [`validator.response`](#validator) | Validate response bodies with Zod. | None |
| [`comments`](#comments) | How much of each description reaches the JSDoc. | `'full'` |
| [`sdk`](#sdk) | Emit a class-based SDK instead of standalone functions. | None |
| ↳ [`sdk.mode`](#sdk) | Generate one SDK class per tag or a flat SDK. | `'tag'` |
| ↳ [`sdk.name`](#sdk) | Name the composed or flat SDK class. | None |
| [`returnType`](#returntype) | Shape of the value a generated call resolves to. | `'full'` |
| [`include`](/docs/5.x/reference/plugin-options#include) | Keep only operations that match. | None |
| [`exclude`](/docs/5.x/reference/plugin-options#exclude) | Skip operations that match. | `[]` |
| [`override`](/docs/5.x/reference/plugin-options#override) | Apply different options per pattern. | `[]` |
| [`resolver`](#resolver) | Customize generated names and file paths. | `resolverClient` |
| [`macros`](/docs/5.x/reference/plugin-options#macros) | Rewrite AST nodes before printing. | `[]`, run after the built-in client macros |

## Option details

### baseURL

Base URL prepended to every request. When omitted, no host is prepended and each request uses the operation's relative path from the spec, with no server-URL fallback. A value containing a `${...}` interpolation is emitted as a template literal, so `baseURL: '${process.env.API_URL}'` reads the environment variable at runtime.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |

### throwOnErrorDefault

<!--@include: ../../../snippets/options/client-throw-on-error-default.md-->

### validator

Validates request and response bodies using schemas from `@kubb/plugin-zod`. Add `pluginZod()` when either direction uses `'zod'`. Invalid bodies cause the generated function to throw a `ParseError`.

| | |
| --- | --- |
| Type | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required | `false` |
| Default | `false` |

::field-group

:::field{name="false"}
Default value. Skips validation and casts the response to the generated type.
:::

:::field{name="'zod'"}
Validates the success response body and, when a non-2xx call does not throw, the error body.
:::

:::field{name="{ request?: 'zod', response?: 'zod' }"}
Enables validation separately for requests and responses.
:::

::

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginAxios({ validator: { request: 'zod', response: 'zod' } }),
  ],
})
```

### comments

<!--@include: ../../../snippets/options/client-comments.md-->

### sdk

Generates a class-based SDK. Each instance receives a client configuration, so environments can use separate clients. Leave `sdk` unset to keep the standalone functions used by query plugins.

| | |
| --- | --- |
| Type | `{ mode?: 'tag' \| 'flat'; name?: string }` |
| Required | `false` |

::field-group

:::field{name="'tag'"}
Default value for `sdk.mode`. Generates one class per tag, such as `PetClient` and `StoreClient`. Set `sdk.name` to also generate a root class that instantiates the tag clients from one shared configuration, used as `new PetStore(config).pet.getPetById(...)`.
:::

:::field{name="'flat'"}
Generates a single class named by `sdk.name`, with every operation as a direct method. Supports single-file output.
:::

::

`mode: 'tag'` needs one file per tag, so pairing it with a single-file `output` (`output.mode: 'file'`, or an `output.path` that already names a file such as `'clients.ts'`) throws [`KUBB_INVALID_PLUGIN_OPTIONS`](/docs/5.x/reference/diagnostics#kubb-invalid-plugin-options). Use `mode: 'flat'` for a single-file SDK, or give `output.path` a directory so `mode: 'tag'` can split per tag.

Construct a class with a `ClientConfig` (`baseURL`, `headers`, and so on), then call a method with the grouped options object (`{ path, query, headers, body }`). Each call resolves to `{ status, data, error, contentType, request, response }`. With the default `throwOnErrorDefault: true`, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` to get the discriminated union instead, keyed on the top-level `status`:

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

Shape of the value a generated call resolves to.

| | |
| --- | --- |
| Type | `'full' \| 'data'` |
| Required | `false` |
| Default | `'full'` |

::field-group

:::field{name="'full'"}
Default value. Returns `{ status, data, error, contentType, request, response }`.
:::

:::field{name="'data'"}
Returns the success body when `throwOnError` is `true`. With `throwOnError: false`, returns the full result so callers can distinguish errors from successful responses.
:::

::

```typescript
pluginAxios({ returnType: 'data' })

const pet = await getPetById({ path: { petId: 1 } }) // Pet, not { status, data, ... }
```

This applies to the standalone functions and the class-based SDK. `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`, and `@kubb/plugin-mcp` read the same option, so their hooks and tool handlers give you the success body as `data` either way. They also honor a per-operation `returnType` set through [`override`](/docs/5.x/reference/plugin-options#override).

To read response headers such as `ETag` under `'data'`, pass `throwOnError: false` on the call. It then resolves to the full result, and a non-2xx comes back on `error` instead of throwing:

```typescript
const result = await getPetById({ path: { petId: 1 }, throwOnError: false })

if (result.error === undefined) {
  const etag = result.response.headers.etag
}
```

### resolver

<!--@include: ../../../snippets/options/client-resolver.md-->

