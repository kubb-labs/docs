---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-react-query.
outline: deep
---

# Options

Options for `pluginReactQuery`, with type and default in the table.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'hooks', barrel: { type: 'named' } }` | Where the generated hooks are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'axios' \| 'fetch'` | — | Which registered client plugin the hooks call |
| [`infinite`](#infinite) | `Partial<Infinite> \| false` | `false` | Generate `useInfiniteQuery` hooks for pagination |
| [`suspense`](#suspense) | `Partial<object> \| false` | `{}` | Generate `useSuspenseQuery` hooks |
| [`query`](#query) | `Partial<Query> \| false` | `{ methods: ['GET'], … }` | Configure the query hooks |
| [`queryKey`](#querykey) | `(props) => unknown[]` | `built-in` | Build the `queryKey` for each query hook |
| [`mutation`](#mutation) | `Partial<Mutation> \| false` | `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], … }` | Configure the mutation hooks |
| [`mutationKey`](#mutationkey) | `(props) => unknown[]` | `built-in` | Build the `mutationKey` for each mutation hook |
| [`customOptions`](#customoptions) | `CustomOptions` | — | Route every hook through your own options function |
| [`hooks`](#hooks) | `boolean` | `false` | Emit `use*` hook functions on top of the factories |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverReactQuery>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated hooks are written and exported.

#### output.path

Folder for the plugin's files, resolved against the global `output.path` and defaulting to `'hooks'`. With `output.mode: 'file'`, use a filename like `'hooks.ts'`.

#### output.mode

`'directory'` (the default) writes one file per operation. `'file'` writes a single file whose `output.path` includes the extension, and cannot be combined with `group`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Turns a group key into a folder name, defaulting to the camelCased tag, or the first URL segment for `path` groups.

### client

Which registered client plugin the hooks call, `'axios'` or `'fetch'`. When omitted, a single registered client plugin is auto-detected, so it is only needed to disambiguate several.

> [!NOTE]
> The hooks call a client plugin's functions, so register `@kubb/plugin-axios` or `@kubb/plugin-fetch` alongside this one.

### infinite

Adds infinite-query output for pagination. Pass an object to configure the cursor, or `false` (the default) to skip. Emitted only for operations with a query parameter matching `infinite.queryParam`, and [`hooks`](#hooks) wraps it in `useInfiniteQuery`.

#### infinite.queryParam

Query parameter that carries the page cursor, defaulting to `'id'`.

#### infinite.initialPageParam

Initial value for `pageParam` on the first fetch, defaulting to `0`.

#### infinite.nextParam

Path to the next-page cursor, as dot notation (`'pagination.next.id'`) or array form. Defaults to `null`.

#### infinite.previousParam

Path to the previous-page cursor, in the same forms. Defaults to `null`.

### suspense

Adds a suspense variant alongside the regular query output, on by default. Set `false` to skip it, or [`hooks`](#hooks) to wrap it in `useSuspenseQuery`. TanStack Query v5+ only.

### query

Which operations become queries, emitting a `queryOptions` factory by default. Pass `false` to skip, or [`hooks`](#hooks) to also emit `useQuery`.

#### query.methods

HTTP methods treated as queries, defaulting to `['GET']`.

#### query.importPath

Module for the `queryOptions` import, defaulting to `'@tanstack/react-query'`.

### queryKey

Builds the `queryKey` for each hook from the operation `node` and `casing`, defaulting to the built-in `queryKeyTransformer`. String values are inlined verbatim, so wrap literals in `JSON.stringify(...)`.

### mutation

Which operations become mutations, emitting a `mutationOptions` factory by default. Set `false` to skip, or [`hooks`](#hooks) to also emit `useMutation`.

#### mutation.methods

HTTP methods treated as mutations, defaulting to `['POST', 'PUT', 'PATCH', 'DELETE']`.

#### mutation.importPath

Module for the `mutationOptions` import, defaulting to `'@tanstack/react-query'`.

### mutationKey

Builds the `mutationKey` for each mutation hook, for batched invalidations or `useMutationState`. Same props and string-inlining caveat as `queryKey`, defaulting to the built-in `mutationKeyTransformer`.

### customOptions

Routes every hook through your own function that returns extra options such as `onSuccess` or `select`. Also emits a `HookOptions` type so your wrapper stays in sync.

#### customOptions.importPath

Module of your custom-options hook, imported as a named import. Required when `customOptions` is set.

#### customOptions.name

Exported name of your custom-options hook, defaulting to `'useCustomHookOptions'`.

### hooks

When `false` (the default), only the adapter-portable factory helpers are written. Set `true` to also generate `useQuery`, `useSuspenseQuery`, `useInfiniteQuery`, `useSuspenseInfiniteQuery`, and `useMutation`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverReactQuery`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverReactQueryPatch = {
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
  suspenseQuery?: { /* same members as query */ }
  infiniteQuery?: { /* same members as query */ }
  suspenseInfiniteQuery?: { /* same members as query */ }
  mutation?: {
    name?(node: OperationNode): string          // → 'useUpdatePet'
    optionsName?(node: OperationNode): string
    keyName?(node: OperationNode): string
    typeName?(node: OperationNode): string      // → 'UpdatePet'
  }
  hook?: {
    optionsName?(): string
    customOptionsName?(): string
  }
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
