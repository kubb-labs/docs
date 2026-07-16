---
layout: doc
title: Coerce query and form input
description: Scope z.coerce to a single tag with override so only matching operations coerce their schemas.
outline: deep
---

# Coerce query and form input

Coercion suits string sources like query params and form data. Scope it to one tag with [`override`](/plugins/plugin-zod/reference/options#override), which merges its `options` onto the plugin defaults for matching operations, so only the `store` tag wraps its schemas in `z.coerce`.

```typescript [kubb.config.ts]
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
          pattern: 'store',
          options: { coercion: true },
        },
      ],
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/getOrderByIdSchema.ts]
import * as z from 'zod'
import { orderSchema } from './orderSchema'

export const getOrderByIdPathOrderIdSchema = z.coerce.bigint().describe('ID of order that needs to be fetched')

export const getOrderByIdStatus200SchemaJson = orderSchema

export const getOrderByIdStatus200SchemaXml = orderSchema

export const getOrderByIdStatus200Schema = z.union([getOrderByIdStatus200SchemaJson, getOrderByIdStatus200SchemaXml])
```

```typescript [usage.ts]
import { getOrderByIdPathOrderIdSchema } from './src/gen/zod/getOrderByIdSchema'

// coerces the raw route param string into a bigint before validating
const orderId = getOrderByIdPathOrderIdSchema.parse('1000')
```
