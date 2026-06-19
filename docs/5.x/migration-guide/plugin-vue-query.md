---
title: 'Migration: @kubb/plugin-vue-query'
description: Configuration and generated-output changes for @kubb/plugin-vue-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-vue-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each composable now takes its parameters as a single grouped options object shaped as `{ path, query, body, headers }`, with camelCase property names. This matches the shape `@kubb/plugin-fetch` already used. Query params move under `query`, path params under `path`, the request body under `body`, and header params under `headers`.

```diff [Diff]
  pluginVueQuery({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

Update the call sites. Query params move into `query`, and path params move into `path`. When an operation has required path params, `path` is required too.

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

The first argument is typed `Omit<XxxRequestConfig, 'url'>`, the `RequestConfig` type `@kubb/plugin-ts` generates. The trailing `config` argument is unchanged.

## Generated output

The generated output changes match React Query. The `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, and `enabled`-guarded params become optional. Vue Query writes the guard as `enabled: () => !!toValue(petId)`. See [Generated output: @kubb/plugin-react-query](/docs/5.x/migration-guide/plugin-react-query#generated-output).
