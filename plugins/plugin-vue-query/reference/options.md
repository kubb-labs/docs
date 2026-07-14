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
| [`output`](#output) | `Output` | `{ path: 'hooks', barrel: { type: 'named' } }` | Where the generated composables are written and exported |
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
| [`resolver`](#resolver) | `Partial<ResolverVueQuery>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated composables are written and how they are exported. Defaults to `{ path: 'hooks', barrel: { type: 'named' } }`.

#### output.path

Folder the plugin writes to, resolved against the global `output.path` and defaulting to `'hooks'`. For a single file, set `output.mode: 'file'` and give `path` an extension such as `'hooks.ts'`.

#### output.mode

How generated code is consolidated, `'directory'` or `'file'`. The default `'directory'` writes one file per operation and pairs with `group` for subdirectories. `'file'` writes a single file, so `output.path` needs an extension.

> [!IMPORTANT]
> `mode: 'file'` forbids `group`, and combining them stops the build with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` (barrel) re-exports the plugin's output. Type `{ type: 'named' | 'all', nested?: boolean } | false`. The default `{ type: 'named' }` re-exports each symbol by name for tree-shaking, `{ type: 'all' }` uses `export *`, `nested: true` adds a per-subdirectory barrel, and `false` skips the barrel and drops the files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, for license headers or a `@ts-nocheck` directive. Type `string | ((meta: BannerMeta) => string)`. The function form receives document info (`title`, `description`, `version`, `baseURL`) and per-file `filePath`, `baseName`, `isBarrel`, and `isAggregation`, so `'use server'` can skip barrels.

#### output.footer

Works like `banner` but for closing comments at the bottom of each file. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. It applies only to `output.mode: 'directory'`, not `'file'`.

#### group.type

Property that assigns each operation to a group, required when `group` is set, either `'tag'` or `'path'`. `'tag'` uses the first tag and `'path'` the first URL segment (`pet` for `/pet/{petId}`). An untagged operation lands in `default`.

#### group.name

Function turning a group key into a folder or identifier name, typed `(context: { group: string }) => string`. Defaults to `({ group }) => camelCase(group)` for tag groups, while path groups use the URL segment as-is.

### client

Selects which registered client plugin the composables call: `'axios'` for `@kubb/plugin-axios` or `'fetch'` for `@kubb/plugin-fetch`. When omitted, the plugin auto-detects the single registered client plugin, so you only need this to disambiguate several. A client plugin must be registered.

### infinite

Adds infinite-query output for cursor- or page-based pagination. Pass an object to configure how the cursor is read, or `false` (the default) to skip. Output is emitted for an operation only when it declares a query parameter matching `infinite.queryParam` (default `'id'`). Set [`hooks`](#hooks) to wrap it in `useInfiniteQuery`.

Setting `infinite: {}` adds a `getPetsInfiniteQueryOptions` factory beside the regular `getPetsQueryOptions`:

::: code-group

```typescript [infinite: false (default)]
export function getPetsQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}
```

```typescript [infinite: {}]
export function getPetsInfiniteQueryOptions(/* ... */) {
  return infiniteQueryOptions({ queryKey, queryFn, initialPageParam, getNextPageParam })
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

Builds the `mutationKey` for each mutation composable, useful for batching invalidations. It takes the same `{ node, casing }` props as `queryKey` and inlines strings verbatim, so wrap literals in `JSON.stringify(...)`. Defaults to the built-in `mutationKeyTransformer`.

### hooks

Controls whether `use*` composables are emitted. The default `false` writes only the factory helpers `queryOptions`, `queryKey`, and `mutationKey`. Set `true` to also generate `useQuery`, `useInfiniteQuery`, and `useMutation`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how composables and files are named without forking the plugin. Override only the methods you need, and call `this.name(name)` to reuse the built-in name. The default is `resolverVueQuery`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers).

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
