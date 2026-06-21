---
layout: doc
title: Kubb Cypress Plugin
description: Generate typed `cy.request()` wrappers from OpenAPI so end-to-end
  tests reuse one source of truth for API calls.
outline: 2
kind: plugin
id: plugin-cypress
name: Cypress
category: testing
type: official
npmPackage: "@kubb/plugin-cypress"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-cypress
featured: false
icon:
  light: https://kubb.dev/feature/cypress.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - cypress
  - e2e-testing
  - api-testing
  - test-generation
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-cypress
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-cypress/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/cypress
---

# @kubb/plugin-cypress

`@kubb/plugin-cypress` turns your OpenAPI operations into typed `cy.request()` wrappers. You get one helper per operation. Each helper types its path params, body, query, and response, so a broken API call fails at compile time instead of in the test runner. Use them in `before` and `beforeEach` hooks to seed data, in custom commands, or in API-only tests.

Every helper yields the response body, typed as `Cypress.Chainable<T>`. Chain `.then()` to assert against the parsed body. To reach `status` or `headers`, call `cy.request()` directly.

It builds on [`@kubb/plugin-ts`](/plugins/plugin-ts), so add that plugin too.

Each helper takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

**See also**

- [Cypress](https://www.cypress.io/)
- [cy.request()](https://docs.cypress.io/api/commands/request)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-cypress@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-cypress@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-cypress@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-cypress@beta
```

:::

## Options

### output

Where the generated helpers are written and how they are exported.

|           |                                                  |
| --------: | :----------------------------------------------- |
|     Type: | `Output`                                         |
| Required: | `false`                                          |
|  Default: | `{ path: 'cypress', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'cypress.ts'`.

|           |             |
| --------: | :---------- |
|     Type: | `string`    |
| Required: | `true`      |
|  Default: | `'cypress'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: { path: './cypress' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── cypress/
        ├── getPetById.ts
        └── getInventory.ts
```

:::

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'cypress.ts'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'types.ts', mode: 'file' },
    }),
    pluginCypress({
      output: { path: 'cypress', mode: 'directory' },
      group: { type: 'tag' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    ├── types.ts
    └── cypress/
        ├── pet/
        │   └── getPetById.ts
        └── store/
            └── getInventory.ts
```

:::

#### output.barrel

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

- `{ type: 'named' }` re-exports each symbol by name. Best for tree-shaking and explicit imports.
- `{ type: 'all' }` uses `export *`. Smaller barrel file, but exports everything.
- `{ nested: true }` creates a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel entirely. The plugin's files are also excluded from the root `index.ts`.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'named' \| 'all', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

> [!TIP]
> Pick `'named'` when consumers care about which symbols they import (better tree-shaking, friendlier auto-import). Pick `'all'` when the file count is small and you want a one-line barrel.

::: code-group

```typescript ['named' (default)]
export { getPetById } from './getPetById'
export { getInventory } from './getInventory'
```

```typescript ['all']
export * from './getPetById'
export * from './getInventory'
```

```text [nested → generated tree]
// output: { barrel: { type: 'named', nested: true } }
src/gen/cypress/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPetById, ...
│   └── getPetById.ts
└── store/
    ├── index.ts
    └── getInventory.ts
```

```text [false → result]
// output: { barrel: false }
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode` (the AST root with the path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Static banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: {
        path: 'cypress',
        banner: '/* eslint-disable */\n// @ts-nocheck',
      },
    }),
  ],
})
```

```typescript [Generated file]
/* eslint-disable */
// @ts-nocheck
export function getPetById({ path }: Omit<GetPetByIdRequestConfig, 'url'>, options: Partial<Cypress.RequestOptions> = {}): Cypress.Chainable<GetPetByIdResponse> {
  return cy
    .request<GetPetByIdResponse>({
      method: 'GET',
      url: `/pet/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

:::

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode` and returns the text.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Re-enable lint after a banner disable]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: {
        path: 'cypress',
        banner: '/* eslint-disable */',
        footer: '/* eslint-enable */',
      },
    }),
  ],
})
```

:::

### baseURL

Base URL added in front of every request URL. When omitted, the URL comes from the adapter's server URL (typically `servers[0].url`). Set it to point the helpers at a different environment (staging, production) than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

::: code-group

```typescript [Override the spec's server URL]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      baseURL: 'https://petstore.swagger.io/v2',
    }),
  ],
})
```

:::

### group

Splits generated files into subfolders by the operation's first tag or first path segment. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-group barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      group: { type: 'tag' },
    }),
  ],
})
```

:::

With the configuration above, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name. For example, `name: ({ group }) => \`${group}Controller\`` keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` reads the first segment of the operation's URL (`/pet/findByStatus` becomes `pet`).

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder name from the group key (the operation's first tag or first path segment).

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                   |
|  Default: | camelCased tag, or first path segment for `path` groups |

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

::: code-group

```typescript [Only the pet tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      include: [
        { type: 'method', pattern: 'GET' },
        { type: 'path', pattern: /^\/pet/ },
      ],
    }),
  ],
})
```

:::

### exclude

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

::: code-group

```typescript [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      exclude: [
        { type: 'operationId', pattern: 'deletePet' },
        { type: 'method', pattern: 'DELETE' },
      ],
    }),
  ],
})
```

:::

### override

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. That object accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

::: code-group

```typescript [Point the user tag at a different host]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      baseURL: 'https://petstore.swagger.io/v2',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { baseURL: 'https://users.petstore.swagger.io/v2' },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                        |
| --------: | :----------------------------------------------------- |
|     Type: | `Partial<ResolverCypress> & ThisType<ResolverCypress>` |
| Required: | `false`                                                |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript [Add an Api prefix to every name]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      resolver: {
        resolveName(name) {
          return `Api${this.default(name, 'function')}`
        },
      },
    }),
  ],
})
```

Each plugin ships with a default resolver:

| Plugin                 | Default resolver  |
| ---------------------- | ----------------- |
| `@kubb/plugin-ts`      | `resolverTs`      |
| `@kubb/plugin-zod`     | `resolverZod`     |
| `@kubb/plugin-faker`   | `resolverFaker`   |
| `@kubb/plugin-cypress` | `resolverCypress` |
| `@kubb/plugin-msw`     | `resolverMsw`     |
| `@kubb/plugin-mcp`     | `resolverMcp`     |
| `@kubb/plugin-client`  | `resolverClient`  |

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      macros: [
        {
          name: 'strip-descriptions',
          schema(node) {
            return { ...node, description: undefined }
          },
        },
      ],
    }),
  ],
})
```

```typescript [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      macros: [
        {
          name: 'prefix-operation-id',
          operation(node) {
            return { ...node, operationId: `api_${node.operationId}` }
          },
        },
      ],
    }),
  ],
})
```

:::

## Dependencies

This plugin needs the following plugin installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: {
        path: './cypress',
        barrel: { type: 'named' },
        banner: '/* eslint-disable */',
      },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Requests`,
      },
    }),
  ],
})
```

```typescript [Using a generated helper]
import { getPetById } from '../gen/cypress/petRequests'

describe('Pet API', () => {
  it('returns the pet by id', () => {
    getPetById({ path: { petId: 1 } }).then((pet) => {
      expect(pet.id).to.eq(1)
    })
  })
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-cypress/CHANGELOG.md)
