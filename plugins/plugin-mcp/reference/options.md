---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-mcp.
outline: deep
---

# Options

Options for `@kubb/plugin-mcp`, which generates an MCP server where each OpenAPI operation becomes a typed tool handler.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'mcp', barrel: { type: 'named' } }` | Where the generated handlers are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'fetch' \| 'axios'` | — | Which registered client plugin the handlers call |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverMcp>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated MCP handler files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig` and defaulting to `mcp`. To write everything into a single file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `mcp.ts`.

#### output.mode

How the plugin consolidates its generated code. `'file'` (the default) writes everything into a single file whose `output.path` must include the extension, and `'directory'` writes one file per operation under `output.path`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function that turns a group key into the subdirectory name under `output.path`. It defaults to the camelCased tag for `tag` groups and the first URL segment as-is for `path` groups. The `server.ts` and `.mcp.json` files keep their fixed names at the root of `output.path`.

### client

Selects which registered client plugin the handlers call, `'fetch'` for `@kubb/plugin-fetch` or `'axios'` for `@kubb/plugin-axios`. Each handler calls that client's generated `<op>` for the operation, passing one grouped `{ path, query, headers, body }` object. A lone registered client plugin is auto-detected, so set this only to disambiguate when both are registered, and transport options such as `baseURL` live on the client plugin itself.

> [!NOTE]
> The handlers call a client plugin's functions, so register `@kubb/plugin-fetch` or `@kubb/plugin-axios` alongside this one.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

A partial patch changes how the plugin names generated files and symbols. Override only the members you want, and anything you omit keeps `resolverMcp`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverMcpPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  handler?: {
    name?(node: OperationNode): string     // → 'showPetByIdHandler'
  }
}
```

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
