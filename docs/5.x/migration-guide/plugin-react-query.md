---
title: 'Migration: @kubb/plugin-react-query'
description: Configuration and generated-output changes for @kubb/plugin-react-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-react-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-react-query`](/plugins/plugin-react-query).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `client` sub-object for HTTP client configuration is unchanged. All other options are unchanged.

## Generated output

These changes are shared with [`@kubb/plugin-vue-query`](/docs/5.x/migration-guide/plugin-vue-query). Beyond them, both plugins inherit the renames from `plugin-client` (`*Data`, `*Response`, `*Status<code>`).

The exported `*MutationKey` type alias is gone. Keep using the runtime helper if you need the key:

```diff
- export type CreateUserMutationKey = ReturnType<typeof createUserMutationKey>
- export const createUserMutationKey = () => [{ url: '/user' }] as const
+ export const createUserMutationKey = () => [{ url: '/user' }] as const
```

### Mutation and query `TData` narrows to 2xx responses

The `TData` generic on `useMutation`, `useQuery`, `useInfiniteQuery`, `useSuspenseQuery`, and their `*Options` helpers now references the union of `2xx` response status types instead of the full response alias. This aligns with TanStack Query's contract that `TData` is the resolved success value and errors flow through `TError`.

```diff
  export function useAddPet<TContext>(
    options: {
      mutation?: MutationObserverOptions<
-       AddPetResponse,
+       AddPetStatus200,
        ResponseErrorConfig<AddPetStatus405>,
        { data: AddPetData },
        TContext
      > & { client?: QueryClient }
      client?: Partial<RequestConfig<AddPetData>> & { client?: typeof client }
    } = {},
  ) { /* ... */ }
```

Call sites that previously needed `as` casts or `'id' in res` checks compile directly:

```ts
const pet = await mutateAsync({ data: { name: 'Rex' } })
pet.id // typed as Pet.id, no narrowing required
```

The change applies to `queryFn`, `queryOptions`, and the hook generics in one pass. No config flag toggles the old behavior. If your client returns non-`2xx` bodies as resolved data instead of throwing, wrap it to throw so TanStack Query's `error` / `onError` path fires. The previous typing was silently broken at runtime.

### `enabled`-guarded params are now optional

`*QueryOptions` and `*InfiniteQueryOptions` emit an `enabled` guard derived from the required path and query parameters (`enabled: !!petId` in React Query, `enabled: () => !!toValue(petId)` in Vue Query). In v4 those parameters stayed required in the generated type, so a caller could never pass `undefined` to reach the disabled state the guard already implements. The type contradicted the runtime.

v5 makes those parameters optional in the generated `queryKey`, `queryOptions`, and hook signatures, and the `queryFn` calls the client with a non-null assertion. The `enabled` guard is unchanged.

```diff
- export function getPetByIdQueryOptions({ petId }: { petId: GetPetByIdPathPetId }, config: Partial<RequestConfig> & { client?: Client } = {}) {
+ export function getPetByIdQueryOptions({ petId }: { petId?: GetPetByIdPathPetId } = {}, config: Partial<RequestConfig> & { client?: Client } = {}) {
    const queryKey = getPetByIdQueryKey({ petId })
    return queryOptions<GetPetByIdStatus200, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>, GetPetByIdStatus200, typeof queryKey>({
      enabled: !!petId,
      queryKey,
      queryFn: async ({ signal }) => {
-       return getPetById({ petId }, { ...config, signal: config.signal ?? signal })
+       return getPetById({ petId: petId! }, { ...config, signal: config.signal ?? signal })
      },
    })
  }
```

You can now pass a not-yet-available value (for example a route param or the result of a dependent query) and rely on the existing guard to keep the query disabled until it resolves:

```ts
// type-checks in v5; the query stays disabled until petId is defined
useGetPetById({ petId: route.params.petId })
```

> [!NOTE]
> This is a type-only change. The `?` and `!` are erased at compile time, so the emitted JavaScript (including the `enabled` guard) is identical to v4. Suspense hooks cannot be disabled, so their parameters stay required.
