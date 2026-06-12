---
layout: doc
title: Kubb Zod Plugin
description: Generate Zod v4 schemas from OpenAPI for runtime validation that
  stays in sync with your TypeScript types.
outline: 2
kind: plugin
id: plugin-zod
---

# @kubb/plugin-zod

Generate [Zod](https://zod.dev/) v4 schemas from your OpenAPI spec. Use them to validate API responses at runtime, build form schemas, or feed back into router libraries that consume Zod (`tRPC`, `Hono`, `Elysia`).

Pair with `@kubb/plugin-client` and set the client's `parser: 'zod'` to validate every response automatically.

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

### output

Where the generated Zod schemas are written and how they are exported.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Output`                                     |
| Required: | `false`                                      |
|  Default: | `{ path: 'zod', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Use a folder to keep each generator's output isolated (`'types'`, `'clients'`, `'hooks'`). To put everything in one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |
|  Default: | `'zod'`  |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. See `output.mode` for the single-file and one-file-per-group layouts.

::: code-group

```typescript [kubb.config.ts]
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
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group` — a single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

::: code-group

```typescript [kubb.config.ts]
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

```typescript ['named' (default)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'named' } },
    }),
  ],
})
```

```typescript [src/gen/types/index.ts]
export { Pet, PetStatus } from './Pet'
export { Store } from './Store'
```

```typescript ['all']
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'all' } },
    }),
  ],
})
```

```typescript [src/gen/types/index.ts]
export * from './Pet'
export * from './Store'
```

```typescript [nested]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'named', nested: true } },
    }),
  ],
})
```

```text [Generated tree]
src/gen/types/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports Pet, Store, ...
│   └── Pet.ts
└── store/
    ├── index.ts
    └── Store.ts
```

```typescript [false]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Text prepended to every generated file. Useful for license headers, lint disables, or `@ts-nocheck` directives.

Pass a string for a static banner. Pass a function to compute the banner from each file's `RootNode` (the AST root containing path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Static banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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
export type Pet = {
  id: number
  name: string
}
```

```typescript [Dynamic banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        banner: (node) => `// Source: ${node.path}\n// Generated at ${new Date().toISOString()}`,
      },
    }),
  ],
})
```

:::

#### output.footer

Text appended at the end of every generated file. The mirror of `banner` — use it for closing comments, re-enabling lint rules, or marker lines.

Pass a string for a static footer, or a function that receives the file's `RootNode` and returns the footer text.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Re-enable lint after a banner disable]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Allows the plugin to overwrite hand-written files that share a name with a generated file.

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

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { override: true },
    }),
  ],
})
```

:::

### resolver

Overrides how the plugin builds names and paths for generated files and symbols. Use this to add prefixes, suffixes, or to swap the casing strategy without forking the plugin.

Only override the methods you want to change. Anything you omit falls back to the plugin's default resolver. A method that returns `null` or `undefined` also falls back.

Inside each method, `this` is bound to the full resolver, so you can call `this.default(name, 'function')` to delegate to the built-in implementation.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverZod> & ThisType<ResolverZod>` |
| Required: | `false`                                        |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `transformer` instead.

```typescript [Add an Api prefix to every name]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

### group

Splits generated files into subfolders based on the operation's tag, so each tag in your OpenAPI spec gets its own directory.

Without `group`, every file lands in the plugin's `output.path` folder. With `group`, files are bucketed under `{output.path}/{groupName}/`, where `groupName` is derived from the operation's first tag.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default), where each group becomes a folder. It is not valid with `output.mode: 'file'` — a single-file output has no grouping concept.

::: code-group

```typescript [kubb.config.ts]
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

```text
src/gen/
├── pet/
│   ├── AddPet.ts
│   └── GetPet.ts
└── store/
    ├── CreateStore.ts
    └── GetStoreById.ts
