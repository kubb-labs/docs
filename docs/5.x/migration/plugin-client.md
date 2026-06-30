---
title: 'Migration: @kubb/plugin-client removed'
description: '@kubb/plugin-client is removed. Migrate to @kubb/plugin-axios or @kubb/plugin-fetch.'
---

# Migration: `@kubb/plugin-client` removed

`@kubb/plugin-client` no longer ships. Two dedicated plugins replace it:

- [`@kubb/plugin-axios`](/plugins/plugin-axios/) generates an axios HTTP client. Import `pluginAxios`.
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) generates a Fetch API client. Import `pluginFetch`.

Both speak the same `RequestResult` contract and share the same options: `output`, `exclude`, `include`, `override`, `baseURL`, `validator`, `sdk`, `group`, `resolver`, and `macros`.

## Pick a plugin by the old `client` value

In v4 the `client` option chose the runtime inside one `@kubb/plugin-client`. In v5 you pick the plugin instead, and `client` is gone from its options.

::: code-group

```typescript [v4 kubb.config.ts]
import { pluginClient } from '@kubb/plugin-client'

pluginClient({ client: 'axios', output: { path: 'clients' } })
```

```typescript [v5 kubb.config.ts]
import { pluginAxios } from '@kubb/plugin-axios'

pluginAxios({ output: { path: 'clients' } })
```

:::

::: code-group

```typescript [v4 kubb.config.ts]
import { pluginClient } from '@kubb/plugin-client'

pluginClient({ client: 'fetch', output: { path: 'clients' } })
```

```typescript [v5 kubb.config.ts]
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ output: { path: 'clients' } })
```

:::

## Replace `clientType` and `wrapper` with `sdk`

v4 generated standalone functions by default and switched to a class with `clientType: 'class'`. A separate `wrapper: { className }` composed those tag classes into one entry point. v5 drops both and adds a single `sdk` option for class-based output. Leave `sdk` unset to keep the standalone per-operation functions, which is what the query plugins consume.

::: code-group

```typescript [v4 kubb.config.ts]
import { pluginClient } from '@kubb/plugin-client'

pluginClient({ clientType: 'class', wrapper: { className: 'PetStore' } })
```

```typescript [v5 kubb.config.ts]
import { pluginAxios } from '@kubb/plugin-axios'

pluginAxios({ sdk: { name: 'petStore' } })
```

:::

With `sdk` set, `mode: 'tag'` (the default) emits one class per tag, and a `name` composes them into a root class that builds every tag client from one config. Use `mode: 'flat'` for a single class with every operation as a direct method.

## Remove `dataReturnType` and read the result

`dataReturnType` is gone. Both client plugins return the shared `RequestResult` of `{ data, error, request, response }`, and `throwOnError` defaults to `true`. A `dataReturnType: 'data'` call becomes a destructure, and `dataReturnType: 'full'` becomes `throwOnError: false` so you can read `error` and `response.status`. The [main migration guide](/docs/5.x/migration#_11-remove-datareturntype-and-adopt-the-requestresult-contract) covers the full contract.

```diff [Diff]
- const pet = await getPet(1)
+ const { data: pet } = await getPet({ path: { petId: 1 } })
```

## `parser` is renamed to `validator`

v4 `parser` took `'client'` or `'zod'` and defaulted to `'client'`. v5 renames the option to `validator`. It defaults to `false` and accepts `'zod'` or `{ request, response }` to validate request and response bodies with schemas from `@kubb/plugin-zod`. The `'client'` value is gone, so `parser: 'zod'` becomes `validator: 'zod'`, and `parser: 'client'` becomes the default `false`.

## Authentication comes from the spec

v4 left auth to the custom client you imported through `importPath`. v5 reads the security schemes from your OpenAPI spec and attaches them to every generated call. You give the bundled client one `auth` resolver and the runtime adds the token to each guarded request. See [Authentication](/plugins/plugin-fetch/guide/authentication) for the setup.

## Other removed options

Drop these `plugin-client` options from your config:

- `operations`, with no equivalent
- `clientType: 'staticClass'`, since `sdk` covers class output
- the custom-client `importPath`, since the client is always bundled into `.kubb/client.ts`
- `bundle`, for the same reason
- `urlType`, with its `get<Operation>Url` helpers and the `resolveUrlName` resolver method
- `generators`, since custom output now lives in your own plugin

`transformers.name` becomes [`resolver.resolveName`](/docs/5.x/migration#transformersname-resolver), and `contentType` moves to [`adapterOas`](/adapters/adapter-oas/). If you wrapped a custom HTTP library through `importPath`, move that logic into your own module and call the generated functions from it.

## Rebuild the URL helpers with a custom plugin

`urlType: 'export'` used to emit one `get<Operation>Url` function per operation that returned the URL without sending the request. The client plugins no longer generate those. If you relied on them, generate the same helpers from your own plugin. The URL lives on each operation node as `node.path`, so a small `operation` generator covers it.

```typescript twoslash [pluginClientUrl.ts]
import { ast, definePlugin, defineGenerator } from '@kubb/core'

export const pluginClientUrl = definePlugin(() => ({
  name: 'plugin-client-url',
  dependencies: ['plugin-ts'],
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(
        defineGenerator({
          name: 'client-url-generator',
          operation(node, genCtx) {
            const resolver = genCtx.getResolver('plugin-ts')
            const name = `${resolver.default(node.operationId, 'function')}Url`

            return [
              ast.factory.createFile({
                baseName: `${name}.ts`,
                path: `${genCtx.root}/${name}.ts`,
                sources: [
                  ast.factory.createSource({
                    nodes: [ast.factory.createText(`export function ${name}() {\n  return \`${node.path}\` as const\n}\n`)],
                  }),
                ],
              }),
            ]
          },
        }),
      )
    },
  },
}))
```

Register it alongside `pluginTs` and your client plugin. For a full walk-through of the plugin anatomy and how to read names off the `plugin-ts` resolver, see [Creating plugins](/docs/5.x/guide/going-further/creating-plugins).

## Query plugins keep `client`

`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-swr` keep a `client?: 'axios' | 'fetch'` option. It auto-detects the registered client plugin, so register `pluginAxios` or `pluginFetch` alongside the query plugin and the hooks pick it up.

## `plugin-mcp`

`@kubb/plugin-mcp` now takes `client` as an `'axios' | 'fetch'` selector instead of the v4 object that carried `baseURL`, `dataReturnType`, and the rest. The handlers delegate to a registered client plugin, so `baseURL` moves onto `pluginAxios` or `pluginFetch`. With a single client plugin registered, the selector auto-detects, so you only pass `client` to disambiguate several.

::: code-group

```typescript [v4 kubb.config.ts]
import { pluginMcp } from '@kubb/plugin-mcp'

pluginMcp({ client: { client: 'fetch', baseURL: 'https://api.example.com' } })
```

```typescript [v5 kubb.config.ts]
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginMcp } from '@kubb/plugin-mcp'

pluginFetch({ baseURL: 'https://api.example.com' })
pluginMcp({ client: 'fetch' })
```

:::
