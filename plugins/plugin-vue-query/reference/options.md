---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-vue-query.
outline: deep
---

# Options

Options for `@kubb/plugin-vue-query`, which generates TanStack Vue Query composables from an OpenAPI spec.

## Options overview

Select an option to see its type, default, and examples. Nested settings link to their own section or the parent option.

| Option | Purpose |
| --- | --- |
| [`output`](#output) | Where the generated composables are written and exported. |
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
| [`client`](#client) | Which registered client plugin the composables call. |
| [`infinite`](#infinite) | Add `useInfiniteQuery` composables for paginated reads. |
| ↳ [`infinite.queryParam`](#infinite-queryparam) | Choose the query parameter that carries the cursor. |
| ↳ [`infinite.initialPageParam`](#infinite-initialpageparam) | Set the first page parameter. |
| ↳ [`infinite.nextParam`](#infinite-nextparam) | Locate the next-page cursor in the response. |
| ↳ [`infinite.previousParam`](#infinite-previousparam) | Locate the previous-page cursor in the response. |
| ↳ [`infinite.cursorParam`](#infinite-cursorparam) | Deprecated cursor path. Use `nextParam` and `previousParam` instead. |
| [`query`](#query) | Configure or disable query composables. |
| ↳ [`query.methods`](#query-methods) | Choose which HTTP methods generate queries. |
| ↳ [`query.importPath`](#query-importpath) | Set the module used for query imports. |
| [`queryKey`](#querykey) | Build the `queryKey` for each query composable. |
| [`mutation`](#mutation) | Configure or disable mutation composables. |
| ↳ [`mutation.methods`](#mutation-methods) | Choose which HTTP methods generate mutations. |
| ↳ [`mutation.importPath`](#mutation-importpath) | Set the module used for mutation imports. |
| [`mutationKey`](#mutationkey) | Build the `mutationKey` for each mutation composable. |
| [`hooks`](#hooks) | Emit `use*` composables on top of the factory helpers. |
| [`include`](#include) | Keep only operations that match. |
| [`exclude`](#exclude) | Skip operations that match. |
| [`override`](#override) | Apply different options per pattern. |
| [`resolver`](#resolver) | Customize generated names and file paths. |
| [`macros`](#macros) | Rewrite AST nodes before printing. |

## Option details

### output

Where the generated composables are written and how they are exported. Defaults to `{ path: 'hooks', barrel: { type: 'named' } }`.

| | |
| --- | --- |
| Type | `Output` |
| Required | `false` |
| Default | `{ path: 'hooks', barrel: { type: 'named' } }` |

#### output.path

Folder the plugin writes to, resolved against the global `output.path` and defaulting to `'hooks'`. For a single file, set `output.mode: 'file'` and give `path` an extension such as `'hooks.ts'`.

#### output.mode

How generated code is consolidated into files.

::field-group

:::field{name="'file'"}
Writes everything into a single file. `output.path` must include a file extension. This mode cannot be combined with `group`.
:::

:::field{name="'directory'"}
Writes separate files under `output.path`. Use `group` to organize them into subdirectories.
:::

::

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

Function turning a group key into a folder or identifier name, typed `(context: { group: string }) => string`. Defaults to `({ group }) => camelCase(group)` for tag groups, while path groups use the URL segment as-is.

### client

Selects which registered client plugin the composables call. A single registered client is auto-detected; set `client` when several are registered.

| | |
| --- | --- |
| Type | `'axios' \| 'fetch'` |
| Required | `false` |

::field-group

:::field{name="'fetch'"}
Calls the operations generated by [`@kubb/plugin-fetch`](/plugins/plugin-fetch/).
:::

:::field{name="'axios'"}
Calls the operations generated by [`@kubb/plugin-axios`](/plugins/plugin-axios/).
:::

::

### infinite

Adds infinite-query output for cursor- or page-based pagination. Pass an object to configure how the cursor is read, or `false` (the default) to skip. Output is emitted for an operation only when it declares a query parameter matching `infinite.queryParam` (default `'id'`) and [`hooks`](#hooks) is also `true`. Without `hooks: true`, `infinite` produces no file at all, not even the factory:

| | |
| --- | --- |
| Type | `Partial<Infinite> \| false` |
| Required | `false` |
| Default | `false` |

::code-group

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

::

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

| | |
| --- | --- |
| Type | `Partial<Query> \| false` |
| Required | `false` |
| Default | `{ methods: ['GET'], … }` |

#### query.methods

HTTP methods treated as queries, default `['GET']`. Matching operations generate a `queryOptions` factory instead of a mutation. Type `Array<string>`.

#### query.importPath

Module specifier for the generated `import { queryOptions } from '...'`. Type `string`, default `'@tanstack/vue-query'`.

### queryKey

Builds the `queryKey` for each query composable. The callback receives the operation `node`, the active `casing` and the `variant` (`'query'` or `'infiniteQuery'`, the hook the key is built for) and returns the key array. String values are inlined verbatim, so wrap literals in `JSON.stringify(...)`. Defaults to the built-in `queryKeyTransformer`, which adds `infinite: true` to infinite keys so they never share a cache entry with the plain query.

| | |
| --- | --- |
| Type | `(props) => Array<unknown>` |
| Required | `false` |
| Default | `built-in` |

::code-group

```typescript [queryKey builder]
queryKey: ({ node, variant }) => [JSON.stringify({ variant, operationId: node.operationId })]
```

```typescript [Generated output]
export const getUserByNameQueryKey = () => [{ variant: 'query', operationId: 'getUserByName' }] as const
```

::

### mutation

Decides which operations are treated as mutations. The plugin generates a `mutationKey` helper for each match by default. Pass `false` to skip, or set [`hooks`](#hooks) to also emit `useMutation`.

| | |
| --- | --- |
| Type | `Partial<Mutation> \| false` |
| Required | `false` |
| Default | `{ methods: ['POST', …], … }` |

#### mutation.methods

HTTP methods treated as mutations, default `['POST', 'PUT', 'PATCH', 'DELETE']`. Matching operations generate mutation output instead of a query. Type `Array<string>`.

#### mutation.importPath

Module specifier for the generated `import { useMutation } from '...'`, emitted when [`hooks`](#hooks) is set. Type `string`, default `'@tanstack/vue-query'`.

### mutationKey

Builds the `mutationKey` for each mutation composable, useful for batching invalidations. It takes the same `{ node, casing }` props as `queryKey` (with `variant: 'mutation'`), inlines strings the same way (wrap literals in `JSON.stringify(...)`), and defaults to the built-in `mutationKeyTransformer`.

| | |
| --- | --- |
| Type | `(props) => Array<unknown>` |
| Required | `false` |
| Default | `built-in` |

### hooks

Controls whether `use*` composables are emitted. The default `false` writes only the `queryOptions`, `queryKey`, and `mutationKey` factory helpers for plain queries and mutations. Set `true` to also generate `useQuery`, `useInfiniteQuery`, and `useMutation`.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `false` |

[`infinite`](#infinite) is gated on `hooks` too, writing nothing while `hooks` is `false`.

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
| Type | `ResolverPatch<ResolverVueQuery>` |
| Required | `false` |

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

| | |
| --- | --- |
| Type | `Array<Macro>` |
| Required | `false` |
