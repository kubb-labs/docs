---
layout: doc
title: Kubb Zod Plugin
description: Generate Zod v4 schemas from OpenAPI for runtime validation that
  stays in sync with your TypeScript types.
outline: 2
kind: plugin
id: plugin-zod
name: Zod
category: validation
type: official
npmPackage: "@kubb/plugin-zod"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-zod
featured: true
icon:
  light: https://kubb.dev/feature/zod.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - zod
  - validation
  - schema
  - runtime-validation
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-zod
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/zod
---

# @kubb/plugin-zod

`@kubb/plugin-zod` turns your OpenAPI schemas into [Zod](https://zod.dev/) v4 schemas. Use them to validate API responses at runtime, build form schemas, or feed router libraries that take Zod (`tRPC`, `Hono`, `Elysia`).

Pair it with `@kubb/plugin-client` and set the client's `parser: 'zod'` to validate every response.

**See also**

- [Zod](https://zod.dev/)
- [Zod Mini](https://zod.dev/packages/mini)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-zod@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-zod@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-zod@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-zod@beta
```

:::

## Options

> [!NOTE]
> Schema-shaping options such as `enum`, `dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, and `contentType` moved to [`@kubb/adapter-oas`](/adapters/adapter-oas) in v5. Set them with `adapterOas({ ... })` instead of on this plugin.

### output

Where the generated Zod schemas are written and how they are exported.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Output`                                     |
| Required: | `false`                                      |
|  Default: | `{ path: 'zod', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code, resolved against the global `output.path` set on `defineConfig`. To put everything in one file instead, set `output.mode: 'file'` and point `path` at a target file including its extension (e.g. `'types.ts'`).

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |
|  Default: | `'zod'`  |

> [!TIP]
> `output.path` sets where files go. `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── types/
        ├── Pet.ts
        └── Store.ts
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

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'types.ts', mode: 'file' },
    }),
    pluginClient({
      output: { path: 'clients', mode: 'directory' },
      group: { type: 'tag' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    ├── types.ts
    └── clients/
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

```typescript twoslash ['named' (default)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'types', barrel: { type: 'named' } },
    }),
  ],
})
```

```typescript [src/gen/types/index.ts]
export { Pet, PetStatus } from './Pet'
export { Store } from './Store'
```

```typescript ['all' → src/gen/types/index.ts]
// output: { barrel: { type: 'all' } }
export * from './Pet'
export * from './Store'
```

```text [nested → generated tree]
// output: { barrel: { type: 'named', nested: true } }
src/gen/types/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports Pet, Store, ...
│   └── Pet.ts
└── store/
    ├── index.ts
    └── Store.ts
