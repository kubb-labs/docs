---
layout: doc
title: Fast-path validation with compile
description: Compile generated Zod schemas with z.compile for high-throughput fast-path validation.
outline: deep
---

# Fast-path validation with compile

Set [`compile`](/plugins/plugin-zod/reference/options#compile) to `true` to wrap generated schemas in `z.compile(...)`. Under the hood, `z.compile()` walks the schema once and generates flat, loop-free JavaScript validation code that executes significantly faster than standard interpreter traversal.

> [!NOTE]
> `compile` requires **Zod v4.5.0 or higher**.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      compile: true,
    }),
  ],
})
```

## Strict mode

To guarantee that your schemas actually compile into flat JavaScript and do not silently fall back to interpreted mode, configure `compile: { strict: true }`:

```typescript [kubb.config.ts]
pluginZod({
  compile: { strict: true },
})
```

## Output example

```typescript [src/gen/zod/petSchema.ts]
import * as z from 'zod'

export const petSchema = z.compile(
  z.object({
    id: z.number(),
    name: z.string(),
    tag: z.string().optional(),
  }),
)
```

With `compile: { strict: true }`:

```typescript [src/gen/zod/petSchema.ts]
import * as z from 'zod'

export const petSchema = z.compile(
  z.object({
    id: z.number(),
    name: z.string(),
    tag: z.string().optional(),
  }),
  { strict: true },
)
```

## Usage

Compiled schemas share the exact same API as standard Zod schemas (`.parse()`, `.safeParse()`, etc.), but validate significantly faster:

```typescript [usage.ts]
import { petSchema } from './src/gen/zod/petSchema'

// Runs through the compiled fast path
const pet = petSchema.parse({ id: 1, name: 'Rex' })
```
