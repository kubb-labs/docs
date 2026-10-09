---
layout: doc
title: Mock API responses
description: Configure generated MSW handlers and register them in tests or a
  browser worker.
outline: deep
---

# Mock API responses

## Generate typed handlers

Add `pluginTs` and `pluginMsw` to your configuration. The default `parser: 'data'` creates handlers whose response data you supply.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({ output: { path: 'handlers', mode: 'directory' }, baseURL: 'http://localhost:3000', handlers: true }),
  ],
})
```

> [!TIP]
> For Node tests, set `baseURL` to the URL your client calls so MSW can match absolute requests. Browser handlers can use relative paths for the current origin.

## Supply test data

Call a generated handler with a response body or a callback that returns a `Response`.

```typescript [test-server.ts]
import { setupServer } from 'msw/node'
import { getPetByIdHandler } from './src/gen/handlers/getPetByIdHandler'

export const server = setupServer(
  getPetByIdHandler({ name: 'Rex', photoUrls: [] }),
)
```

## Generate mock data

Add `pluginFaker` and change the MSW [`parser`](/plugins/plugin-msw/reference/options#parser) to `'faker'`.

```typescript [kubb.config.ts]
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

const plugins = [
  pluginTs(),
  pluginFaker(),
  pluginMsw({
    output: { path: 'handlers', mode: 'directory' },
    baseURL: 'http://localhost:3000',
    parser: 'faker',
    handlers: true,
  }),
]
```

Use this array as `defineConfig.plugins`. Calling `getPetByIdHandler()` without data now uses generated Faker values.

## Register the handler collection

With `handlers: true`, Kubb exports an operation-ordered collection from `handlers.ts`. Register it in Node or a browser.

::code-group

```typescript [test-server.ts]
import { setupServer } from 'msw/node'
import { handlers } from './src/gen/handlers/handlers'

export const server = setupServer(...handlers)
```

```typescript [browser-worker.ts]
import { setupWorker } from 'msw/browser'
import { handlers } from './src/gen/handlers/handlers'

export const worker = setupWorker(...handlers)
```

::

Start the server or worker through your test or application setup.
