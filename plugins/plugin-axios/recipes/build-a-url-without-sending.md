---
layout: doc
title: Build a URL without sending
description: Build an operation's final URL without sending a request using the client @kubb/plugin-axios bundles.
outline: deep
---

# Build a URL without sending

The bundled `client`, written under [`output`](/plugins/plugin-axios/reference/options#output), exposes `getUrl` to build an operation's final URL without sending the request, useful for cache keys, prefetch, and links.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginAxios(),
  ],
})
```

```typescript
import { client } from './src/gen/.kubb/client'

const url = client.getUrl({ url: '/pet/{petId}', path: { petId: 1 }, query: { status: ['available'] } })
// '/pet/1?status=available'
```
