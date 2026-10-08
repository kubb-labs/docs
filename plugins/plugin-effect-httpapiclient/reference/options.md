---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-effect-httpapiclient.
outline: deep
---

# Options

`pluginEffectHttpApiClient` accepts the following options.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'effectHttpApiClient', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | None | Split generated files into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | None | Embed a fixed base URL in the generated client |
| [`mode`](#mode) | `'tag' \| 'flat'` | `'tag'` | Group client methods by tag or expose them at the root |
| [`include`](#include) | `Array<Include>` | None | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | `[]` | Skip operations that match |
| [`override`](#override) | `Array<Override>` | `[]` | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverEffectHttpApiClient>` | None | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | None | Rewrite AST nodes before printing |

### output

Controls where the generated `.ts` files are written and how Kubb exports them.

#### output.path

The plugin resolves this folder against the global `output.path` from `defineConfig`.

|           |                       |
| --------: | :-------------------- |
|     Type: | `string`              |
| Required: | `false`               |
|  Default: | `'effectHttpApiClient'` |

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

File grouping controls the output directory layout. It is separate from [`mode`](#mode), which controls the property layout on the generated `ApiClient`.

#### group.type

<!--@include: ../../../snippets/how-to/group-type.md-->

#### group.name

The function turns a tag or path key into the subdirectory under `output.path`.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                  |
|  Default: | `({ group }) => camelCase(group)`        |

### baseURL

Embeds a fixed string in the generated `HttpApiClient.make(Api, { baseUrl })` call. The plugin does not generate a factory for selecting another URL at runtime.

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `false`   |
|  Default: | None      |

### mode

Controls the shape returned by the generated client Effect.

- `'tag'` groups operations by their first OpenAPI tag. An operation without tags belongs to the `default` group.
- `'flat'` adds every operation directly to the client root.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'flat'` |
| Required: | `false`           |
|  Default: | `'tag'`           |

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes generated symbols and file paths. Methods omitted from the patch keep the default behavior.

| Method | Purpose |
| ------ | ------- |
| `name(name)` | Resolve the shared base name |
| `file(name)` | Resolve a generated file name |
| `endpoint.name(operation)` | Resolve an exported endpoint constant |
| `endpoint.identifier(operation)` | Resolve the operation property on the client |
| `group.name(tag)` | Resolve an exported `HttpApiGroup` constant |
| `group.identifier(tag)` | Resolve the group property on a tagged client |
| `api.name()` | Resolve the root `HttpApi` constant |
| `client.name()` | Resolve the generated client type and Effect value |

```typescript [kubb.config.ts]
import { pluginEffectHttpApiClient } from '@kubb/plugin-effect-httpapiclient'

pluginEffectHttpApiClient({
  resolver: {
    client: {
      name() {
        return 'PetStoreClient'
      },
    },
  },
})
```

See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the resolver context.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
