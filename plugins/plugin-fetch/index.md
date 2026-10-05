---
layout: doc
title: Kubb Fetch Plugin
description: Generates a type-safe Fetch API client from your OpenAPI spec, one
  async function per operation, so each call stays in sync with the API.
outline: deep
guides:
  - id: authentication
    title: Authenticate
  - id: base-url
    title: Set base URL
  - id: calling-operations
    title: Call operations
  - id: error-handling
    title: Handle errors
  - id: interceptors
    title: Add interceptors
  - id: serialization
    title: Serialize parameters
  - id: server-sent-events
    title: Server-sent events
  - id: transport
    title: Use custom transport
kind: plugin
id: plugin-fetch
name: Fetch
category: client
type: official
npmPackage: "@kubb/plugin-fetch"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-fetch
featured: true
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
  - fetch
  - http-client
  - codegen
  - openapi
  - validator
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-fetch
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-fetch/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/fetch
---

# @kubb/plugin-fetch

`@kubb/plugin-fetch` generates a typed async function for each OpenAPI operation using the native [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API). Calls accept grouped request parameters and return a status-keyed result.

## Installation

::code-group

```shell [bun]
bun add -d @kubb/plugin-fetch
```

```shell [pnpm]
pnpm add -D @kubb/plugin-fetch
```

```shell [npm]
npm install --save-dev @kubb/plugin-fetch
```

```shell [yarn]
yarn add -D @kubb/plugin-fetch
```

::

## Dependencies

Add [`pluginTs`](/plugins/plugin-ts/) or [`pluginZod`](/plugins/plugin-zod/) with `inferred: true` for operation types. `pluginTs` takes precedence when both are configured. Validation also requires `pluginZod`. The generated client uses native `fetch`.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch({ baseURL: 'https://petstore.swagger.io/v2' }),
  ],
})
```

## Documentation

- [Options](./reference/options)
- [Authenticate](./guide/authentication)
- [Set base URL](./guide/base-url)
- [Call operations](./guide/calling-operations)
- [Handle errors](./guide/error-handling)
- [Add interceptors](./guide/interceptors)
- [Serialize parameters](./guide/serialization)
- [Server-sent events](./guide/server-sent-events)
- [Use custom transport](./guide/transport)

## See also

- [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-fetch/CHANGELOG.md)
