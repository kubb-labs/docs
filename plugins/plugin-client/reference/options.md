---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-client.
outline: deep
---

# Options

Pass these options to `pluginClient()` to control what it generates and where the files go.

## Options overview

Select an option to see its type, default, and examples. Nested settings link to their own section or the parent option.

| Option | Purpose |
| --- | --- |
| [`importPath`](#importpath) | Import specifier of your client module. |
| [`output`](#output) | Where the generated files are written and exported. |
| ↳ [`output.path`](#output-path) | Choose the output folder or file. |
| ↳ [`output.mode`](#output-mode) | Write a single file or a directory of files. |
| ↳ [`output.barrel`](#output-barrel) | Configure barrel exports. |
| ↳ [`output.barrel.type`](#output-barrel) | Use named exports or wildcard exports. |
| ↳ [`output.barrel.nested`](#output-barrel) | Choose whether barrels reference subdirectory barrels. |
| ↳ [`output.banner`](#output-banner) | Add content before generated code. |
| ↳ [`output.footer`](#output-footer) | Add content after generated code. |
| [`group`](#group) | Split output into per-tag or per-path folders. |
| ↳ [`group.type`](#group-type) | Group operations by tag or URL path. |
| ↳ [`group.name`](#group-name) | Customize output group names. |
| [`throwOnErrorDefault`](#throwonerrordefault) | Default `throwOnError` value passed to your client. |
| [`validator`](#validator) | Pass Zod schemas to your client. |
| ↳ [`validator.request`](#validator) | Validate request bodies with Zod. |
| ↳ [`validator.response`](#validator) | Validate response bodies with Zod. |
| [`include`](#include) | Keep only operations that match. |
| [`exclude`](#exclude) | Skip operations that match. |
| [`override`](#override) | Apply different options per pattern. |
| [`resolver`](#resolver) | Customize generated names and file paths. |
| [`macros`](#macros) | Rewrite AST nodes before printing. |

## Option details

### importPath

Import specifier of your client module. The plugin writes it into every generated import exactly as given, so it must resolve from the generated file. Use a relative path, a package name, or an alias.

| | |
| --- | --- |
| Type | `string` |
| Required | `true` |

```typescript
pluginClient({ importPath: '../../../client' }) // relative to src/gen/clients/<tag>/
pluginClient({ importPath: '@my-org/api-client' }) // a package
```

With `group: { type: 'tag' }` and `output.path: 'clients'`, a generated file sits in `src/gen/clients/<tag>/`, so `../../../client` points at `src/client.ts`. Without `group` it is `../../client`.

The module must export `client`, plus the `Options` and `RequestResult` types. See [write your client](/plugins/plugin-client/guide/write-your-client).

### output

Where the plugin writes its generated `.ts` files and how it exports them.

| | |
| --- | --- |
| Type | `Output` |
| Required | `false` |
| Default | `{ path: 'clients', barrel: { type: 'named' } }` |

#### output.path

Folder for the plugin's files, resolved against the global `output.path` on `defineConfig` and defaulting to `'clients'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

#### output.mode

How the plugin consolidates its code into files, either `'file'` or `'directory'`.

::field-group

:::field{name="'file'"}
Writes everything into a single file, so `output.path` must include the extension (see above).
:::

:::field{name="'directory'"}
Writes one file per operation under `output.path`.
:::

::

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

Split output into per-tag or per-path folders.

| | |
| --- | --- |
| Type | `Group` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name. It defaults to the camelCased tag for a `'tag'` group or the first path segment for a `'path'` group, and a `group.name` you pass always wins.

### throwOnErrorDefault

Default for the `throwOnError` field that every generated function passes to your client. It defaults to `true`. A call that sets `throwOnError` itself wins. Your client decides what the flag does: the [example client](/plugins/plugin-client/guide/write-your-client) throws on a non-2xx status when it is `true` and returns the error as a value when it is `false`.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `true` |

The setting applies to the whole plugin, so you cannot set it in `override`.

### validator

Passes Zod schemas from `@kubb/plugin-zod` to your client on `config.validator`, defaulting to `false`.

| | |
| --- | --- |
| Type | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required | `false` |
| Default | `false` |

::field-group

:::field{name="false"}
Passes nothing.
:::

:::field{name="'zod'"}
Passes the response and error schemas.
:::

:::field{name="{ request?: 'zod', response?: 'zod' }"}
Opts in per direction.
:::

::

The plugin does not run the schemas. Your client reads `config.validator` and validates. Add `pluginZod()` to the plugins list when `validator` is set. Generation stops with an error if it is missing. See [validate requests and responses](/plugins/plugin-client/recipes/validate-requests-and-responses).

### include

Keep only operations that match.

| | |
| --- | --- |
| Type | `Array<Include>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

Skip operations that match.

| | |
| --- | --- |
| Type | `Array<Exclude>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

Apply different options per pattern.

| | |
| --- | --- |
| Type | `Array<Override>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols by accepting a partial patch. Override only the members you want, and anything you omit keeps `resolverClient`. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverClient>` |
| Required | `false` |

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->

| | |
| --- | --- |
| Type | `Array<Macro>` |
| Required | `false` |
