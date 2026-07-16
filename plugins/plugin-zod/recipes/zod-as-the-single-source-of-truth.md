---
layout: doc
title: Zod as the single source of truth
description: Export a z.infer alias next to every schema so Zod carries the types and you drop plugin-ts.
outline: deep
---

# Zod as the single source of truth

Turn on [`inferred`](/plugins/plugin-zod/reference/options#inferred) to export a `z.infer` alias next to every schema. The schemas then carry the types too, so you drop `@kubb/plugin-ts` from the config.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      inferred: true,
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/categorySchema.ts]
import * as z from 'zod'

export const categorySchema = z.object({
  id: z.bigint().optional().meta({ examples: [1] }),
  name: z.string().optional().meta({ examples: ['Dogs'] }),
  get parent() { return categorySchema.optional() },
})

export type CategorySchemaType = z.infer<typeof categorySchema>
```

```typescript [usage.ts]
import { categorySchema, type CategorySchemaType } from './src/gen/zod/categorySchema'

// no import from @kubb/plugin-ts needed, the type comes from the schema
const category: CategorySchemaType = categorySchema.parse({ name: 'Dogs' })
```
