---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-swr`](/plugins/plugin-swr).

`@kubb/plugin-swr` follows the same conventions as the React Query and Vue Query plugins. [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

SWR has no `enabled` option. v5 drops the param-presence guard, so the hook keys off `shouldFetch` alone (`useSWR(shouldFetch ? queryKey : null, ...)`). Set `shouldFetch` to `false` to disable the request.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each hook now takes its parameters as a single grouped options object shaped as `{ path, query, body, headers }`, with camelCase property names. This matches the shape `@kubb/plugin-fetch` already used. Query params move under `query`, path params under `path`, the request body under `body`, and header params under `headers`.

```diff [Diff]
  pluginSwr({
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
useUpdatePet().trigger({ petId, data: pet })
```

```typescript [v5 call site]
useFindPets({ query: { status: 'available' } })
useGetPet({ path: { petId } })
useUpdatePet().trigger({ path: { petId }, body: pet })
```

:::

The first argument is typed `Omit<XxxRequestConfig, 'url'>`, the `RequestConfig` type `@kubb/plugin-ts` generates. The trailing `config` argument is unchanged.
