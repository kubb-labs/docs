---
layout: doc
title: Kubb Client Plugin
description: Generates typed operation functions from your OpenAPI spec that call a client module you own, so you decide the transport, auth, and error handling.
outline: deep
guides:
  - id: write-your-client
    title: Write your client
  - id: authentication
    title: Authenticate
  - id: calling-operations
    title: Call operations
recipes:
  - id: validate-requests-and-responses
    title: Validate requests and responses
kind: plugin
id: plugin-client
name: Client
category: client
type: official
npmPackage: "@kubb/plugin-client"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-client
featured: false
icon:
  light: https://kubb.dev/feature/javascript.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - api-client
  - http-client
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-client
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-client/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/client
---

# @kubb/plugin-client

`@kubb/plugin-client` turns each OpenAPI operation into a typed async function that calls a client module you write. Kubb generates the operations and their types. It does not choose a transport and does not copy a runtime into your project, so the generated code has no Fetch, Axios, or Kubb dependency.

Use it when [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) or [`@kubb/plugin-axios`](/plugins/plugin-axios/) do more than you want, for example when you sign requests, share one client across many generated packages, or keep an existing HTTP layer.

From your spec, the plugin gives you:

- [Typed functions](/plugins/plugin-client/guide/calling-operations) per operation with grouped `path`, `query`, `headers`, and `body`.
- A `security` list on each call that tells your client which [auth](/plugins/plugin-client/guide/authentication) the operation needs.
- A per-call `client` override, so one function can use a different client.
- Optional [validation](/plugins/plugin-client/recipes/validate-requests-and-responses) schemas from [`@kubb/plugin-zod`](/plugins/plugin-zod/), passed to your client.

Each function takes one grouped options object (`{ path, query, headers, body }`) and returns whatever your `client` returns, typed as your `RequestResult`. See [write your client](/plugins/plugin-client/guide/write-your-client) for the exports the module needs.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-client
```

```shell [pnpm]
pnpm add -D @kubb/plugin-client
```

```shell [npm]
npm install --save-dev @kubb/plugin-client
```

```shell [yarn]
yarn add -D @kubb/plugin-client
```

::

## Dependencies

The plugin needs `@kubb/plugin-ts` for the operation types. It needs `@kubb/plugin-zod` only when `validator` is set, and generation stops with an error if `@kubb/plugin-zod` is missing.

- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [`@kubb/plugin-zod`](/plugins/plugin-zod/)

> [!IMPORTANT]
> There is no HTTP client to install. The generated functions call the module you point `importPath` at.

## Example

::code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      output: { path: 'clients', mode: 'directory', barrel: { type: 'named' } },
      group: { type: 'tag' },
      // resolved from each generated file: src/gen/clients/<tag>/ to src/client.ts
      importPath: '../../../client',
    }),
  ],
})
```

::

## See also

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
- [Example project](https://github.com/kubb-labs/plugins/tree/main/examples/client)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-client/CHANGELOG.md)
