---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-vue-query.
outline: deep
---

# Options

Options for `@kubb/plugin-vue-query`, which generates TanStack Vue Query composables from an OpenAPI spec.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'hooks' }` | Where the generated composables are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'axios' \| 'fetch'` | — | Which registered client plugin the composables call |
| [`infinite`](#infinite) | `Partial<Infinite> \| false` | `false` | Add `useInfiniteQuery` composables for paginated reads |
| [`query`](#query) | `Partial<Query> \| false` | `{ methods: ['GET'], … }` | Configure or disable query composables |
| [`queryKey`](#querykey) | `(props) => Array<unknown>` | `built-in` | Build the `queryKey` for each query composable |
| [`mutation`](#mutation) | `Partial<Mutation> \| false` | `{ methods: ['POST', …], … }` | Configure or disable mutation composables |
| [`mutationKey`](#mutationkey) | `(props) => Array<unknown>` | `built-in` | Build the `mutationKey` for each mutation composable |
| [`hooks`](#hooks) | `boolean` | `false` | Emit `use*` composables on top of the factory helpers |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverVueQuery>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated composables are written and how they are exported. Defaults to `{ path: 'hooks', barrel: { type: 'named' } }`.

#### output.path

Folder the plugin writes to, resolved against the global `output.path` and defaulting to `'hooks'`. For a single file, set `output.mode: 'file'` and give `path` an extension such as `'hooks.ts'`.

#### output.mode

How generated code is consolidated, `'file'` or `'directory'`. The default `'file'` writes a single file, so `output.path` needs an extension. `'directory'` writes one file per operation and pairs with `group` for subdirectories.

> [!IMPORTANT]
> `group` requires `mode: 'directory'`. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) stops the build with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function turning a group key into a folder or identifier name, typed `(context: { group: string }) => string`. Defaults to `({ group }) => camelCase(group)` for tag groups, while path groups use the URL segment as-is.

### client

Selects which registered client plugin the composables call: `'axios'` for `@kubb/plugin-axios` or `'fetch'` for `@kubb/plugin-fetch`. When omitted, the plugin auto-detects the single registered client plugin, so you only need this to disambiguate several. A client plugin must be registered.

### infinite

Adds infinite-query output for cursor- or page-based pagination. Pass an object to configure how the cursor is read, or `false` (the default) to skip. Output is emitted for an operation only when it declares a query parameter matching `infinite.queryParam` (default `'id'`) and [`hooks`](#hooks) is also `true`. Without `hooks: true`, `infinite` produces no file at all, not even the factory:

::: code-group

```typescript [infinite: false (default)]
export function getPetsQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}
```

```typescript [infinite: {}, hooks: true]
export function getPetsInfiniteQueryOptions(/* ... */) {
  return infiniteQueryOptions({ queryKey, queryFn, initialPageParam, getNextPageParam })
}

export function useGetPetsInfiniteQuery(/* ... */) {
  return useInfiniteQuery(getPetsInfiniteQueryOptions(/* ... */))
}
```

:::

#### infinite.queryParam

Name of the query parameter that holds the page cursor. Defaults to `'id'`.

#### infinite.initialPageParam

Initial value for `pageParam` on the first fetch. Type `unknown`, default `0`.

#### infinite.nextParam

Path to the next-page cursor on the response, as dot notation (`'pagination.next.id'`) or array form. Type `string | string[] | null`, default `null`.

#### infinite.previousParam

Path to the previous-page cursor, same dot or array form. Type `string | string[] | null`, default `null`.

#### infinite.cursorParam

Deprecated path to the cursor field. Use `nextParam` and `previousParam` instead. Type `string | null`, default `null`.

### query

Decides which operations are treated as queries. The plugin generates a `queryOptions` factory for each match by default. Pass `false` to skip, or set [`hooks`](#hooks) to also emit `useQuery`.

#### query.methods

HTTP methods treated as queries, default `['GET']`. Matching operations generate a `queryOptions` factory instead of a mutation. Type `Array<string>`.

#### query.importPath

Module specifier for the generated `import { queryOptions } from '...'`. Type `string`, default `'@tanstack/vue-query'`.

### queryKey

Builds the `queryKey` for each query composable. The callback receives the operation `node` and active `casing` and returns the key array. String values are inlined verbatim, so wrap literals in `JSON.stringify(...)`. Defaults to the built-in `queryKeyTransformer`.

::: code-group

```typescript [queryKey builder]
queryKey: ({ node }) => [JSON.stringify(node.operationId)]
```

```typescript [Generated output]
export const getUserByNameQueryKey = () => ['getUserByName'] as const
```

:::

### mutation

Decides which operations are treated as mutations. The plugin generates a `mutationKey` helper for each match by default. Pass `false` to skip, or set [`hooks`](#hooks) to also emit `useMutation`.

#### mutation.methods

HTTP methods treated as mutations, default `['POST', 'PUT', 'PATCH', 'DELETE']`. Matching operations generate mutation output instead of a query. Type `Array<string>`.

#### mutation.importPath

Module specifier for the generated `import { useMutation } from '...'`, emitted when [`hooks`](#hooks) is set. Type `string`, default `'@tanstack/vue-query'`.

### mutationKey

Builds the `mutationKey` for each mutation composable, useful for batching invalidations. It takes the same `{ node, casing }` props as `queryKey`, inlines strings the same way (wrap literals in `JSON.stringify(...)`), and defaults to the built-in `mutationKeyTransformer`.

### hooks

Controls whether `use*` composables are emitted. The default `false` writes only the `queryOptions`, `queryKey`, and `mutationKey` factory helpers for plain queries and mutations. Set `true` to also generate `useQuery`, `useInfiniteQuery`, and `useMutation`.

[`infinite`](#infinite) is gated on `hooks` too, writing nothing while `hooks` is `false`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverVueQuery`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverVueQueryPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  query?: {
    name?(node: OperationNode): string
    optionsName?(node: OperationNode): string
    keyName?(node: OperationNode): string
    keyTypeName?(node: OperationNode): string
    clientName?(node: OperationNode): string
  }
  infiniteQuery?: { /* same members as query */ }
  mutation?: {
    name?(node: OperationNode): string
    keyName?(node: OperationNode): string
    typeName?(node: OperationNode): string
  }
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
