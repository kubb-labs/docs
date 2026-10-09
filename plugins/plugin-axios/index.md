---
layout: doc
title: Kubb Axios Plugin
description: Generates a type-safe axios client from your OpenAPI spec, one
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
  - id: transport
    title: Use custom transport
kind: plugin
id: plugin-axios
name: Axios
category: client
type: official
npmPackage: "@kubb/plugin-axios"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-axios
featured: true
icon:
  light: https://kubb.dev/feature/axios.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - api-client
  - axios
  - http-client
  - codegen
  - openapi
  - validator
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-axios
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/axios
---

# @kubb/plugin-axios

`@kubb/plugin-axios` generates a typed async function for each OpenAPI operation using [Axios](https://axios-http.com/). Calls accept grouped request parameters and return a status-keyed result.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-axios
```

```shell [pnpm]
pnpm add -D @kubb/plugin-axios
```

```shell [npm]
npm install --save-dev @kubb/plugin-axios
```

```shell [yarn]
yarn add -D @kubb/plugin-axios
```

::

## Dependencies

Add [`pluginTs`](/plugins/plugin-ts/) or [`pluginZod`](/plugins/plugin-zod/) with `inferred: true` for operation types. `pluginTs` takes precedence when both are configured. Validation also requires `pluginZod`. Install Axios v1 or higher in the consuming app.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
  ],
})
```

## Documentation

::card-group

:::card{title="Options" to="/plugins/plugin-axios/reference/options"}
:::

:::card{title="Authenticate" to="/plugins/plugin-axios/guide/authentication"}
:::

:::card{title="Set base URL" to="/plugins/plugin-axios/guide/base-url"}
:::

:::card{title="Call operations" to="/plugins/plugin-axios/guide/calling-operations"}
:::

:::card{title="Handle errors" to="/plugins/plugin-axios/guide/error-handling"}
:::

:::card{title="Add interceptors" to="/plugins/plugin-axios/guide/interceptors"}
:::

:::card{title="Serialize parameters" to="/plugins/plugin-axios/guide/serialization"}
:::

:::card{title="Use custom transport" to="/plugins/plugin-axios/guide/transport"}
:::

::

## See also

- [axios](https://axios-http.com/)
- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md)
