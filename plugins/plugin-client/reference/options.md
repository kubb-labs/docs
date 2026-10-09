---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-client.
outline: deep
---

# Options

Pass these options to `pluginClient()` to control what it generates and where the files go.

::field-group

:::field{name="importPath" type="string" required}
Import specifier of your client module. [See details](#importpath).

Required; no default.
:::

:::field{name="output" type="Output"}
Where the generated files are written and exported. [See details](#output).

Default: `{ path: 'clients', barrel: { type: 'named' } }`.
:::

:::field{name="group" type="Group"}
Split output into per-tag or per-path folders. [See details](#group).

No default.
:::

:::field{name="throwOnErrorDefault" type="boolean"}
Default `throwOnError` value passed to your client. [See details](#throwonerrordefault).

Default: `true`.
:::

:::field{name="validator" type="false | 'zod' | { request?: 'zod'; response?: 'zod' }"}
Pass Zod schemas to your client. [See details](#validator).

Default: `false`.
:::

:::field{name="include" type="Array<Include>"}
Keep only operations that match. [See details](#include).

No default.
:::

:::field{name="exclude" type="Array<Exclude>"}
Skip operations that match. [See details](#exclude).

Default: `[]`.
:::

:::field{name="override" type="Array<Override>"}
Apply different options per pattern. [See details](#override).

Default: `[]`.
:::

:::field{name="resolver" type="ResolverPatch<ResolverClient>"}
Customize generated names and file paths. [See details](#resolver).

No default.
:::

:::field{name="macros" type="Array<Macro>"}
Rewrite AST nodes before printing. [See details](#macros).

No default.
:::

::

> [!NOTE]
> `sdk`, `returnType`, and `baseURL` from [`@kubb/plugin-fetch`](/plugins/plugin-fetch/reference/options) are not options here. This plugin generates standalone functions that return your client's promise, and your client owns the base URL.

### importPath

Import specifier of your client module. The plugin writes it into every generated import exactly as given, so it must resolve from the generated file. Use a relative path, a package name, or an alias.

```typescript
pluginClient({ importPath: '../../../client' }) // relative to src/gen/clients/<tag>/
pluginClient({ importPath: '@my-org/api-client' }) // a package
```

With `group: { type: 'tag' }` and `output.path: 'clients'`, a generated file sits in `src/gen/clients/<tag>/`, so `../../../client` points at `src/client.ts`. Without `group` it is `../../client`.

The module must export `client`, plus the `Options` and `RequestResult` types. See [write your client](/plugins/plugin-client/guide/write-your-client).

### output

Where the plugin writes its generated `.ts` files and how it exports them.

#### output.path

Folder for the plugin's files, resolved against the global `output.path` on `defineConfig` and defaulting to `'clients'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

#### output.mode

How the plugin consolidates its code into files, either `'file'` or `'directory'`.

- `'file'` writes everything into a single file, so `output.path` must include the extension (see above).
- `'directory'` writes one file per operation under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into a folder name. It defaults to the camelCased tag for a `'tag'` group or the first path segment for a `'path'` group, and a `group.name` you pass always wins.

### throwOnErrorDefault

Default for the `throwOnError` field that every generated function passes to your client. It defaults to `true`. A call that sets `throwOnError` itself wins. Your client decides what the flag does: the [example client](/plugins/plugin-client/guide/write-your-client) throws on a non-2xx status when it is `true` and returns the error as a value when it is `false`.

The setting applies to the whole plugin, so you cannot set it in `override`.

### validator

Passes Zod schemas from `@kubb/plugin-zod` to your client on `config.validator`, defaulting to `false`.

- `false` passes nothing.
- `'zod'` passes the response and error schemas.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction.

The plugin does not run the schemas. Your client reads `config.validator` and validates. Add `pluginZod()` to the plugins list when `validator` is set. Generation stops with an error if it is missing. See [validate requests and responses](/plugins/plugin-client/recipes/validate-requests-and-responses).

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols by accepting a partial patch. Override only the members you want, and anything you omit keeps `resolverClient`. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
