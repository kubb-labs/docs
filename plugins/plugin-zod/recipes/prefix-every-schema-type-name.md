---
layout: doc
title: Prefix every schema type name
description: Override resolver.schema.typeName so the z.infer alias plugin-zod exports for every schema carries a shared prefix.
outline: deep
---

# Prefix every schema type name

Set [`resolver.schema.typeName`](/plugins/plugin-zod/reference/options#resolver) to patch the name plugin-zod gives the `z.infer` alias it exports next to each schema, alongside [`inferred`](/plugins/plugin-zod/reference/options#inferred). This prefixes every inferred type with `Api`, so it never collides with a hand-written type of the same name.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      inferred: true,
      resolver: {
        schema: {
          typeName(name) {
            return `Api${name}`
          },
        },
      },
    }),
  ],
})
```

## Output example

```typescript twoslash [src/gen/zod/petSchema.ts]
export const petSchema = z.object({ /* ... */ })

export type ApiPet = z.infer<typeof petSchema>
```

```typescript twoslash [usage.ts]
import { petSchema, type ApiPet } from './src/gen/zod/petSchema'

const pet: ApiPet = petSchema.parse({ name: 'Rex', photoUrls: [] })
```

Only `resolver.schema.typeName` renames the inferred type. The schema constant itself (`petSchema`) keeps its default name unless `resolver.schema.type` is patched too.

> [!TIP]
> `name` arrives already cased, so the override only needs the prefix. There is no `this.default.schema.typeName(name)` to reuse here (`this.default` only carries the top-level `name`), and `this.name(name)` inside a `schema` method calls the schema constant's own casing (for example `orderSchema`), not the type name's, so it is the wrong thing to wrap even if it did not throw.
