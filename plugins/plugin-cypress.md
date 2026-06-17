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

Generate one typed `cy.request()` wrapper per OpenAPI operation. Each helper has typed path params, body, query, and response, so a broken API call shows up at compile time instead of inside the test runner. Use them in `before`/`beforeEach` hooks to seed data, in custom commands, or in API-only specs.

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

Where the generated Cypress helpers are written and how they are exported.

|           |                                                  |
| --------: | :----------------------------------------------- |
|     Type: | `Output`                                         |
| Required: | `false`                                          |
|  Default: | `{ path: 'cypress', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Point `path` at a folder to keep each generator's output isolated, such as `'types'` or `'clients'`. To write everything into one file, set `output.mode: 'file'` and point `path` at the target file with its extension (e.g. `'types.ts'`).

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

- `'directory'` writes one file per operation or schema under `output.path`. This is the default.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'types.ts'`, `'models.py'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`, since a single-file output has nothing to group. Combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: { barrel: { type: 'named' } },
    }),
  ],
})
```

```typescript [src/gen/cypress/index.ts]
export { getPetById } from './getPetById'
export { getInventory } from './getInventory'
```

```typescript ['all']
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: { barrel: { type: 'all' } },
    }),
  ],
})
```

```typescript [src/gen/cypress/index.ts]
export * from './getPetById'
export * from './getInventory'
```

```typescript [nested]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: { barrel: { type: 'named', nested: true } },
    }),
  ],
})
```

```text [Generated tree]
src/gen/cypress/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPetById, ...
│   └── getPetById.ts
└── store/
    ├── index.ts
    └── getInventory.ts
```

```typescript [false]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: { barrel: false },
    }),
  ],
})
```

```text [Result]
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text prepended to every generated file, for license headers, lint disables, or `@ts-nocheck` directives. Pass a string for a static banner, or a function that computes it from each file's `RootNode` (the AST root holding path, schema, and operation context).

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
        banner: '/* eslint-disable */\n// @ts-nocheck',
      },
    }),
  ],
})
```

```typescript [Generated file]
/* eslint-disable */
// @ts-nocheck
export function getPetById(petId: GetPetByIdPathPetId, options: Partial<Cypress.RequestOptions> = {}): Cypress.Chainable<GetPetByIdResponse> {
  return cy
    .request<GetPetByIdResponse>({
      method: 'GET',
      url: `/pet/${petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

```typescript [Dynamic banner]
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
        banner: (node) => `// Source: ${node.path}\n// Generated at ${new Date().toISOString()}`,
      },
    }),
  ],
})
```

:::

#### output.footer

Text appended to every generated file, the counterpart to `banner`, for closing comments, re-enabling lint rules, or marker lines. Pass a string for a static footer, or a function that receives the file's `RootNode` and returns the footer text.

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
        banner: '/* eslint-disable */',
        footer: '/* eslint-enable */',
      },
    }),
  ],
})
```

:::

#### output.override

Lets the plugin overwrite hand-written files that share a name with a generated file.