```

Pass `group.name` to customize the folder name, for example `name: ({ group }) => \`${group}Controller\``to keep the pre-v5`petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

Today only `'tag'` is supported: Kubb reads the first tag on the operation (`operation.getTags().at(0)?.name`) and uses it as the group key. Operations without a tag are placed in a default group.

|           |         |
| --------: | :------ |
|     Type: | `'tag'` |
| Required: | `true`  |

> [!NOTE]
> `Required: true*` is conditional — only required when the parent `group` option is used. `group` itself stays optional.

#### group.name

Function that builds the folder/identifier name from a group key (the operation's first tag).

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### importPath

Module specifier used in the `import { z } from '...'` statement at the top of generated files.

Defaults to `'zod'`, or `'zod/mini'` when the `mini` option is enabled. Set it explicitly to import from a custom path, for example when re-exporting Zod from your own module.

|           |                             |
| --------: | :-------------------------- |
|     Type: | `string`                    |
| Required: | `false`                     |
|  Default: | `mini ? 'zod/mini' : 'zod'` |

::: code-group

```typescript [Use Zod's mini bundle]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginZod({ importPath: 'zod/mini' })],
})
```

:::

### typed

Adds a type annotation that ties each Zod schema to its TypeScript counterpart from `@kubb/plugin-ts`.

With `typed: true`, the generated `petSchema` is typed as `ToZod<Pet>` — TypeScript will fail compilation when the schema drifts from the type. Requires `@kubb/plugin-ts` in the plugins list.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!IMPORTANT]
> The mapping uses a [ToZod-style](https://github.com/colinhacks/tozod) helper (vendored in Kubb) to derive a Zod shape from a TypeScript type.

::: code-group

```typescript [Schema linked to its TS type]
import { z } from 'zod'
import type { ToZod } from '@kubb/plugin-zod'
import type { Pet } from '../ts/Pet'

export const petSchema: ToZod<Pet> = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

:::

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema. The alias is the PascalCased schema name with a `SchemaType` suffix (`petSchema` → `PetSchemaType`), so the schema value and its inferred type never share an identifier, even for all-uppercase names like `SUV` or `URL`.

Use this when you want one source of truth (the Zod schema) and a TypeScript type derived from it, instead of importing types separately from `@kubb/plugin-ts`.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

```typescript [With inferred enabled]
import { z } from 'zod'

export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})

export type PetSchemaType = z.infer<typeof petSchema>
```

### integerType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#integerType). Use `adapterOas({ integerType })` instead.

### unknownType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#unknownType). Use `adapterOas({ unknownType })` instead.

### emptySchemaType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#emptySchemaType). Use `adapterOas({ emptySchemaType })` instead.

### coercion

Wraps schemas in `z.coerce` so input is coerced to the expected type before validation. Useful for form data, query params, and any source where everything arrives as a string.

- `true` — coerce strings, numbers, and dates.
- `false` (default) — no coercion. Strict validation.
- Object — pick which primitives to coerce.

