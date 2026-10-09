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

Generate typed API calls for your own HTTP client.

- [Grouped parameters](/plugins/plugin-client/guide/calling-operations): `path`, `query`, `headers`, and `body`.
- Per-operation [authentication requirements](/plugins/plugin-client/guide/authentication) in a `security` list.
- Per-call `client` overrides and your client's `RequestResult` return type.
- Optional [Zod validation schemas](/plugins/plugin-client/recipes/validate-requests-and-responses) passed to your client.

Use it for signed requests, a shared client, or an existing HTTP layer. [Write your client](/plugins/plugin-client/guide/write-your-client) to define the required exports. The generated code has no Fetch, Axios, or Kubb runtime dependency.

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

- Add [`pluginTs`](/plugins/plugin-ts/) for operation types.
- Add [`pluginZod`](/plugins/plugin-zod/) when `validator` is set. Generation fails without it.

Set [`importPath`](/plugins/plugin-client/reference/options#importpath) to your client module. No HTTP client package is required.

## Example

::code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
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