```

```text [false → result]
// output: { barrel: false }
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text prepended to every generated file, for license headers, lint disables, or `@ts-nocheck` directives. Pass a string for a static banner, or a function to compute it from each file's `RootNode` (the AST root holding path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript twoslash [Static banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        path: 'types',
        banner: '/* eslint-disable */\n// @ts-nocheck',
      },
    }),
  ],
})
```

```typescript [Generated file]
/* eslint-disable */
// @ts-nocheck
export type Pet = {
  id: number
  name: string
}
```

```typescript twoslash [Dynamic banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        path: 'types',
        banner: (node) => `// Source: ${node.filePath}\n// Generated at ${new Date().toISOString()}`,
      },
    }),
  ],
})
```

:::

#### output.footer

Text appended to every generated file. Mirrors `banner`, for closing comments, re-enabling lint rules, or marker lines. Pass a string or a function that receives the file's `RootNode` and returns the footer text.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript twoslash [Re-enable lint after a banner disable]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        path: 'types',
        banner: '/* eslint-disable */',
        footer: '/* eslint-enable */',
      },
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverZod> & ThisType<ResolverZod>` |
| Required: | `false`                                        |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript twoslash [Add an Api prefix to every name]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      resolver: {
        resolveTypeName(name) {
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

### group

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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
│   ├── AddPet.ts
│   └── GetPet.ts
└── store/
    ├── CreateStore.ts
    └── GetStoreById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Controller` to the group keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

Operations with no tag are placed in a default group.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used. `group` itself stays optional.

#### group.name

Function that builds the folder/identifier name from a group key (the operation's first tag).

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### importPath

Module specifier for the `import { z } from '...'` statement at the top of every generated file. Set it to re-export Zod from your own module. It defaults to `'zod'`, or to `'zod/mini'` when the `mini` option is on.

|           |                             |
| --------: | :-------------------------- |
|     Type: | `string`                    |
| Required: | `false`                     |
|  Default: | `mini ? 'zod/mini' : 'zod'` |

::: code-group

```typescript ['zod' (default)]
import { z } from 'zod'
```

```typescript ['zod/mini']
import { z } from 'zod/mini'
```

```typescript [Your own module]
// importPath: '../lib/zod'
import { z } from '../lib/zod'
```

:::

### typed

Ties each Zod schema to its TypeScript type from `@kubb/plugin-ts`. With `typed: true`, the generated `petSchema` is typed as `ToZod<Pet>`. TypeScript then fails to compile when the schema drifts from the type. This needs `@kubb/plugin-ts` in the plugins list.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!IMPORTANT]
> The mapping uses a [ToZod-style](https://github.com/colinhacks/tozod) helper (vendored in Kubb) to derive a Zod shape from a TypeScript type.

::: code-group

```typescript [typed: true]
import { z } from 'zod'
import type { ToZod } from '@kubb/plugin-zod'
import type { Pet } from '../ts/Pet'

export const petSchema: ToZod<Pet> = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

```typescript [typed: false (default)]
import { z } from 'zod'

export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

:::

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema. The Zod schema becomes the single source of truth, so you do not import types from `@kubb/plugin-ts`. The alias is the PascalCased schema name with a `SchemaType` suffix (`petSchema` becomes `PetSchemaType`). The value and its inferred type never share a name, even for all-uppercase names like `SUV` or `URL`.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

::: code-group

```typescript [inferred: true]
import { z } from 'zod'

export const petSchema = z.object({
  name: z.string(),
})

export type PetSchemaType = z.infer<typeof petSchema>
```

```typescript [inferred: false (default)]
import { z } from 'zod'

export const petSchema = z.object({
  name: z.string(),
})
```

:::

### coercion

Wraps schemas in `z.coerce` so input is coerced to the expected type before validation. Use it for form data, query params, and any source where everything arrives as a string.

- `true` coerces strings, numbers, and dates.
- `false` (default) coerces nothing and validates strictly.
- An object picks which primitives to coerce.

See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `boolean \| { dates?: boolean; strings?: boolean; numbers?: boolean }` |
| Required: | `false`                                                                |
|  Default: | `false`                                                                |

> [!TIP]
> When `@kubb/adapter-oas` runs with `dateType: 'date'` (date fields typed as `Date`), the generated schemas round-trip dates at the validation boundary instead of coercing. Response schemas decode the ISO `string` into a `Date` (`z.iso.datetime().transform(...)`), and an `${name}InputSchema` variant encodes `Date` back into an ISO `string` (`z.date().transform(...)`) for request bodies. So `coercion.dates` has no effect on these fields.

::: code-group

```typescript [coercion: true]
z.coerce.string()
z.coerce.date()
z.coerce.number()
```

```typescript [coercion: false (default)]
z.string()
z.date()
z.number()
```

```typescript [Coerce numbers only]
// { numbers: true, strings: false, dates: false }
z.string()
z.date()
z.coerce.number()
```

:::

### operations

Emits an `operations.ts` file. It groups the schemas per operation: request body, path/query/header params, each response status, and errors. The map is keyed by `operationId`, and a `paths` map links each URL and method back to it. Use it when you wire Kubb output into a server framework that takes one set of Zod schemas per route.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

::: code-group

```typescript [operations: true → operations.ts]
export const operations = {
  getPetById: {
    request: undefined,
    parameters: {
      path: getPetByIdPathParamsSchema,
      query: undefined,
      header: undefined,
    },
    responses: {
      200: getPetById200Schema,
    },
    errors: {},
  },
} as const

export const paths = {
  '/pet/{petId}': {
    get: operations['getPetById'],
  },
} as const
```

```typescript [operations: false (default)]
// No operations.ts is generated.
```

:::

### paramsCasing

Renames the properties inside the path, query, and header schemas to camelCase. Body schemas stay untouched. Set the same value on `@kubb/plugin-ts` so the Zod schemas stay assignable to the generated types.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

```typescript [paramsCasing: 'camelcase']
// OpenAPI spec uses: pet_id, X-Api-Key
export const getPetPathParamsSchema = z.object({
  petId: z.string(),
})

export const getPetHeaderParamsSchema = z.object({
  xApiKey: z.string().optional(),
})
```

### guidType

Validator used for OpenAPI properties with `format: uuid`.

- `'uuid'` (default) generates `z.uuid()`, a standard RFC 4122 UUID.
- `'guid'` generates `z.guid()`, which is looser and accepts Microsoft-style GUIDs.

|           |                    |
| --------: | :----------------- |
|     Type: | `'uuid' \| 'guid'` |
| Required: | `false`            |
|  Default: | `'uuid'`           |

::: code-group

```typescript ['uuid' (default)]
z.uuid()
```

```typescript ['guid']
z.guid()
```

:::

### mini

Switches code generation to [Zod Mini](https://zod.dev/packages/mini). Schemas use the functional API (`z.optional(z.string())`) instead of the chainable one (`z.string().optional()`). Bundlers can then tree-shake unused validators. Setting `mini: true` also defaults `importPath` to `'zod/mini'`.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!TIP]
> Use Zod Mini in code that ships to the browser. The functional API drops several kilobytes from the bundle compared to the standard Zod build.

> [!WARNING]
> Zod Mini is currently in beta. Its API may change in a future release.

::: code-group

```typescript [mini: true]
import { z } from 'zod/mini'

z.optional(z.string())
z.nullable(z.number())
z.array(z.string()).check(z.minLength(1), z.maxLength(10))
```

```typescript [mini: false (default)]
import { z } from 'zod'

z.string().optional()
z.number().nullable()
z.array(z.string()).min(1).max(10)
```

:::

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request body media type, such as `'application/json'`.
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

```typescript twoslash [Only the pet tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript twoslash [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Skips any operation or schema that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

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

```typescript twoslash [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript twoslash [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

```typescript twoslash [Coerce input only for the user tag]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      coercion: false,
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { coercion: true },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run next to the built-in ones. Each generator can emit extra files or post-process existing ones using the plugin's AST and options. Use it for output the plugin does not produce, such as a custom client wrapper or a metadata file. See [Creating plugins](/docs/5.x/guides/creating-plugins).

|           |                               |
| --------: | :---------------------------- |
|     Type: | `Array<Generator<PluginZod>>` |
| Required: | `false`                       |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript twoslash [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

```typescript twoslash [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

### printer

Replaces the Zod handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Zod expression as a string.

When `mini: true`, overrides target the Zod Mini printer. Otherwise they target the standard Zod printer.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` |
| Required: | `false`                                              |

::: code-group

```typescript twoslash [Use z.number() for integers]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      printer: {
        nodes: {
          integer() {
            return 'z.number()'
          },
        },
      },
    }),
  ],
})
```

```typescript twoslash [Use z.string().date() for date schemas]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      printer: {
        nodes: {
          date() {
            return 'z.string().date()'
          },
        },
      },
    }),
  ],
})
```

:::

### wrapOutput

Wraps the generated Zod schema string with extra calls before it is written to disk. The callback receives the raw schema string and its `SchemaNode`. Return a new string to replace the output, or `undefined` to leave it untouched.

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `(arg: { output: string; schema: SchemaNode }) => string \| undefined` |
| Required: | `false`                                                                |

> [!TIP]
> Use this to round-trip OpenAPI metadata back into Zod, such as examples, descriptions, or `.openapi()` annotations for libraries that re-emit OpenAPI from Zod schemas.

```typescript twoslash [Append .openapi() with metadata]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      wrapOutput: ({ output, schema }) => {
        const metadata: Record<string, unknown> = {}

        if (schema.examples?.length) {
          // Pull example metadata off the SchemaNode here
        }

        if (Object.keys(metadata).length > 0) {
          return `${output}.openapi(${JSON.stringify(metadata)})`
        }

        return undefined
      },
    }),
  ],
})
```

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod({
      output: { path: './zod' },
      group: { type: 'tag', name: ({ group }) => `${group}Schemas` },
      typed: true,
      importPath: 'zod',
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
