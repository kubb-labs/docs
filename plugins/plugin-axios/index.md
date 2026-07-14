---
layout: doc
title: Kubb Axios Plugin
description: Generates a type-safe axios client from your OpenAPI spec, one async
  function per operation, so each call stays in sync with the API.
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

`@kubb/plugin-axios` turns each OpenAPI operation into a typed async function that calls your API with [axios](https://axios-http.com/). The path, query parameters, request body, response, and error shape all come from the spec, so a call stays in sync with the API it targets.

From your spec, the generated client gives you:

- [Typed functions](/plugins/plugin-axios/guide/calling-operations) per operation with grouped `path`, `query`, `headers`, and `body`.
- A [status-keyed result](/plugins/plugin-axios/guide/error-handling) on every call, or a thrown `ResponseError`.
- [Auth](/plugins/plugin-axios/guide/authentication) resolved from your OpenAPI security schemes.
- [Serialization](/plugins/plugin-axios/guide/serialization) of parameters and bodies across content types, including `multipart/form-data` uploads and binary downloads.
- Runtime [validation](#validator) against [`@kubb/plugin-zod`](/plugins/plugin-zod/) schemas.
- Typed [server-sent events](/plugins/plugin-fetch/guide/server-sent-events) you read with `for await`.
- [Interceptors](/plugins/plugin-axios/guide/interceptors) and a [custom transport](/plugins/plugin-axios/guide/transport) for the send.
- Standalone functions or a class-based [SDK](#sdk).

It builds on `@kubb/plugin-ts` for the types, so add that to your config, and axios is a runtime dependency to install next to your app.

Each function takes one grouped options object (`{ path, query, headers, body }`) and returns a `RequestResult` of `{ status, data, error, contentType, request, response }`, bundled into `.kubb/client.ts`. See [error handling](/plugins/plugin-axios/guide/error-handling) for `throwOnError` and the status-keyed result union.

The bundled `client` also exposes `getUrl`, which builds an operation's final URL without sending the request, useful for cache keys, prefetch, and links:

```ts
import { client } from './.kubb/client'

const url = client.getUrl({ url: '/pet/{petId}', path: { petId: 1 }, query: { status: ['available'] } })
// '/pet/1?status=available'
```

For a native axios field the runtime does not set (`timeout`, `proxy`, `maxRedirects`, `decompress`, `onUploadProgress`), pass `options`, on the client or per call, where a per-call value wins:

```ts
import { client } from './.kubb/client'
import { uploadFile } from './uploadFile'

client.setConfig({ options: { timeout: 10_000 } })

await uploadFile({ path: { petId: 1 }, body, options: { timeout: 2_000, onUploadProgress: (e) => console.log(e.loaded) } })
```

For cross-cutting concerns like retries and interceptors, reach for a [custom transport](/plugins/plugin-axios/guide/transport) instead.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-axios@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-axios@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-axios@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-axios@beta
```

:::

## Dependencies

This plugin needs `@kubb/plugin-ts` in your config. Kubb runs it before `plugin-axios` so the functions can import the generated types. When `validator` is set to `'zod'`, also add `@kubb/plugin-zod`.

- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [`@kubb/plugin-zod`](/plugins/plugin-zod/)

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios({
      output: { path: 'clients', barrel: { type: 'named' } },
      baseURL: 'https://petstore.swagger.io/v2',
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Service`,
      },
    }),
  ],
})
```

:::

## See also

- [axios](https://axios-http.com/)
- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md)
