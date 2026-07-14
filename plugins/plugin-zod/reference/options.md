---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-zod.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'zod', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`importPath`](#importpath) | `string` | `mini ? 'zod/mini' : 'zod'` | Module the generated files import `z` from |
| [`inferred`](#inferred) | `boolean` | `false` | Emit a `z.infer` alias next to each schema |
| [`coercion`](#coercion) | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` | `false` | Coerce input before validation |
| [`guidType`](#guidtype) | `'uuid' \| 'guid'` | `'uuid'` | Validator for `format: uuid` properties |
| [`regexType`](#regextype) | `'literal' \| 'constructor'` | `'literal'` | How an OpenAPI `pattern` is written |
| [`mini`](#mini) | `boolean` | `false` | Generate Zod Mini schemas |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverZod>` | — | Customize generated names and file paths |
| [`printer`](#printer) | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` | — | Replace the handler for a schema type |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`. For a single file, set `output.mode: 'file'` and give `path` an extension, such as `'zod.ts'`.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'zod'`  |

#### output.mode

How the plugin consolidates generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file, so `output.path` must include the file extension (for example `'zod.ts'`).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'directory' \| 'file'` |
| Default: | `'directory'`           |

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

Text added to the top of every generated file, for license headers or a `@ts-nocheck` directive. Pass a string, or a function that builds one from a `BannerMeta` object (document and per-file context like `isBarrel`), so a directive such as `'use server'` can skip barrels.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

```typescript
/* eslint-disable */
// @ts-nocheck
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})
```

#### output.footer

Bottom-of-file counterpart to `banner`, for closing comments. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'` (the default).

> [!IMPORTANT]
> Combining `group` with `output.mode: 'file'` fails the build with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### group.type

Assigns each operation to a group, required whenever `group` is set. An operation with no tag goes in the `default` group.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key (first tag or path segment) into a folder or identifier name, used as the subdirectory under `output.path` and a suffix for aggregate files. For `type: 'path'`, the default keeps the URL segment as-is instead of camelCasing.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `(context: { group: string }) => string` |
| Default: | `({ group }) => camelCase(group)` |

### importPath

Module specifier for the `import { z } from '...'` statement in every generated file, so you can re-export Zod from your own module. Defaults to `'zod'`, or `'zod/mini'` when `mini` is on.

> [!NOTE]
> `'zod'` and `'zod/mini'` import the `z` namespace (`import * as z`), but a custom module imports the named `z` export (`import { z }`), so re-export `z` from there.

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema, so the schema is the single source of truth and you do not import types from `@kubb/plugin-ts`. The alias is the PascalCased schema name with a `SchemaType` suffix, so `petSchema` becomes `PetSchemaType`.

```typescript
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})

export type PetSchemaType = z.infer<typeof petSchema>
```

### coercion

Wraps schemas in `z.coerce` so input is coerced before validation, for form data, query params, and similar string sources.

- `true` coerces strings, numbers, and dates.
- `false` (default) coerces nothing and validates strictly.
- An object picks which primitives to coerce.

See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

```typescript
z.coerce.string()
z.coerce.number()
z.coerce.date()
```

> [!NOTE]
> `dates` coerces only `Date`-typed fields (from `dateType: 'date'`). Fields kept as ISO strings (`z.iso.date()`, `z.iso.datetime()`) are never coerced.

### guidType

Validator used for OpenAPI properties with `format: uuid`.

- `'uuid'` (default) generates `z.uuid()`, a standard RFC 4122 UUID.
- `'guid'` generates `z.guid()`, which is looser and accepts Microsoft-style GUIDs.

### regexType

Controls how an OpenAPI `pattern` is written inside `.regex(...)`.

- `'literal'` (default) emits a regex literal, such as `.regex(/^[a-z]+$/)`.
- `'constructor'` emits the `RegExp` constructor, such as `.regex(new RegExp('^[a-z]+$'))`.

Use `'constructor'` when a regex literal breaks your build or you need a string pattern.

### mini

Switches code generation to [Zod Mini](https://zod.dev/packages/mini), which uses the functional API (`z.optional(z.string())`) instead of the chainable one (`z.string().optional()`) so bundlers can tree-shake unused validators. `mini: true` also defaults `importPath` to `'zod/mini'`.

> [!WARNING]
> Zod Mini is currently in beta. Its API may change in a future release.

```typescript
import * as z from 'zod/mini'

z.optional(z.string())
z.nullable(z.number())
z.array(z.string()).check(z.minLength(1), z.maxLength(10))
```

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

For example, `override: [{ type: 'tag', pattern: 'user', options: { coercion: true } }]` coerces input only for the `user` tag.

### resolver

Changes how the plugin names generated files and symbols, such as a prefix, suffix, or casing change, without forking the plugin. Override only the methods you want, since omitted ones keep their default, and `this.default.name(name)` reuses the built-in name. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and patch layering.

For example, `resolver: { name(name) { return \`${this.default.name(name)}Validator\` } }` renames every generated schema from `petSchema` to `petValidator`.

### printer

Replaces the Zod handler for a schema type such as `'integer'` or `'string'`, each returning the Zod expression as a string and targeting the Zod Mini printer when `mini: true`. Inside a handler, `this.base(node)` returns the built-in output to wrap and `this.transform(node)` recurses into nested nodes. See the [printer guide](/docs/5.x/guide/going-further/printers).

```typescript
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

<!--@include: ../../../snippets/how-to/macros-option.md-->
