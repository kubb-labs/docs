---
layout: doc
title: Register handlers with a server
description: Emit a handlers.ts collection with @kubb/plugin-msw and drop it into an MSW server or worker.
outline: deep
---

# Register handlers with a server

Set [`handlers`](/plugins/plugin-msw/reference/options#handlers) to `true` so the plugin writes a `handlers.ts` file that re-exports every generated handler in operation order. Pass the collection to `setupServer` in Node tests or `setupWorker` in the browser.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginMsw({
      handlers: true,
    }),
  ],
})
```

Spread the exported `handlers` array into the server you start before your tests run.

```typescript
import { setupServer } from 'msw/node'
import { handlers } from './src/gen/handlers/handlers'

export const server = setupServer(...handlers)
```
