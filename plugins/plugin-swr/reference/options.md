---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-swr.
outline: deep
---

# Options

Configuration options for `@kubb/plugin-swr`, passed to `pluginSwr({ ... })`. Every field is optional.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'hooks', barrel: { type: 'named' } }` | Where the generated hooks are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'fetch' \| 'axios'` | — | Which registered client plugin the hooks call |
| [`query`](#query) | `Partial<Query> \| false` | `{ methods: ['GET'], importPath: 'swr' }` | Configure the `useSWR` hooks, or turn them off |
| [`queryKey`](#querykey) | `Transformer` | `built-in` | Build the SWR key for each query hook |
| [`mutation`](#mutation) | `Partial<Mutation> \| false` | `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], importPath: 'swr/mutation' }` | Configure the `useSWRMutation` hooks, or turn them off |
| [`mutationKey`](#mutationkey) | `Transformer` | `built-in` | Build the SWR key for each mutation hook |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverSwr>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported. Defaults to `{ path: 'hooks', barrel: { type: 'named' } }`.

#### output.path

Folder where the plugin writes its files (`string`, default `'hooks'`), resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'hooks.ts'`.

#### output.mode

How the plugin consolidates generated code (`'file' | 'directory'`, default `'file'`). The default writes everything into a single file whose `path` must include the extension. `'directory'` writes one file per operation under `output.path` and can be grouped into subdirectories.

> [!IMPORTANT]
> `group` requires `mode: 'directory'`. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) fails the build with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function that turns a group key into a folder or identifier name, used as the subdirectory name and as a suffix when naming aggregate files. Defaults to `({ group }) => camelCase(group)`, except `type: 'path'` groups use the first URL segment as-is.

### client

Selects which registered client plugin the generated hooks call (`'fetch' | 'axios'`). `'fetch'` calls the `@kubb/plugin-fetch` functions and `'axios'` the `@kubb/plugin-axios` functions, both through one grouped `options` object. A client plugin must be registered. When only one is registered it is auto-detected, so `client` is only needed to disambiguate several.

### query

Configures the generated `useSWR` hooks. Pass an object to change the HTTP methods or import path, or `false` to skip query hook generation. Defaults to `{ methods: ['GET'], importPath: 'swr' }`.

#### query.methods

HTTP methods treated as queries (`Array<string>`, default `['GET']`). An operation whose method is in this list generates a `useSWR` hook instead of a mutation.

#### query.importPath

Module that `useSWR` is imported from (`string`, default `'swr'`). The plugin emits `import useSWR from '${importPath}'`. Relative and absolute paths are used as written, with relative paths resolved against the generated file.

### queryKey

Builds the SWR key for each query hook. The callback receives the operation `node` and the active `casing` and returns the key array, and the built-in transformer is used when unset. String values are inlined into generated code verbatim, so wrap any literal string in `JSON.stringify(...)`.

### mutation

Configures the generated `useSWRMutation` hooks. Pass an object to change the HTTP methods or import path, or `false` to skip mutation hook generation. Defaults to `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], importPath: 'swr/mutation' }`.

#### mutation.methods

HTTP methods treated as mutations (`Array<string>`, default `['POST', 'PUT', 'PATCH', 'DELETE']`). An operation whose method is in this list generates a `useSWRMutation` hook instead of a query.

#### mutation.importPath

Module that `useSWRMutation` is imported from (`string`, default `'swr/mutation'`). The plugin emits `import useSWRMutation from '${importPath}'`. Relative and absolute paths are used as written, with relative paths resolved against the generated file.

### mutationKey

Builds the SWR key for each mutation hook. Like `queryKey`, the callback receives the operation `node` and the active `casing` and returns the key array, and the built-in transformer is used when unset. String values are inlined verbatim, so wrap any literal string in `JSON.stringify(...)`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverSwr`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverSwrPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  query?: {
    name?(node: OperationNode): string         // → 'useGetPetById'
    optionsName?(node: OperationNode): string  // → 'getPetByIdQueryOptions'
    keyName?(node: OperationNode): string       // → 'getPetByIdQueryKey'
    keyTypeName?(node: OperationNode): string   // → 'GetPetByIdQueryKey'
    clientName?(node: OperationNode): string    // → 'getPetById'
  }
  mutation?: {
    name?(node: OperationNode): string          // → 'useUpdatePet'
    keyName?(node: OperationNode): string        // → 'updatePetMutationKey'
    keyTypeName?(node: OperationNode): string    // → 'UpdatePetMutationKey'
    argTypeName?(node: OperationNode): string    // → 'UpdatePetMutationArg'
  }
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
