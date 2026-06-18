---
title: 'Migration: @kubb/plugin-react-query'
description: Configuration and generated-output changes for @kubb/plugin-react-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-react-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-react-query`](/plugins/plugin-react-query).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`. The `client` sub-object stays the same, as do all other options.

## Generated output

[`@kubb/plugin-vue-query`](/docs/5.x/migration-guide/plugin-vue-query) shares these changes. Both plugins also pick up the renames from `plugin-client` (`*Data`, `*Response`, `*Status<code>`).

The exported `*MutationKey` type alias is gone. Use the runtime helper when you need the key:

```diff
- export type CreateUserMutationKey = ReturnType<typeof createUserMutationKey>
- export const createUserMutationKey = () => [{ url: '/user' }] as const
+ export const createUserMutationKey = () => [{ url: '/user' }] as const
```

### Mutation and query `TData` narrows to 2xx responses

The `TData` generic on `useMutation`, `useQuery`, `useInfiniteQuery`, `useSuspenseQuery`, and their `*Options` helpers now points at the union of `2xx` response status types instead of the full response alias. That matches TanStack Query's contract, where `TData` is the resolved success value and errors flow through `TError`.


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

The change covers `queryFn`, `queryOptions`, and the hook generics together. No config flag brings back the old behavior. If your client returns non-`2xx` bodies as resolved data instead of throwing, wrap it to throw so TanStack Query's `error` / `onError` path fires. The previous typing was silently broken at runtime.

### `enabled`-guarded params are now optional

`*QueryOptions` and `*InfiniteQueryOptions` emit an `enabled` guard built from the required path and query parameters (`enabled: !!petId` in React Query, `enabled: () => !!toValue(petId)` in Vue Query). In v4 those parameters stayed required in the generated type, so a caller could never pass `undefined` to reach the disabled state the guard already covers. The type contradicted the runtime.

v5 makes those parameters optional in the generated `queryKey`, `queryOptions`, and hook signatures. The `queryFn` calls the client with a non-null assertion. The `enabled` guard stays the same.

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

You can now pass a value that is not ready yet, such as a route param or the result of a dependent query, and let the existing guard keep the query disabled until it resolves:

```ts
// type-checks in v5; the query stays disabled until petId is defined
useGetPetById({ petId: route.params.petId })
```

> [!NOTE]
> This is a type-only change. The `?` and `!` are erased at compile time, so the emitted JavaScript (including the `enabled` guard) matches v4. Suspense hooks cannot be disabled, so their parameters stay required.
