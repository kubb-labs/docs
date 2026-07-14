---
layout: doc
title: Kubb Fetch Plugin
description: Generates a type-safe Fetch API client from your OpenAPI spec, one async
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
  - id: server-sent-events
    title: Server-sent events
  - id: transport
    title: Use custom transport
recipes:
  - id: class-based-sdk
    title: Class-based SDK
  - id: validate-requests-and-responses
    title: Validate requests and responses
  - id: build-a-url-without-sending
    title: Build a URL without sending
  - id: point-at-an-env-driven-host
    title: Point at an env-driven host
  - id: stream-server-sent-events
    title: Stream server-sent events
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

`@kubb/plugin-fetch` turns each OpenAPI operation into a typed async function that calls your API with the global [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API). The path, query parameters, request body, response, and error shape all come from the spec, so a call stays in sync with the API it targets.

From your spec, the generated client gives you:

- [Typed functions](/plugins/plugin-fetch/guide/calling-operations) per operation with grouped `path`, `query`, `headers`, and `body`.
- A [status-keyed result](/plugins/plugin-fetch/guide/error-handling) on every call, or a thrown `ResponseError`.
- [Auth](/plugins/plugin-fetch/guide/authentication) resolved from your OpenAPI security schemes.
- [Serialization](/plugins/plugin-fetch/guide/serialization) of parameters and bodies across content types, including `multipart/form-data` uploads and binary downloads.
- Runtime [validation](#validator) against [`@kubb/plugin-zod`](/plugins/plugin-zod/) schemas.
- Typed [server-sent events](/plugins/plugin-fetch/guide/server-sent-events) you read with `for await`.
- [Interceptors](/plugins/plugin-fetch/guide/interceptors) and a [custom transport](/plugins/plugin-fetch/guide/transport) for the send.
- Standalone functions or a class-based [SDK](#sdk).

It builds on `@kubb/plugin-ts` for the types, so add that to your config. The client uses the built-in `fetch`, so there is no extra HTTP dependency to install.

Each function takes one grouped options object (`{ path, query, headers, body }`) and returns a `RequestResult` of `{ status, data, error, contentType, request, response }`, bundled into `.kubb/client.ts`. See [error handling](/plugins/plugin-fetch/guide/error-handling) for `throwOnError` and the status-keyed result union.

The bundled `client` also exposes `getUrl`, which builds an operation's final URL without sending the request, useful for cache keys, prefetch, and links:

```ts
import { client } from './.kubb/client'

const url = client.getUrl({ url: '/pet/{petId}', path: { petId: 1 }, query: { status: ['available'] } })
// '/pet/1?status=available'
```

The runtime sets `method`, `headers`, `body`, `signal`, and `credentials` itself. To reach the rest of `RequestInit` (`cache`, `mode`, `redirect`, `keepalive`, `duplex`, or Next.js's `next`), pass `options`, on the client or per call, where a per-call value wins:

```ts
import { client } from './.kubb/client'
import { getPetById } from './getPetById'

client.setConfig({ options: { cache: 'no-store' } })

await getPetById({ path: { petId: 1 }, options: { cache: 'force-cache', next: { revalidate: 60 } } })
```

For cross-cutting concerns like retries and interceptors, reach for a [custom transport](/plugins/plugin-fetch/guide/transport) instead.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-fetch@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-fetch@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-fetch@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-fetch@beta
```

:::

## Dependencies

This plugin needs `@kubb/plugin-ts` in your config. Kubb runs it before `plugin-fetch` so the functions can import the generated types. When `validator` is set to `'zod'`, also add `@kubb/plugin-zod`.

- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [`@kubb/plugin-zod`](/plugins/plugin-zod/)

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch({
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

- [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [`@kubb/plugin-ts`](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-fetch/CHANGELOG.md)
