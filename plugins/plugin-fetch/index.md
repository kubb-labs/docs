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
    title: Configure serialization
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

Generate typed API calls with the native [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API).

- One async function per OpenAPI operation.
- Grouped request parameters and status-keyed results.

## Installation

::code-group{sync="package-manager"}

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

- Add [`pluginTs`](/plugins/plugin-ts/) or [`pluginZod`](/plugins/plugin-zod/) with `inferred: true` for operation types. `pluginTs` takes precedence.
- Add `pluginZod` for validation.
- Uses native `fetch`.

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

::card-group

:::card{title="Options" to="/plugins/plugin-fetch/reference/options"}
:::

:::card{title="Authenticate" to="/plugins/plugin-fetch/guide/authentication"}
:::

:::card{title="Set base URL" to="/plugins/plugin-fetch/guide/base-url"}
:::

:::card{title="Call operations" to="/plugins/plugin-fetch/guide/calling-operations"}
:::

:::card{title="Handle errors" to="/plugins/plugin-fetch/guide/error-handling"}
:::

:::card{title="Add interceptors" to="/plugins/plugin-fetch/guide/interceptors"}
:::

:::card{title="Serialize parameters" to="/plugins/plugin-fetch/guide/serialization"}
:::

:::card{title="Server-sent events" to="/plugins/plugin-fetch/guide/server-sent-events"}
:::

:::card{title="Use custom transport" to="/plugins/plugin-fetch/guide/transport"}
:::

::

## See also

- [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-fetch/CHANGELOG.md)
