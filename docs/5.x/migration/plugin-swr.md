---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-swr`](/plugins/plugin-swr/).

`@kubb/plugin-swr` follows the same conventions as the React Query and Vue Query plugins. [`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers` object held only `name`, so that is the whole rename. To rewrite generated nodes before printing, use the new [`macros`](/plugins/plugin-swr/reference/options#macros) option. The `generators` option is [gone](/docs/5.x/migration#generators-removed).

SWR has no `enabled` option. v5 drops the param-presence guard, so the hook keys off `shouldFetch` alone (`useSWR(shouldFetch ? queryKey : null, ...)`). Set `shouldFetch` to `false` to disable the request.

## `client` is a selector, not an object

In v4 `client` was an object that carried the whole client config (`dataReturnType`, `clientType`, `baseURL`, `bundle`, `importPath`). In v5 it is a string that names a registered client plugin, and the hooks call that plugin instead of emitting their own. See [Query and MCP plugins select a client](/docs/5.x/migration#client-becomes-a-selector) for the shared rules, then register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and point `client` at it.

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

```typescript twoslash [v5 kubb.config.ts]
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

## Removed: `parser`

As on [React Query](/docs/5.x/migration/plugin-react-query#removed-parser), the `parser` option is gone; set `validator: 'zod'` on the client plugin (`pluginAxios`/`pluginFetch`) instead.

## Removed: `mutation.paramsToTrigger`

v4 gated the trigger-based mutation shape behind `mutation.paramsToTrigger`, off by default. v5 removes the flag and makes that shape the default, so mutation parameters always pass through `trigger()`. Drop `paramsToTrigger` from your config.

```diff [Diff]
  pluginSwr({
-   mutation: { paramsToTrigger: true },
  })
```

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

Same grouped-options change as [React Query](/docs/5.x/migration/plugin-react-query#removed-paramstype-pathparamstype-paramscasing): each hook takes one `{ path, query, body, headers }` object (property names from the `@kubb/plugin-ts` `*Options` type). The mutation form passes it through `trigger()`:

```typescript [v5 call site]
useFindPets({ query: { status: 'available' } })
useGetPet({ path: { petId } })
useUpdatePet().trigger({ path: { petId }, body: pet })
```
