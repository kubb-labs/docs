---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-client.
outline: deep
---

# Options

Pass these options to `pluginClient()`. Shared options link to [Shared plugin options](/docs/5.x/reference/plugin-options), which documents their behavior once.

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`importPath`](#importpath) | Import specifier of your client module. | Required |
| [`output`](/docs/5.x/reference/plugin-options#output) | Where the generated files are written and exported. | `{ path: 'clients', barrel: { type: 'named' } }` |
| ↳ [`output.path`](/docs/5.x/reference/plugin-options#output-path) | Choose the output folder or file. | `'clients'` |
| ↳ [`output.mode`](/docs/5.x/reference/plugin-options#output-mode) | Write a single file or a directory of files. | Inferred from `output.path` |
| ↳ [`output.barrel`](/docs/5.x/reference/plugin-options#output-barrel) | Configure barrel exports. | `{ type: 'named' }` |
| ↳ [`output.banner`](/docs/5.x/reference/plugin-options#output-banner) | Add content before generated code. | None |
| ↳ [`output.footer`](/docs/5.x/reference/plugin-options#output-footer) | Add content after generated code. | None |
| [`group`](/docs/5.x/reference/plugin-options#group) | Split output into per-tag or per-path folders. | None |
| ↳ [`group.type`](/docs/5.x/reference/plugin-options#group-type) | Group operations by tag or URL path. | Required with `group` |
| ↳ [`group.name`](/docs/5.x/reference/plugin-options#group-name) | Customize output group names. | camelCased tag or raw path segment |
| [`throwOnErrorDefault`](#throwonerrordefault) | Default `throwOnError` value passed to your client. | `true` |
| [`validator`](#validator) | Pass Zod schemas to your client. | `false` |
| ↳ [`validator.request`](#validator) | Pass request body schemas. | None |
| ↳ [`validator.response`](#validator) | Pass response body schemas. | None |
| [`include`](/docs/5.x/reference/plugin-options#include) | Keep only operations that match. | None |
| [`exclude`](/docs/5.x/reference/plugin-options#exclude) | Skip operations that match. | `[]` |
| [`override`](/docs/5.x/reference/plugin-options#override) | Apply different options per pattern. | `[]` |
| [`resolver`](/docs/5.x/reference/plugin-options#resolver) | Customize generated names and file paths. | `resolverClient` |
| [`macros`](/docs/5.x/reference/plugin-options#macros) | Rewrite AST nodes before printing. | `[]`, run after the built-in client macros |

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

### throwOnErrorDefault

Default for the `throwOnError` field that every generated function passes to your client. A call that sets `throwOnError` itself wins. Your client decides what the flag does: the [example client](/plugins/plugin-client/guide/write-your-client) throws on a non-2xx status when it is `true` and returns the error as a value when it is `false`.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `true` |

The setting applies to the whole plugin, so you cannot set it in `override`.

### validator

Passes Zod schemas from `@kubb/plugin-zod` to your client on `config.validator`. The plugin does not run the schemas, your client reads `config.validator` and validates. See [validate requests and responses](/plugins/plugin-client/recipes/validate-requests-and-responses).

| | |
| --- | --- |
| Type | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required | `false` |
| Default | `false` |

::field-group

:::field{name="false"}
Default value. Passes nothing.
:::

:::field{name="'zod'"}
Passes the response and error schemas.
:::

:::field{name="{ request?: 'zod', response?: 'zod' }"}
Opts in per direction.
:::

::

> [!IMPORTANT]
> Add `pluginZod()` to the plugins list when `validator` is set. Generation stops with an error if it is missing.
