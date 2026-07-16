---
layout: doc
title: Tree-shakeable schemas with Zod Mini
description: Generate Zod Mini schemas on the functional API so bundlers tree-shake the validators you never call.
outline: deep
---

# Tree-shakeable schemas with Zod Mini

Set [`mini`](/plugins/plugin-zod/reference/options#mini) to `true` to generate Zod Mini schemas that use the functional API, so bundlers tree-shake the validators you never call. This also defaults the import to `'zod/mini'`.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      mini: true,
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/petSchema.ts]
import * as z from 'zod/mini'
import { categorySchema } from './categorySchema'
import { tagSchema } from './tagSchema'

export const petSchema = z.object({
  id: z.optional(z.bigint()),
  name: z.string(),
  get category() { return z.optional(categorySchema) },
  photoUrls: z.array(z.string()),
  tags: z.optional(z.array(tagSchema)),
  status: z.optional(z.enum(['available', 'pending', 'sold'])),
})
```

```typescript [usage.ts]
import { petSchema } from './src/gen/zod/petSchema'

// only the validators actually imported end up in the bundle
const pet = petSchema.parse({ name: 'Rex', photoUrls: [] })
```