- `false` (default): Kubb skips a file if it already exists and is not marked as generated. This protects manual edits.
- `true`: Kubb overwrites any file at the target path, including hand-written ones.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!WARNING]
> Enable this only when you are sure the target folder contains nothing you need to keep. Local edits are lost on the next generation.

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
      output: { override: true },
    }),
  ],
})
```

:::

### resolver

Overrides how the plugin builds names and paths for generated files and symbols. Use it to add prefixes, suffixes, or swap the casing strategy without forking the plugin. Override only the methods you want to change. Anything you omit, or a method that returns `null` or `undefined`, falls back to the default resolver. Inside each method, `this` is bound to the full resolver, so you can call `this.default(name, 'function')` to delegate to the built-in implementation.

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

### paramsType

How operation parameters (path, query, headers) are exposed in the generated function signature.

- `'inline'` (default): each parameter is a separate positional argument. Compact for operations with one or two params.
- `'object'`: every parameter is wrapped in a single object argument. Reads better for operations with many params and names each one at the call site.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

> [!TIP]
> Setting `paramsType: 'object'` implicitly sets `pathParamsType: 'object'` as well, so call sites are consistent.

::: code-group

```typescript ['inline' (default)]
export function updatePet(
  petId: UpdatePetPathPetId,
  data?: UpdatePetData,
  params?: { status?: UpdatePetQueryStatus },
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<UpdatePetResponse> {
  // ...
}
```

```typescript [Caller]
updatePet(42, { name: 'Fido' }, { status: 'available' })
```

```typescript ['object']
export function updatePet(
  { petId, data, params }: { petId: UpdatePetPathPetId; data?: UpdatePetData; params?: { status?: UpdatePetQueryStatus } },
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<UpdatePetResponse> {
  // ...
}
```

```typescript [Caller]
updatePet({ petId: 42, data: { name: 'Fido' }, params: { status: 'available' } })
```

:::

### paramsCasing

Renames the path, query, and header parameters in the generated helpers to camelCase. The request still carries the original names from the spec, and Kubb writes the mapping back for you. So `'camelcase'` turns `page_size` into `pageSize` in your TypeScript code, while the request `qs` still sends `page_size`.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

> [!IMPORTANT]
> Set the same `paramsCasing` on `@kubb/plugin-ts`. The Cypress helpers reuse the types that `@kubb/plugin-ts` generates, so mismatched casing produces type errors between the two layers.

::: code-group

```typescript [With paramsCasing: 'camelcase']
// The argument is camelCase, the request maps it back to page_size
export function getPets(params?: { pageSize?: GetPetsQueryPageSize }, options: Partial<Cypress.RequestOptions> = {}): Cypress.Chainable<GetPetsResponse> {
  return cy
    .request<GetPetsResponse>({
      method: 'GET',
      url: `/pets`,
      qs: params ? { page_size: params.pageSize } : undefined,
      ...options,
    })
    .then((res) => res.body)
}
```

```typescript [Without paramsCasing]
// The argument mirrors the spec name
export function getPets(params?: { page_size?: GetPetsQueryPageSize }, options: Partial<Cypress.RequestOptions> = {}): Cypress.Chainable<GetPetsResponse> {
  return cy
    .request<GetPetsResponse>({
      method: 'GET',
      url: `/pets`,
      qs: params,
      ...options,
    })
    .then((res) => res.body)
}
```

:::

### pathParamsType

How URL path parameters appear in the generated function signature. Affects only path params. Query params follow `paramsType`.

- `'inline'` (default): each path param is a positional argument, as in `showPetById(petId)`.
- `'object'`: path params are wrapped in a single object, as in `showPetById({ petId })`.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

::: code-group

```typescript ['inline' (default)]
export function showPetById(
  petId: ShowPetByIdPathPetId,
  params?: { limit?: ShowPetByIdQueryLimit },
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  // ...
}
```

```typescript ['object']
export function showPetById(
  { petId }: { petId: ShowPetByIdPathPetId },
  params?: { limit?: ShowPetByIdQueryLimit },
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  // ...
}
```

:::

### dataReturnType

Shape of the value each generated helper resolves to.

- `'data'` resolves to the response body only.
- `'full'` resolves to the full Cypress response object, so you can read `status`, `headers`, and `body`.

|           |                    |
| --------: | :----------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`            |
|  Default: | `'data'`           |

::: code-group

```typescript ['data' (default)]
// Cypress.Chainable<ShowPetByIdResponse>
showPetById(1).then((pet) => {
  expect(pet.id).to.eq(1)
})
```

```typescript ['full']
// Cypress.Chainable<Cypress.Response<ShowPetByIdResponse>>
showPetById(1).then((response) => {
  expect(response.status).to.eq(200)
  expect(response.body.id).to.eq(1)
})
```

:::

### baseURL

Base URL prepended to every request URL in the generated client. When omitted, the URL comes from the spec's `servers[0].url` (or whichever index the adapter reads). Set it to point the client at a different environment (staging, production) than the spec.

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

Splits generated files into subfolders by the operation's tag or first path segment, so related helpers share a directory. Without `group`, every file lands in the plugin's `output.path` folder. With `group`, files go under `{output.path}/{groupName}/`, where `groupName` comes from the operation's first tag or first path segment.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default), where each group becomes a folder. It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

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

```text
src/gen/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name, for example `name: ({ group }) => \`${group}Controller\`` to keep the pre-v5 `petController/` layout.

#### group.type

Property that assigns each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` reads the first segment of the operation's URL (`/pet/findByStatus` becomes `pet`).

|           |                  |
| --------: | :--------------- |
|     Type: | `'tag' \| 'path'`|
| Required: | `true`           |

> [!NOTE]
> `Required` here is conditional. It applies only when the parent `group` option is set, and `group` itself stays optional.

#### group.name

Function that builds the folder name from the group key (the operation's first tag or first path segment).

|           |                                       |
| --------: | :------------------------------------ |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                               |
|  Default: | camelCased tag, or first path segment for `path` groups |

### include

Restricts generation to operations that match at least one entry in the list. Anything not matched is skipped.

Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL pattern (`'/pet/{petId}'`).
- `method`: the HTTP method (`'get'`, `'post'`, ...).
- `contentType`: the media type of the request body.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
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
        { type: 'method', pattern: 'get' },
        { type: 'path', pattern: /^\/pet/ },
      ],
    }),
  ],
})
```

:::

### exclude

Skips any operation that matches at least one entry in the list. The opposite of `include`.

Each entry filters by one of:

- `tag`: the operation's first tag.
- `operationId`: the operation's `operationId`.
- `path`: the URL pattern (`'/pet/{petId}'`).
- `method`: the HTTP method (`'get'`, `'post'`, ...).
- `contentType`: the media type of the request body.

`pattern` accepts a plain string or a `RegExp`. When both `include` and `exclude` are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
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
        { type: 'method', pattern: 'delete' },
      ],
    }),
  ],
})
```

:::

### override

Applies a different set of plugin options to operations that match a pattern. Use this when most of your API follows the global config but a handful of endpoints need different treatment. Each entry shares the `type` and `pattern` shape of `include` and `exclude`, plus an `options` object that overrides the plugin's options for the matched operations. Entries are evaluated top to bottom: the first match's `options` is merged onto the plugin defaults, and later entries do not stack.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
  pattern: string | RegExp
  options: PluginOptions
}
```

::: code-group

```typescript [Return the full response for the user tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      dataReturnType: 'data',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { dataReturnType: 'full' },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run alongside the plugin's built-in ones. Each generator can emit extra files or post-process existing ones using the plugin's AST and options. Use this for output the plugin does not produce itself (a custom client wrapper, an extra index, a metadata file). See [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                   |
| --------: | :-------------------------------- |
|     Type: | `Array<Generator<PluginCypress>>` |
| Required: | `false`                           |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### macros

Rewrite AST nodes before they are printed to source code, to rewrite operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (e.g. `schema`, `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it untouched. Callbacks you omit keep the default behavior. Macros run in order, so a later macro sees the output of an earlier one.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

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

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)

## Example

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
      output: {
        path: './cypress',
        barrel: { type: 'named' },
        banner: '/* eslint-disable */',
      },
      dataReturnType: 'full',
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
    getPetById(1).then((response) => {
      expect(response.status).to.eq(200)
      expect(response.body.id).to.eq(1)
    })
  })
})
```

:::
