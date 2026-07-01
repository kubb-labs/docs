---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-zod.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'zod' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`importPath`](#importpath) | `string` | `mini ? 'zod/mini' : 'zod'` | Module the generated files import `z` from |
| [`typed`](#typed) | `boolean` | — | Tie each schema to its `@kubb/plugin-ts` type |
| [`inferred`](#inferred) | `boolean` | — | Emit a `z.infer` alias next to each schema |
| [`coercion`](#coercion) | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` | `false` | Coerce input before validation |
| [`guidType`](#guidtype) | `'uuid' \| 'guid'` | `'uuid'` | Validator for `format: uuid` properties |
| [`regexType`](#regextype) | `'literal' \| 'constructor'` | `'literal'` | How an OpenAPI `pattern` is written |
| [`mini`](#mini) | `boolean` | `false` | Generate Zod Mini schemas |
| [`wrapOutput`](#wrapoutput) | `(arg) => string \| undefined` | — | Wrap each schema string with extra calls |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverZod>` | — | Customize generated names and file paths |
| [`printer`](#printer) | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` | — | Replace the handler for a schema type |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'zod', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'zod.ts'`.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'zod'`  |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'zod.ts'`).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'directory' \| 'file'` |
| Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

- `{ type: 'named' }` re-exports each symbol by name. Best for tree-shaking and explicit imports.
- `{ type: 'all' }` uses `export *`. Smaller barrel file, but exports everything.
- `{ nested: true }` creates a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel entirely. The plugin's files are also excluded from the root `index.ts`.

|          |                                                         |
| -------: | :------------------------------------------------------ |
|    Type: | `{ type: 'named' \| 'all', nested?: boolean } \| false` |
| Default: | `{ type: 'named' }`                                     |

> [!TIP]
> Pick `'named'` when consumers care about which symbols they import (better tree-shaking, friendlier auto-import). Pick `'all'` when the file count is small and you want a one-line barrel.

::: code-group

```typescript ['named' (default)]
// src/gen/zod/index.ts
export { petSchema, petStatusSchema } from './petSchema'
export { storeSchema } from './storeSchema'
```

```typescript ['all']
// src/gen/zod/index.ts
export * from './petSchema'
export * from './storeSchema'
```

```text [nested]
src/gen/zod/
├── index.ts             # re-exports ./pet and ./store
├── pet/
│   ├── index.ts         # re-exports petSchema, ...
│   └── petSchema.ts
└── store/
    ├── index.ts
    └── storeSchema.ts
```

```text [false]
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode` (the AST root with the path, schema, and operation context).

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((node: RootNode) => string)` |

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})
```

A function banner builds the text from the file's `RootNode`, such as `banner: (node) => \`// Source: ${node.filePath}\``.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((node: RootNode) => string)` |

### group

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|          |         |
| -------: | :------ |
|    Type: | `Group` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── addPetSchema.ts
│   └── getPetSchema.ts
└── store/
    ├── createStoreSchema.ts
    └── getStoreByIdSchema.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Controller` to the group keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

Operations with no tag go in a default group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key (the operation's first tag) into a folder or identifier name. The result is used as both the subdirectory name under `output.path` and as a suffix when naming aggregate files.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: GroupContext) => string` |
| Default: | `(ctx) => camelCase(ctx.group)`         |

### importPath

Module specifier for the `import { z } from '...'` statement at the top of every generated file. Set it to re-export Zod from your own module. It defaults to `'zod'`, or to `'zod/mini'` when the `mini` option is on.

|          |                             |
| -------: | :-------------------------- |
|    Type: | `string`                    |
| Default: | `mini ? 'zod/mini' : 'zod'` |

::: code-group

```typescript ['zod' (default)]
import * as z from 'zod'
```

```typescript ['zod/mini']
import * as z from 'zod/mini'
```

```typescript [Your own module]
// importPath: '@acme/zod'
import { z } from '@acme/zod'
```

:::

You consume the schema the same way no matter where `z` comes from. The import line only changes inside the generated files:

```typescript
import { petSchema } from './src/gen/zod/petSchema'

const pet = petSchema.parse(data)
```

> [!NOTE]
> The `'zod'` and `'zod/mini'` modules import the `z` namespace (`import * as z`). A custom module imports the named `z` export (`import { z }`), so re-export `z` from there.

### typed

Ties each Zod schema to its TypeScript type from `@kubb/plugin-ts`. With `typed: true`, the generated `petSchema` is typed as `ToZod<Pet>`. TypeScript then fails to compile when the schema drifts from the type. This needs `@kubb/plugin-ts` in the plugins list.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |

> [!IMPORTANT]
> The mapping uses a [ToZod-style](https://github.com/colinhacks/tozod) helper (vendored in Kubb) to derive a Zod shape from a TypeScript type.

::: code-group

```typescript [typed: true]
import * as z from 'zod'
import type { ToZod } from '@kubb/plugin-zod'
import type { Pet } from '../ts/Pet'

export const petSchema: ToZod<Pet> = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

```typescript [typed unset (default)]
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

:::

You consume the schema the same way whether or not it is typed. `typed` only adds the compile-time `ToZod<Pet>` check on the schema declaration:

```typescript
import { petSchema } from './src/gen/zod/petSchema'

const pet = petSchema.parse(data)
```

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema. The Zod schema becomes the single source of truth, so you do not import types from `@kubb/plugin-ts`. The alias is the PascalCased schema name with a `SchemaType` suffix (`petSchema` becomes `PetSchemaType`). The value and its inferred type never share a name, even for all-uppercase names like `SUV` or `URL`.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |

::: code-group

```typescript [inferred: true]
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})

export type PetSchemaType = z.infer<typeof petSchema>
```

```typescript [inferred unset (default)]
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})
```

:::

Where the type comes from depends on the value:

::: code-group

```typescript [inferred: true]
import { petSchema, type PetSchemaType } from './src/gen/zod/petSchema'

const pet: PetSchemaType = petSchema.parse(data)
```

```typescript [inferred unset (default)]
import * as z from 'zod'
import { petSchema } from './src/gen/zod/petSchema'

type Pet = z.infer<typeof petSchema>
const pet: Pet = petSchema.parse(data)
```

:::

### coercion

Wraps schemas in `z.coerce` so input is coerced to the expected type before validation. Use it for form data, query params, and any source where everything arrives as a string.

- `true` coerces strings, numbers, and dates.
- `false` (default) coerces nothing and validates strictly.
- An object picks which primitives to coerce.

See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

|          |                                                                        |
| -------: | :--------------------------------------------------------------------- |
|    Type: | `boolean \| { dates?: boolean; strings?: boolean; numbers?: boolean }` |
| Default: | `false`                                                                |

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

Coercion changes what the schema accepts at `parse`:

::: code-group

```typescript [coercion: true]
import { querySchema } from './src/gen/zod/querySchema'

// strings, numbers, and dates are coerced
querySchema.parse({ count: '5', date: '2024-01-01' }) // { count: 5, date: Date }
```

```typescript [coercion: false (default)]
import { querySchema } from './src/gen/zod/querySchema'

querySchema.parse({ count: '5', date: '2024-01-01' }) // throws a ZodError, nothing is coerced
querySchema.parse({ count: 5, date: new Date() }) // ok
```

```typescript [Coerce numbers only]
import { querySchema } from './src/gen/zod/querySchema'

// only numbers are coerced, so the date must already be a Date
querySchema.parse({ count: '5', date: new Date() }) // { count: 5, date: Date }
querySchema.parse({ count: '5', date: '2024-01-01' }) // throws, the date is not coerced
```

:::

> [!NOTE]
> `coercion.dates` covers `date` and `datetime` string fields. Fields that Kubb represents as a JavaScript `Date` are generated with transform-based codecs rather than `z.coerce.date()`, so `coercion.dates` does not change them.

### guidType

Validator used for OpenAPI properties with `format: uuid`.

- `'uuid'` (default) generates `z.uuid()`, a standard RFC 4122 UUID.
- `'guid'` generates `z.guid()`, which is looser and accepts Microsoft-style GUIDs.

|          |                    |
| -------: | :----------------- |
|    Type: | `'uuid' \| 'guid'` |
| Default: | `'uuid'`           |

::: code-group

```typescript ['uuid' (default)]
z.uuid()
```

```typescript ['guid']
z.guid()
```

:::

You consume the schema the same way for both values. Only the accepted format changes, with `'uuid'` stricter than `'guid'`:

```typescript
import { idSchema } from './src/gen/zod/idSchema'

const id = idSchema.parse('123e4567-e89b-12d3-a456-426614174000')
```

### regexType

Controls how an OpenAPI `pattern` is written inside `.regex(...)`.

- `'literal'` (default) emits a regex literal, such as `.regex(/^[a-z]+$/)`.
- `'constructor'` emits the `RegExp` constructor, such as `.regex(new RegExp("^[a-z]+$"))`.

Reach for `'constructor'` when a regex literal trips up your build pipeline or when you need the pattern as a plain string.

|          |                              |
| -------: | :--------------------------- |
|    Type: | `'literal' \| 'constructor'` |
| Default: | `'literal'`                  |

::: code-group

```typescript ['literal' (default)]
z.string().regex(/^[a-z]+$/)
```

```typescript ['constructor']
z.string().regex(new RegExp('^[a-z]+$'))
```

:::

Both forms validate identically at runtime, so you consume the schema the same way:

```typescript
import { slugSchema } from './src/gen/zod/slugSchema'

const slug = slugSchema.parse('abc')
```

### mini

Switches code generation to [Zod Mini](https://zod.dev/packages/mini). Schemas use the functional API (`z.optional(z.string())`) instead of the chainable one (`z.string().optional()`). Bundlers can then tree-shake unused validators. Setting `mini: true` also defaults `importPath` to `'zod/mini'`.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |
| Default: | `false`   |

> [!TIP]
> Use Zod Mini in code that ships to the browser. The functional API drops several kilobytes from the bundle compared to the standard Zod build.

> [!WARNING]
> Zod Mini is currently in beta. Its API may change in a future release.

::: code-group

```typescript [mini: true]
import * as z from 'zod/mini'

z.optional(z.string())
z.nullable(z.number())
z.array(z.string()).check(z.minLength(1), z.maxLength(10))
```

```typescript [mini: false (default)]
import * as z from 'zod'

z.string().optional()
z.number().nullable()
z.array(z.string()).min(1).max(10)
```

:::

You consume the schema the same way in either mode. Zod Mini only changes how the generated code builds the schema:

```typescript
import { petSchema } from './src/gen/zod/petSchema'

const pet = petSchema.parse(data)
```

### wrapOutput

Wraps the generated Zod schema string with extra calls before it is written to disk. The callback receives the raw schema string and its `SchemaNode`. Return a new string to replace the output, or `undefined` to leave it untouched.

|          |                                                                        |
| -------: | :--------------------------------------------------------------------- |
|    Type: | `(arg: { output: string; schema: SchemaNode }) => string \| undefined` |

> [!TIP]
> Use this to round-trip OpenAPI metadata back into Zod, such as examples, descriptions, or `.openapi()` annotations for libraries that re-emit OpenAPI from Zod schemas.

```typescript [Append .openapi() with metadata]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  wrapOutput: ({ output, schema }) => {
    if (!schema.examples?.length) {
      return undefined
    }

    return `${output}.openapi(${JSON.stringify({ examples: schema.examples })})`
  },
})
```

### include

Generates only the operations and schemas that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|          |                  |
| -------: | :--------------- |
|    Type: | `Array<Include>` |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

Pass `include: [{ type: 'tag', pattern: 'pet' }]` to keep only the `pet` tag. Stack entries to narrow further, such as `{ type: 'method', pattern: 'GET' }` with `{ type: 'path', pattern: /^\/pet/ }` for GET operations under `/pet`.

### exclude

Skips any operation or schema that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

|          |                  |
| -------: | :--------------- |
|    Type: | `Array<Exclude>` |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

Pass `exclude: [{ type: 'tag', pattern: 'store' }]` to drop the `store` tag, or stack `{ type: 'operationId', pattern: 'deletePet' }` with `{ type: 'method', pattern: 'DELETE' }` to skip one operation and every DELETE.

### override

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. That object accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

|          |                   |
| -------: | :---------------- |
|    Type: | `Array<Override>` |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

For example, `override: [{ type: 'tag', pattern: 'user', options: { coercion: true } }]` coerces input only for the `user` tag while the rest of the spec validates strictly.

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|          |                                                |
| -------: | :--------------------------------------------- |
|    Type: | `Partial<ResolverZod> & ThisType<ResolverZod>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.

For example, `resolver: { resolveSchemaName(name) { return \`${this.default(name, 'function')}Validator\` } }` renames every generated schema from `petSchema` to `petValidator`.

Each plugin ships with a default resolver:

| Plugin                 | Default resolver  |
| ---------------------- | ----------------- |
| `@kubb/plugin-ts`      | `resolverTs`      |
| `@kubb/plugin-zod`     | `resolverZod`     |
| `@kubb/plugin-faker`   | `resolverFaker`   |
| `@kubb/plugin-cypress` | `resolverCypress` |
| `@kubb/plugin-msw`     | `resolverMsw`     |
| `@kubb/plugin-mcp`     | `resolverMcp`     |
| `@kubb/plugin-axios`   | `resolverClient`  |
| `@kubb/plugin-fetch`   | `resolverClient`  |

### printer

Replaces the Zod handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Zod expression as a string. When `mini: true`, overrides target the Zod Mini printer. Otherwise they target the standard Zod printer.

|          |                                                     |
| -------: | :-------------------------------------------------- |
|    Type: | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` |

```typescript [Map integers and dates to other Zod expressions]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      integer() {
        return 'z.number()'
      },
      date() {
        return 'z.string().date()'
      },
    },
  },
})
```

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  macros: [
    {
      name: 'strip-descriptions',
      schema(node) {
        return { ...node, description: undefined }
      },
    },
    {
      name: 'prefix-operation-id',
      operation(node) {
        return { ...node, operationId: `api_${node.operationId}` }
      },
    },
  ],
})
```
