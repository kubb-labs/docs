---
title: 'Migration: @kubb/plugin-client removed'
description: '@kubb/plugin-client is removed. Migrate to @kubb/plugin-axios or @kubb/plugin-fetch.'
---

# Migration: `@kubb/plugin-client` removed

`@kubb/plugin-client` no longer ships. Two dedicated plugins replace it:

- [`@kubb/plugin-axios`](/plugins/plugin-axios) generates an axios HTTP client. Import `pluginAxios`.
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch) generates a Fetch API client. Import `pluginFetch`.

Both speak the same `RequestResult` contract and share the same options: `output`, `exclude`, `include`, `override`, `baseURL`, `parser`, `sdk`, `group`, `resolver`, and `macros`.

## Pick a plugin by the old `client` value

The old `client` option chose the runtime. Now you pick the plugin instead.

::: code-group

```typescript [Before (axios)]
import { pluginClient } from '@kubb/plugin-client'

pluginClient({ client: 'axios', output: { path: 'clients' } })
```

```typescript [After (axios)]
import { pluginAxios } from '@kubb/plugin-axios'

pluginAxios({ output: { path: 'clients' } })
```

:::

::: code-group

```typescript [Before (fetch)]
import { pluginClient } from '@kubb/plugin-client'

pluginClient({ client: 'fetch', output: { path: 'clients' } })
```

```typescript [After (fetch)]
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ output: { path: 'clients' } })
```

:::

## Rename `sdk.className` to `sdk.name`

The `sdk` option keeps the same shape with one rename. `className` becomes `name`, and the value is lower-case.

```diff [Diff]
- pluginClient({ sdk: { className: 'PetStore' } })
+ pluginAxios({ sdk: { name: 'petStore' } })
```

The `clientType: 'class'` behavior now lives behind `sdk`. Set `sdk` to generate a class-based SDK on top of the operation functions.

## Removed options with no replacement

These `plugin-client` options are gone and have no equivalent:

- `operations`
- `clientType: 'staticClass'`
- the custom-client `importPath`
- `urlType`, with its `get<Operation>Url` helpers and the `resolveUrlName` resolver method

Drop them from your config. If you wrapped a custom HTTP library through `importPath`, move that logic into your own module and call the generated functions from it.

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

Register it alongside `pluginTs` and your client plugin. For a full walk-through of the plugin anatomy and how to read names off the `plugin-ts` resolver, see [Creating plugins](/docs/5.x/guides/creating-plugins).

## Query plugins keep `client`

`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-swr` keep a `client?: 'axios' | 'fetch'` option. It auto-detects the registered client plugin, so register `pluginAxios` or `pluginFetch` alongside the query plugin and the hooks pick it up.

## `plugin-mcp`

`@kubb/plugin-mcp` now takes `client` as an `'axios' | 'fetch'` selector instead of an object. Set `baseURL` at the top level of `pluginMcp`. The handlers delegate to the registered axios or fetch client.

```diff [Diff]
- pluginMcp({ client: { client: 'fetch', baseURL: 'https://api.example.com' } })
+ pluginMcp({ client: 'fetch', baseURL: 'https://api.example.com' })
```
