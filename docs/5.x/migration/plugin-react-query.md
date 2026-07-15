---
title: 'Migration: @kubb/plugin-react-query'
description: Configuration and generated-output changes for @kubb/plugin-react-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-react-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-react-query`](/plugins/plugin-react-query/).

[`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers` object held only `name`, so that is the whole rename. To rewrite generated nodes before printing, use the new [`macros`](/plugins/plugin-react-query/reference/options#macros) option.

## `client` is a selector, not an object

In v4 the `client` option carried the whole client config, including `dataReturnType`, `clientType`, `baseURL`, `bundle`, and the custom `importPath`. v5 drops the object form. The hooks no longer emit their own client. They call a registered client plugin instead, so you register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and point `client` at it with the string `'axios'` or `'fetch'`. When exactly one client plugin is registered, leave `client` off and the plugin picks it up. Set the string only to disambiguate when both are registered.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  plugins: [
    pluginReactQuery({
      client: { client: 'axios', dataReturnType: 'data', baseURL: 'https://api.example.com' },
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://api.example.com' }),
    pluginReactQuery({ client: 'axios' }),
  ],
})
```

:::

`dataReturnType` has no replacement on the query plugin. The client plugin returns the response body, so the hooks read `res.data`. Move `baseURL` to the client plugin, and see [Migration: @kubb/plugin-client removed](/docs/5.x/migration/plugin-client) for the `clientType`, `bundle`, and `importPath` options that went with it.

## Removed: `parser`

The v4 `parser` option is gone, and so is its v5 rename `validator`: this plugin never applies validation itself. The hooks call the client operation, and the client plugin bakes the validation into that operation. Set `validator: 'zod'` on `pluginAxios` or `pluginFetch` instead.

```diff [Diff]
  pluginReactQuery({
-   parser: 'zod',
  })
  pluginAxios({
+   validator: 'zod',
  })
```

## Removed: `generators`

The `generators` option is gone. Plugins no longer accept extra generators inline. Move custom output into your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each hook now takes its parameters as a single grouped options object shaped as `{ path, query, body, headers }`, with camelCase property names. This matches the shape `@kubb/plugin-fetch` already used. Query params move under `query`, path params under `path`, the request body under `body`, and header params under `headers`.

```diff [Diff]
  pluginReactQuery({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

Update the call sites. Query params move into `query`, and path params move into `path`. When an operation has a required parameter in a group, that group (`path`, `query`, or `headers`) is required too, so an incomplete call fails to compile.

::: code-group

```typescript [v4 call site]
useFindPets({ status: 'available' })
useGetPet(petId)
useUpdatePet().mutate({ petId, data: pet })
```

```typescript [v5 call site]
useFindPets({ query: { status: 'available' } })
useGetPet({ path: { petId } })
useUpdatePet().mutate({ path: { petId }, body: pet })
```

:::

The first argument is the grouped options type that `@kubb/plugin-ts` generates for the operation (`{ path, query, body, headers }`, for example `GetPetByIdOptions`). The trailing `config` argument is typed `Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>>`, where `RequestConfig` comes from the client plugin's `.kubb/client`.

## Generated output

[`@kubb/plugin-vue-query`](/docs/5.x/migration/plugin-vue-query) shares these changes. Both plugins also pick up the renames from the client plugin (`*Data`, `*Response`, `*Status<code>`).

The exported `*MutationKey` type alias is gone. Use the runtime helper when you need the key:

```diff [Diff]
- export type CreateUserMutationKey = ReturnType<typeof createUserMutationKey>
- export const createUserMutationKey = () => [{ url: '/user' }] as const
+ export const createUserMutationKey = () => [{ url: '/user' }] as const
```

### Mutation and query `TData` narrows to 2xx responses

The `TData` generic on `useMutation`, `useQuery`, `useInfiniteQuery`, `useSuspenseQuery`, and their `*Options` helpers now points at the union of `2xx` response status types instead of the full response alias. That matches TanStack Query's contract, where `TData` is the resolved success value and errors flow through `TError`.


```diff [Diff]
  export function useAddPet<TContext>(
    options: {
      mutation?: UseMutationOptions<
-       AddPetResponse,
+       AddPetStatus200,
        ResponseErrorConfig<AddPetStatus405>,
        AddPetOptions,
        TContext
      > & { client?: QueryClient }
      client?: Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>>
    } = {},
  ) { /* ... */ }
```

Call sites that previously needed `as` casts or `'id' in res` checks compile directly:

```typescript [Generated output]
const pet = await mutateAsync({ body: { name: 'Rex' } })
pet.id // typed as Pet.id, no narrowing required
```

The change covers `queryFn`, `queryOptions`, and the hook generics together. No config flag brings back the old behavior. If your client returns non-`2xx` bodies as resolved data instead of throwing, wrap it to throw so TanStack Query's `error` / `onError` path fires. The previous typing was silently broken at runtime.

### No auto `enabled` guard

v4 generated an `enabled` guard from the required path and query parameters: `enabled: !!path?.petId` in React Query, `enabled: () => !!toValue(path?.petId)` in Vue Query. Those parameters were already required, so `!!path.petId` was always `true`. The guard disabled nothing. It read like a safety net and did no work.

v5 removes it. The `path`, `query`, and `headers` groups are required in the generated `queryKey`, `queryOptions`, and hook signatures whenever the operation has a required parameter in that group, and nothing emits `enabled` for you. The query key types only the groups it reads, so a required `headers` parameter never leaks onto the key.

```diff [Diff]
  export function getPetByIdQueryOptions({ path }: GetPetByIdOptions, config: Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>> = {}) {
    const queryKey = getPetByIdQueryKey({ path })
    return queryOptions<GetPetByIdStatus200, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>, GetPetByIdStatus200, typeof queryKey>({
-     enabled: !!path?.petId,
      queryKey,
      queryFn: async ({ signal }) => {
        const { data } = await getPetById({ ...config, path, signal: config.signal ?? signal, throwOnError: true })
        return data
      },
    })
  }
```

To defer or disable a query, set TanStack Query's own `enabled` (or pass `skipToken`) through the hook options:

```typescript [Generated output]
// keep the query disabled until petId resolves
useGetPetById({ path: { petId } }, { query: { enabled: !!petId } })
```

> [!NOTE]
> Suspense hooks always run, so they never had an `enabled` guard and are unchanged.

## `hooks` defaults to `false`

The `hooks` option controls whether `use*` functions are emitted alongside the factory helpers. Its default changed from `true` to `false`, so existing configs that relied on generated hooks must now opt in explicitly.

```diff [kubb.config.ts]
  pluginReactQuery({
    output: { path: './hooks', mode: 'directory' },
+   hooks: true,
  })
```

With `hooks: false` (the default) the plugin still emits `queryOptions`, `mutationOptions`, `queryKey`, and `mutationKey`. Only the `useQuery`, `useSuspenseQuery`, `useInfiniteQuery`, `useSuspenseInfiniteQuery`, and `useMutation` wrappers are skipped.
