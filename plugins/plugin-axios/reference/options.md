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
| [`output`](#output) | `Output` | `{ path: 'clients', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` | `false` | Validate request and response bodies with Zod |
| [`sdk`](#sdk) | `{ mode?: 'tag' \| 'flat'; name?: string }` | — | Emit a class-based SDK instead of standalone functions |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverClient>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, defaulting to `'clients'` and resolved against the global `output.path` on `defineConfig`. For a single file, set `output.mode: 'file'` and give `path` a name with its extension, such as `'clients.ts'`.

#### output.mode

`'directory'` (the default) writes one file per operation under `output.path`. `'file'` writes everything into a single file whose `output.path` must include the extension, and it forbids `group`, which otherwise stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` re-exports the plugin's output, typed `{ type: 'named' | 'all', nested?: boolean } | false` and defaulting to `{ type: 'named' }`. `'named'` re-exports each symbol by name, `'all'` uses `export *`, `nested: true` adds a barrel in every subdirectory, and `false` skips the barrel and drops the plugin's files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, for headers or lint directives. Pass a string, or a function `(meta: BannerMeta) => string` that builds one from the document info (`title`, `description`, `version`, `baseURL`) and per-file context (`filePath`, `baseName`, `isBarrel`, `isAggregation`).

#### output.footer

Works like `banner` but appends to the bottom of every file, taking the same `string | ((meta: BannerMeta) => string)`. Use it for closing comments such as re-enabling a lint rule.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`, and applies only to `output.mode: 'directory'`. Without `group`, every file lands directly in `output.path`.

#### group.type

Property used to assign each operation to a group, required whenever `group` is set. `'tag'` uses the operation's first tag, `'path'` the first URL segment such as `pet` for `/pet/{petId}`, and an operation with no tag goes in the `default` group.

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

Generates only the operations that match at least one entry, skipping the rest. Each entry pairs a `pattern` (a string for an exact match, or a `RegExp`) with a `type` of `tag` (the first tag), `operationId`, `path`, `method`, `contentType`, or `schemaName` (a component under `#/components/schemas`), and entries stack to narrow further.

### exclude

Skips any operation that matches at least one entry, the opposite of `include`, using the same `type` and `pattern`. When both `include` and `exclude` match, `exclude` wins.

### override

Applies different plugin options to operations matching a pattern, for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom, and the first match wins. For example, `{ type: 'tag', pattern: 'user', options: { validator: 'zod' } }` turns on Zod validation for the `user` tag only.

### resolver

Changes how the plugin names generated files and functions, so you can add a prefix or suffix or swap the casing without forking the plugin. Override only the methods you want, and inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in name. The default is `resolverClient`, shared across the client plugins. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context.

### macros

Rewrites AST nodes before printing, to rename operation IDs or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (`schema`, `operation`, and so on) receives the node and a context object and returns a replacement node or `undefined` to keep it, and callbacks run in order. Use `resolver` instead to rename generated symbols and files.

```typescript
import { pluginAxios } from '@kubb/plugin-axios'

pluginAxios({
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
