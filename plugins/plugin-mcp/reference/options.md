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
| [`client`](#client) | `'fetch' \| 'axios'` | — | Which registered client plugin the handlers call |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverMcp>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated MCP handler files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig` and defaulting to `mcp`. To write everything into a single file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `mcp.ts`.

#### output.mode

How the plugin consolidates its generated code. `'directory'` (the default) writes one file per operation under `output.path`, and `'file'` writes everything into a single file whose `output.path` must include the extension.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` barrel re-exports the plugin's output. `{ type: 'named' }` (the default) re-exports each symbol by name for better tree-shaking, `{ type: 'all' }` uses `export *`, `{ nested: true }` adds a barrel in every subdirectory, and `false` skips the barrel and also excludes the plugin's files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, for license headers, lint disables, or a `@ts-nocheck` directive. Pass a fixed string, or a function that builds one from a `BannerMeta` object carrying the document info (`title`, `description`, `version`, `baseURL`) plus the per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`, so a directive such as `'use server'` can skip barrel files.

#### output.footer

Text added to the bottom of every generated file, mirroring `banner` with a string or a function of the same `BannerMeta`. Pair it with `banner` to scope a lint disable to the generated file.

### client

Selects which registered client plugin the handlers call, `'fetch'` for `@kubb/plugin-fetch` or `'axios'` for `@kubb/plugin-axios`. Each handler calls that client's generated `<op>` for the operation, passing one grouped `{ path, query, headers, body }` object. A lone registered client plugin is auto-detected, so set this only to disambiguate when both are registered, and transport options such as `baseURL` live on the client plugin itself.

> [!NOTE]
> The handlers call a client plugin's functions, so register `@kubb/plugin-fetch` or `@kubb/plugin-axios` alongside this one.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's first tag or first path segment, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. Grouping applies only to `output.mode: 'directory'`, so pairing it with `output.mode: 'file'` is invalid.

#### group.type

Property used to assign each operation to a group, required whenever `group` is set. `'tag'` uses the operation's first tag and `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`. An operation with no tag goes in the `default` group.

#### group.name

Function that turns a group key into the subdirectory name under `output.path`. It defaults to the camelCased tag for `tag` groups and the first URL segment as-is for `path` groups. The `server.ts` and `.mcp.json` files keep their fixed names at the root of `output.path`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and handlers, to add a prefix or suffix or swap the casing without forking the plugin. Override only the methods you want, since anything you omit keeps its default behavior, and inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in name.

For example, `resolver: { name(name) { return \`Api${this.default.name(name)}\` } }` prefixes every generated handler name with `Api`.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
