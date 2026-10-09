---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-swr.
outline: deep
---

# Options

Configuration options for `@kubb/plugin-swr`, passed to `pluginSwr({ ... })`. Every field is optional.

::field-group

:::field{name="output" type="Output"}
Where the generated hooks are written and exported. [See details](#output).

Default: `{ path: 'hooks', barrel: { type: 'named' } }`.
:::

:::field{name="group" type="Group"}
Split output into per-tag or per-path folders. [See details](#group).

No default.
:::

:::field{name="client" type="'fetch' | 'axios'"}
Which registered client plugin the hooks call. [See details](#client).

No default.
:::

:::field{name="query" type="Partial<Query> | false"}
Configure the `useSWR` hooks, or turn them off. [See details](#query).

Default: `{ methods: ['GET'], importPath: 'swr' }`.
:::

:::field{name="queryKey" type="Transformer"}
Build the SWR key for each query hook. [See details](#querykey).

Default: `built-in`.
:::

:::field{name="mutation" type="Partial<Mutation> | false"}
Configure the `useSWRMutation` hooks, or turn them off. [See details](#mutation).

Default: `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], importPath: 'swr/mutation' }`.
:::

:::field{name="mutationKey" type="Transformer"}
Build the SWR key for each mutation hook. [See details](#mutationkey).

Default: `built-in`.
:::

:::field{name="include" type="Array<Include>"}
Keep only operations that match. [See details](#include).

No default.
:::

:::field{name="exclude" type="Array<Exclude>"}
Skip operations that match. [See details](#exclude).

Default: `[]`.
:::

:::field{name="override" type="Array<Override>"}
Apply different options per pattern. [See details](#override).

Default: `[]`.
:::

:::field{name="resolver" type="ResolverPatch<ResolverSwr>"}
Customize generated names and file paths. [See details](#resolver).

No default.
:::

:::field{name="macros" type="Array<Macro>"}
Rewrite AST nodes before printing. [See details](#macros).

No default.
:::

::

### output

Where the generated `.ts` files are written and how they are exported. Defaults to `{ path: 'hooks', barrel: { type: 'named' } }`.

#### output.path

Folder where the plugin writes its files (`string`, default `'hooks'`), resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'hooks.ts'`.

#### output.mode

How the plugin consolidates generated code (`'file' | 'directory'`). `'file'` writes everything into a single file whose `path` must include the extension. `'directory'` writes one file per operation under `output.path` and can be grouped into subdirectories. Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` requires directory output. Kubb infers the mode from `output.path`. Set `mode: 'directory'` to override that inference. Combining `group` with `mode: 'file'` stops generation with `KUBB_INVALID_PLUGIN_OPTIONS`.

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

Builds the SWR key for each query hook. The callback receives the operation `node`, the active `casing` and `variant: 'query'` and returns the key array, and the built-in transformer is used when unset. String values are inlined into generated code verbatim, so wrap any literal string in `JSON.stringify(...)`.

```typescript
queryKey: ({ node, variant }) => [JSON.stringify({ variant, operationId: node.operationId })]
```

### mutation

Configures the generated `useSWRMutation` hooks. Pass an object to change the HTTP methods or import path, or `false` to skip mutation hook generation. Defaults to `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], importPath: 'swr/mutation' }`.

#### mutation.methods

HTTP methods treated as mutations (`Array<string>`, default `['POST', 'PUT', 'PATCH', 'DELETE']`). An operation whose method is in this list generates a `useSWRMutation` hook instead of a query.

#### mutation.importPath

Module that `useSWRMutation` is imported from (`string`, default `'swr/mutation'`). The plugin emits `import useSWRMutation from '${importPath}'`. Relative and absolute paths are used as written, with relative paths resolved against the generated file.

### mutationKey

Builds the SWR key for each mutation hook. Like `queryKey`, the callback receives the operation `node`, the active `casing` and `variant: 'mutation'` and returns the key array, and the built-in transformer is used when unset. String values are inlined verbatim, so wrap any literal string in `JSON.stringify(...)`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

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
