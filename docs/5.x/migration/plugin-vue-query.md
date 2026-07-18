---
title: 'Migration: @kubb/plugin-vue-query'
description: Configuration and generated-output changes for @kubb/plugin-vue-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-vue-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/).

[`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers` object held only `name`, so that is the whole rename. To rewrite generated nodes before printing, use the new [`macros`](/plugins/plugin-vue-query/reference/options#macros) option. The `generators` option is [gone](/docs/5.x/migration#generators-removed).

## `client` is a selector, not an object

In v4 `client` was an object that carried the whole client config (`dataReturnType`, `clientType`, `baseURL`, `bundle`, `importPath`). In v5 it is a string that names a registered client plugin, and the composables call that plugin instead of emitting their own. See [Query and MCP plugins select a client](/docs/5.x/migration#client-becomes-a-selector) for the shared rules, then register [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and point `client` at it.

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

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb/config'
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

## Removed: `parser`

As on [React Query](/docs/5.x/migration/plugin-react-query#removed-parser), the `parser` option is gone; set `validator: 'zod'` on the client plugin (`pluginAxios`/`pluginFetch`) instead.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

Same grouped-options change as [React Query](/docs/5.x/migration/plugin-react-query#removed-paramstype-pathparamstype-paramscasing): each composable takes one `{ path, query, body, headers }` object (property names from the `@kubb/plugin-ts` `*Options` type) instead of positional params. Vue Query wraps each group in `MaybeRefOrGetter`, so refs and getters resolve.

## `hooks` defaults to `false`

The `hooks` option controls whether `use*` composables are emitted alongside the factory helpers. Its default changed from `true` to `false`, so existing configs that relied on generated composables must now opt in explicitly.

```diff [kubb.config.ts]
  pluginVueQuery({
    output: { path: './hooks', mode: 'directory' },
+   hooks: true,
  })
```

With `hooks: false` (the default) the plugin still emits `queryOptions`, `queryKey`, and `mutationKey`. Only the `useQuery`, `useInfiniteQuery`, and `useMutation` wrappers are skipped.

## Generated output

The generated output changes match React Query. The `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, required params are enforced in the type, and the auto `enabled` guard is dropped. The client call still unwraps each grouped option with `toValue()` so refs and getters resolve. See [Generated output: @kubb/plugin-react-query](/docs/5.x/migration/plugin-react-query#generated-output).
