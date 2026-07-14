---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'cypress', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverCypress>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'cypress.ts'`).

> [!IMPORTANT]
> Pairing `mode: 'file'` with the `group` option stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error, since a single file has nothing to group.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

#### output.banner

Text added to the top of every generated file, such as license headers, lint disables, or a `@ts-nocheck` directive. Pass a string, or a function that receives a `BannerMeta` object (document info `title`, `description`, `version`, `baseURL` plus per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`) and returns the text, so a directive such as `'use server'` can skip barrel files.

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. Only applies to `output.mode: 'directory'` (the default).

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

#### group.name

Function that turns a group key into a folder name, used as the subdirectory under `output.path`. By default the key is the camelCased tag, or the first path segment for `'path'` groups.

### baseURL

Base URL prepended to every request in the generated helpers. When omitted, no host is prepended and each helper uses the operation's relative path from the spec. Set it to point the helpers at a different environment, such as staging or production.

```typescript [baseURL: 'https://staging.petstore.dev']
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `https://staging.petstore.dev/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols, for example to add a prefix or suffix or swap the casing. Override only the methods you want, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so `this.default.name(name)` reuses the built-in name.

> [!TIP]
> For changing the AST nodes themselves instead of names, use `macros`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context.

For example, `resolver: { name(name) { return \`api${this.default.name(name)}\` } }` prefixes every generated helper name with `api`.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
