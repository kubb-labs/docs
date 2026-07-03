---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-swr`](/plugins/plugin-swr/).

`@kubb/plugin-swr` follows the same conventions as the React Query and Vue Query plugins. [`resolver.resolveName`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers` object held only `name`, so that is the whole rename. To rewrite generated nodes before printing, use the new [`macros`](/plugins/plugin-swr/reference/options#macros) option.

SWR has no `enabled` option. v5 drops the param-presence guard, so the hook keys off `shouldFetch` alone (`useSWR(shouldFetch ? queryKey : null, ...)`). Set `shouldFetch` to `false` to disable the request.

## `client` is a selector, not an object

In v4 the `client` option carried the whole client config, including `dataReturnType`, `clientType`, `baseURL`, `bundle`, and the custom `importPath`. v5 drops the object form. The hooks no longer emit their own client. They call a registered client plugin instead, so you register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and point `client` at it with the string `'axios'` or `'fetch'`. When exactly one client plugin is registered, leave `client` off and the plugin picks it up. Set the string only to disambiguate when both are registered.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  plugins: [
    pluginSwr({
      client: { client: 'axios', dataReturnType: 'data', baseURL: 'https://api.example.com' },
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://api.example.com' }),
    pluginSwr({ client: 'axios' }),
  ],
})
```

:::

`dataReturnType` has no replacement on the query plugin. The client plugin returns the response body, so the hooks read `res.data`. Move `baseURL` to the client plugin, and see [Migration: @kubb/plugin-client removed](/docs/5.x/migration/plugin-client) for the `clientType`, `bundle`, and `importPath` options that went with it.

## Removed: `parser`

The v4 `parser` option is gone, and so is its v5 rename `validator`: this plugin never applies validation itself. The hooks call the client operation, and the client plugin bakes the validation into that operation. Set `validator: 'zod'` on `pluginAxios` or `pluginFetch` instead.

```diff [Diff]
  pluginSwr({
-   parser: 'zod',
  })
  pluginAxios({
+   validator: 'zod',
  })
```

## Removed: `mutation.paramsToTrigger`

v4 gated the trigger-based mutation shape behind `mutation.paramsToTrigger`, off by default. v5 removes the flag and makes that shape the default, so mutation parameters always pass through `trigger()`. Drop `paramsToTrigger` from your config.

```diff [Diff]
  pluginSwr({
-   mutation: { paramsToTrigger: true },
  })
```

## Removed: `generators`

The `generators` option is gone. Plugins no longer accept extra generators inline. Move custom output into your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

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
