---
layout: doc
title: Downgrade int64 to a plain number
description: Replace the bigint printer node so int64 fields validate as z.number() instead of the default z.bigint().
outline: deep
---

# Downgrade int64 to a plain number

Kubb maps an OpenAPI `integer` with `format: int64` to the `bigint` schema kind, and plugin-zod's default [printer](/plugins/plugin-zod/reference/options#printer) turns that into `z.bigint()`. Override the `bigint` node to emit `z.number()` instead, useful when the rest of a codebase treats large IDs as plain numbers.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      printer: {
        nodes: {
          bigint() {
            return 'z.number()'
          },
        },
      },
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/petSchema.ts]
export const petSchema = z.object({
  id: z.number().optional().meta({ examples: [10] }),
  // ...
})
```

Without the override, that same field prints `id: z.bigint().optional()`. The `integer` node (for 32-bit `format: int32` fields) is a separate handler from `bigint`, so overriding one does not affect the other.

```typescript [usage.ts]
import { petSchema } from './src/gen/zod/petSchema'

// id now parses as a JS number, not a bigint
const pet = petSchema.parse({ id: 10, name: 'Rex', photoUrls: [] })
```