See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` |
| Required: | `false`                                                                |
|  Default: | `false`                                                                |

> [!TIP]
> When `@kubb/adapter-oas` runs with `dateType: 'date'` (date fields typed as `Date`), the generated schemas round-trip dates at the validation boundary rather than coercing: response schemas decode the ISO `string` into a `Date` (`z.iso.datetime().transform(...)`), and an `${name}InputSchema` variant encodes `Date` back into an ISO `string` (`z.date().transform(...)`) for request bodies. `coercion.dates` has no effect on these fields.

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

Emits an `operations.ts` file that groups schemas per operation: request body, query params, path params, and each response status.

Use this to validate or describe whole operations in one place — handy when wiring Kubb output into a server framework that takes Zod schemas per route.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### paramsCasing

Renames properties inside the path/query/header schemas to the chosen casing. Body schemas are unaffected.

Must match the value of `paramsCasing` on `@kubb/plugin-ts` so the generated Zod schemas stay assignable to the generated types.

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

- `'uuid'` (default) — `z.uuid()`. Standard RFC 4122 UUID.
- `'guid'` — `z.guid()`. Looser; accepts Microsoft-style GUIDs (allows lowercase, mixed brace styles).

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

Switches code generation to [Zod Mini](https://zod.dev/packages/mini). Schemas use the functional API (`z.optional(z.string())`) instead of the chainable one (`z.string().optional()`), which lets bundlers tree-shake unused validators.

Setting `mini: true` also defaults `importPath` to `'zod/mini'`.

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

Restricts generation to operations that match at least one entry in the list. Anything not matched is skipped.

Each entry filters by one of:

- `tag` — the operation's first tag in the OpenAPI spec.
- `operationId` — the operation's `operationId`.
- `path` — the URL pattern (`'/pet/{petId}'`).
- `method` — HTTP method (`'get'`, `'post'`, ...).
- `contentType` — the media type of the request body.

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

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

- `tag` — the operation's first tag.
- `operationId` — the operation's `operationId`.
- `path` — the URL pattern (`'/pet/{petId}'`).
- `method` — HTTP method (`'get'`, `'post'`, ...).
- `contentType` — the media type of the request body.

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

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Applies a different set of plugin options to operations that match a pattern. Use this when most of your API should follow the global config, but a handful of endpoints need different treatment.

Each entry has the same `type` and `pattern` shape as `include`/`exclude`, plus an `options` object that overrides the plugin's options for matched operations.

Entries are evaluated top to bottom. The first matching entry's `options` is merged onto the plugin defaults; later entries do not stack.

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

```typescript [Use a different enum style for the user tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enumType: 'asConst',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { enumType: 'literal' },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run alongside the plugin's built-in generators. Each generator can emit additional files or post-process existing ones using the plugin's AST and options.

Use this when you need output the plugin does not produce out of the box (a custom client wrapper, an extra index, a metadata file). For end-to-end guidance, see [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                               |
| --------: | :---------------------------- |
|     Type: | `Array<Generator<PluginZod>>` |
| Required: | `false`                       |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### transformer

Modifies AST nodes before they are printed to source code. Use this when you need to rewrite operation IDs, drop descriptions, or change schema metadata without forking the generator.

Each visitor method (e.g. `schema`, `operation`) receives the node and a context object. Return a new node to replace it, or return `undefined` to leave it untouched. Methods you omit keep the plugin's default behavior.

|           |           |
| --------: | :-------- |
|     Type: | `Visitor` |
| Required: | `false`   |

> [!TIP]
> Use `transformer` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      transformer: {
        schema(node) {
          return { ...node, description: undefined }
        },
      },
    }),
  ],
})
```

```typescript [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      transformer: {
        operation(node) {
          return { ...node, operationId: `api_${node.operationId}` }
        },
      },
    }),
  ],
})
```

:::

### printer

Replaces the Zod handler for a specific schema type (e.g. `'integer'`, `'date'`, `'string'`). Each handler returns the Zod expression as a string.

When `mini: true`, overrides target the Zod Mini printer; otherwise they target the standard Zod printer.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` |
| Required: | `false`                                              |

::: code-group

```typescript [Use z.number() for integers]
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

```typescript [Use z.string().date() for date schemas]
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

Lets you wrap the generated Zod schema string with extra calls before it is written to disk. The callback receives the raw schema output and the originating `SchemaNode`.

Return a new string to replace the output, or return `undefined` to leave it untouched.

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `(arg: { output: string; schema: SchemaNode }) => string \| undefined` |
| Required: | `false`                                                                |

> [!TIP]
> Use this to round-trip metadata from OpenAPI back into Zod — examples, descriptions, or `.openapi()` annotations for libraries that re-emit OpenAPI from Zod schemas.

```typescript [Append .openapi() with metadata]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginZod({
      wrapOutput: ({ output, schema }) => {
        const metadata: Record<string, unknown> = {}

        if (schema.keywords?.includes('example')) {
          // Pull keyword metadata off the SchemaNode here
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

```typescript [kubb.config.ts]
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
