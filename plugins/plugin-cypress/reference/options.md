---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

Options for `pluginCypress`, with type and default in the table.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'cypress' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverCypress>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`.

#### output.mode

How the plugin consolidates its generated code into files.

- `'file'` (default) writes everything into a single file. The `output.path` must include the file extension (for example `'cypress.ts'`).
- `'directory'` writes one file per operation or schema under `output.path`.

> [!IMPORTANT]
> `group` requires `mode: 'directory'`. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error, since a single file has nothing to group.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function that turns a group key into a folder name, used as the subdirectory under `output.path`. By default the key is the camelCased tag, or the first path segment for `'path'` groups.

### baseURL

Base URL prepended to every request in the generated helpers. When omitted, no host is prepended and each helper uses the operation's relative path from the spec. Set it to point the helpers at a different environment, such as staging or production.

```typescript [baseURL: 'https://staging.petstore.dev']
export function showPetById(
  { path }: ShowPetByIdOptions,
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

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverCypress`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverCypressPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  // no extra namespaces
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
