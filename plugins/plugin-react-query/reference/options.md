---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-react-query.
outline: deep
---

# Options

Options for `pluginReactQuery`.

::field-group

:::field{name="output" type="Output"}
Where the generated hooks are written and exported. [See details](#output).

Default: `{ path: 'hooks', barrel: { type: 'named' } }`.
:::

:::field{name="group" type="Group"}
Split output into per-tag or per-path folders. [See details](#group).

No default.
:::

:::field{name="client" type="'axios' | 'fetch'"}
Which registered client plugin the hooks call. [See details](#client).

No default.
:::

:::field{name="infinite" type="Partial<Infinite> | false"}
Generate `useInfiniteQuery` hooks for pagination. [See details](#infinite).

Default: `false`.
:::

:::field{name="suspense" type="Partial<object> | false"}
Generate `useSuspenseQuery` hooks. [See details](#suspense).

Default: `false`.
:::

:::field{name="query" type="Partial<Query> | false"}
Configure the query hooks. [See details](#query).

Default: `{ methods: ['GET'], … }`.
:::

:::field{name="queryKey" type="(props) => unknown[]"}
Build the `queryKey` for each query hook. [See details](#querykey).

Default: `built-in`.
:::

:::field{name="mutation" type="Partial<Mutation> | false"}
Configure the mutation hooks. [See details](#mutation).

Default: `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], … }`.
:::

:::field{name="mutationKey" type="(props) => unknown[]"}
Build the `mutationKey` for each mutation hook. [See details](#mutationkey).

Default: `built-in`.
:::

:::field{name="customOptions" type="CustomOptions"}
Route every hook through your own options function. [See details](#customoptions).

No default.
:::

:::field{name="hooks" type="boolean"}
Emit `use*` hook functions on top of the factories. [See details](#hooks).

Default: `false`.
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

:::field{name="resolver" type="ResolverPatch<ResolverReactQuery>"}
Customize generated names and file paths. [See details](#resolver).

No default.
:::

:::field{name="macros" type="Array<Macro>"}
Rewrite AST nodes before printing. [See details](#macros).

No default.
:::

::

### output

Where the generated hooks are written and exported.

#### output.path

Folder for the plugin's files, resolved against the global `output.path` and defaulting to `'hooks'`. With `output.mode: 'file'`, use a filename like `'hooks.ts'`.

#### output.mode

`'file'` writes a single file whose `output.path` includes the extension, and cannot be combined with `group`. `'directory'` writes one file per operation. Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

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

Adds infinite-query output for pagination. Pass an object to configure the cursor, or `false` (the default) to skip. Emitted only for operations with a query parameter matching `infinite.queryParam`.

With [`hooks`](#hooks) at its default of `false`, setting `infinite` produces no file at all, not even the `infiniteQueryOptions` factory. Set `hooks: true` alongside `infinite` to generate the file and its `useInfiniteQuery` hook.

#### infinite.queryParam

Query parameter that carries the page cursor, defaulting to `'id'`.

#### infinite.initialPageParam

Initial value for `pageParam` on the first fetch, defaulting to `0`.

#### infinite.nextParam

Path to the next-page cursor, as dot notation (`'pagination.next.id'`) or array form. Defaults to `null`.

#### infinite.previousParam

Path to the previous-page cursor, in the same forms. Defaults to `null`.

### suspense

Adds a suspense variant alongside the regular query output. Pass an empty object (`{}`) to enable, or leave it as `false` (the default) to skip it. TanStack Query v5+ only.

With [`hooks`](#hooks) at its default of `false`, enabling `suspense` produces no file at all, not even the `suspenseQueryOptions` factory. Set `hooks: true` alongside `suspense` to generate the file and its `useSuspenseQuery` hook.

### query

Which operations become queries, emitting a `queryOptions` factory by default. Pass `false` to skip, or [`hooks`](#hooks) to also emit `useQuery`.

#### query.methods

HTTP methods treated as queries, defaulting to `['GET']`.

#### query.importPath

Module for the `queryOptions` import, defaulting to `'@tanstack/react-query'`.

### queryKey

Builds the `queryKey` for each hook from the operation `node`, `casing` and `variant`, defaulting to the built-in `queryKeyTransformer`. String values are inlined verbatim, so wrap literals in `JSON.stringify(...)`.

`variant` is the hook the key is built for: `'query'`, `'suspenseQuery'`, `'infiniteQuery'` or `'suspenseInfiniteQuery'`. The default key adds `infinite: true` for the infinite variants, because TanStack Query stores `InfiniteData` under an infinite key and the plain hook for the same request must not share it.

```typescript
queryKey: ({ node, variant }) => [JSON.stringify({ variant, operationId: node.operationId })]
```

### mutation

Which operations become mutations, emitting a `mutationOptions` factory by default. Set `false` to skip, or [`hooks`](#hooks) to also emit `useMutation`.

#### mutation.methods

HTTP methods treated as mutations, defaulting to `['POST', 'PUT', 'PATCH', 'DELETE']`.

#### mutation.importPath

Module for the `mutationOptions` import, defaulting to `'@tanstack/react-query'`.

### mutationKey

Builds the `mutationKey` for each mutation hook, for batched invalidations or `useMutationState`. Same props and string-inlining caveat as `queryKey`, with `variant` set to `'mutation'`, defaulting to the built-in `mutationKeyTransformer`.

### customOptions

Routes every hook through your own function that returns extra options such as `onSuccess` or `select`. Also emits a `HookOptions` type so your wrapper stays in sync.

#### customOptions.importPath

Module of your custom-options hook, imported as a named import. Required when `customOptions` is set.

#### customOptions.name

Exported name of your custom-options hook, defaulting to `'useCustomHookOptions'`.

### hooks

When `false` (the default), only the `query` and `mutation` factory helpers are written. Set `true` to also generate `useQuery`, `useSuspenseQuery`, `useInfiniteQuery`, `useSuspenseInfiniteQuery`, and `useMutation`.

[`suspense`](#suspense) and [`infinite`](#infinite) are gated on `hooks` too: with `hooks: false`, enabling either one writes nothing at all, not even the `suspenseQueryOptions` or `infiniteQueryOptions` factories.

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
