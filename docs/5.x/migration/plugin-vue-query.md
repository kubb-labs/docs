---
title: 'Migration: @kubb/plugin-vue-query'
description: Configuration and generated-output changes for @kubb/plugin-vue-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-vue-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query).

[`resolver.resolveName`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers` object held only `name`, so that is the whole rename. To rewrite generated nodes before printing, use the new [`macros`](/plugins/plugin-vue-query#macros) option.

## `client` is a selector, not an object

In v4 the `client` option carried the whole client config, including `dataReturnType`, `clientType`, `baseURL`, `bundle`, and the custom `importPath`. v5 drops the object form. The composables no longer emit their own client. They call a registered client plugin instead, so you register [`@kubb/plugin-axios`](/plugins/plugin-axios) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch) and point `client` at it with the string `'axios'` or `'fetch'`. When exactly one client plugin is registered, leave `client` off and the plugin picks it up. Set the string only to disambiguate when both are registered.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  plugins: [
    pluginVueQuery({
      client: { client: 'axios', dataReturnType: 'data', baseURL: 'https://api.example.com' },
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://api.example.com' }),
    pluginVueQuery({ client: 'axios' }),
  ],
})
```

:::

`dataReturnType` has no replacement on the query plugin. The client plugin returns the response body, so the composables read `res.data`. Move `baseURL` to the client plugin, and see [Migration: @kubb/plugin-client removed](/docs/5.x/migration/plugin-client) for the `clientType`, `bundle`, and `importPath` options that went with it.

## Renamed: `parser` → `validator`

The `parser` option is now `validator`. Set `validator: 'zod'` where you set `parser: 'zod'` before. The accepted values are unchanged: `false`, `'zod'`, or `{ request: 'zod', response: 'zod' }` to validate request and response bodies with schemas from [`@kubb/plugin-zod`](/plugins/plugin-zod).

```diff [Diff]
  pluginVueQuery({
-   parser: 'zod',
+   validator: 'zod',
  })
```

## Removed: `generators`

The `generators` option is gone. Plugins no longer accept extra generators inline. Move custom output into your own plugin. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each composable now takes its parameters as a single grouped options object shaped as `{ path, query, body, headers }`, with camelCase property names. This matches the shape `@kubb/plugin-fetch` already used. Query params move under `query`, path params under `path`, the request body under `body`, and header params under `headers`.

```diff [Diff]
  pluginVueQuery({
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

The first argument is typed `Omit<XxxRequestConfig, 'url'>`, the `RequestConfig` type `@kubb/plugin-ts` generates. The trailing `config` argument is unchanged.

## Generated output

The generated output changes match React Query. The `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, required params are enforced in the type, and the auto `enabled` guard is dropped. The client call still unwraps each grouped option with `toValue()` so refs and getters resolve. See [Generated output: @kubb/plugin-react-query](/docs/5.x/migration/plugin-react-query#generated-output).
