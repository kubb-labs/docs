---
layout: doc
title: Coerce query and form input
description: Scope z.coerce to a single tag with override so only matching operations coerce their schemas.
outline: deep
---

# Coerce query and form input

Coercion suits string sources like query params and form data. Scope it to one tag with [`override`](/plugins/plugin-zod/reference/options#override), which merges its `options` onto the plugin defaults for matching operations, so only the `user` tag wraps its schemas in `z.coerce`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginZod({
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { coercion: true },
        },
      ],
    }),
  ],
})
```
