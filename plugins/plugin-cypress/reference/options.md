---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

Options for `pluginCypress`, with each option's type and default listed below.

::field-group

:::field{name="output" type="Output"}
Where the generated files are written and exported. [See details](#output).

Default: `{ path: 'cypress', barrel: { type: 'named' } }`.
:::

:::field{name="group" type="Group"}
Split output into per-tag or per-path folders. [See details](#group).

No default.
:::

:::field{name="baseURL" type="string"}
Base URL prepended to every request. [See details](#baseurl).

No default.
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

:::field{name="resolver" type="ResolverPatch<ResolverCypress>"}
Customize generated names and file paths. [See details](#resolver).

No default.
:::

:::field{name="macros" type="Array<Macro>"}
Rewrite AST nodes before printing. [See details](#macros).

No default.
:::

::

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`.

#### output.mode

How the plugin consolidates its generated code into files.

- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'cypress.ts'`).
- `'directory'` writes one file per operation or schema under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` requires directory output. Kubb infers the mode from `output.path`. Set `mode: 'directory'` to override that inference. Combining `group` with `mode: 'file'` stops generation with `KUBB_INVALID_PLUGIN_OPTIONS`.

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

```typescript [kubb.config.ts]
import { pluginCypress } from '@kubb/plugin-cypress'

pluginCypress({ baseURL: 'https://staging.example.com' })
```

Keep `pluginTs()` in the configuration. The host is emitted into each helper's URL. No runtime host setup is needed.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

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
