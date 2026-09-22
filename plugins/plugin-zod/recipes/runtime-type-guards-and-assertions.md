---
layout: doc
title: Runtime type guards and assertions
description: Generate TypeScript type guards (is*) and assertion functions (assert*) using Zod v4's native validate API.
outline: deep
---

# Runtime type guards and assertions

Set [`typeGuards`](/plugins/plugin-zod/reference/options#typeguards) to `true` to generate native TypeScript type predicates (`isPet`) and assertion functions (`assertPet`) alongside your Zod schemas.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      typeGuards: true,
      inferred: true,
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/petSchema.ts]
import * as z from 'zod'

export const petSchema = z.object({
  id: z.int32(),
  name: z.string(),
})

export type PetSchemaType = z.infer<typeof petSchema>

/**
 * Type guard for {@link petSchema}
 */
export const isPet = (data: unknown): data is PetSchemaType => petSchema.validate(data)

/**
 * Asserter for {@link petSchema}
 * @throws {z.ZodError} If data is invalid
 */
export function assertPet(data: unknown): asserts data is PetSchemaType {
  if (!petSchema.validate(data)) {
    petSchema.parse(data)
  }
}
```

## Usage

### Filtering with type guards

Type guards work seamlessly with array methods and conditional checks:

```typescript [usage.ts]
import { isPet } from './src/gen/zod/petSchema'

const rawItems: unknown[] = await fetch('/api/pets').then((r) => r.json())

// pets is typed as PetSchemaType[]
const pets = rawItems.filter(isPet)
```

### Asserting data contracts

Assertion functions validate data at runtime and narrow the variable in the current scope without returning a new object:

```typescript [service.ts]
import { assertPet } from './src/gen/zod/petSchema'

export function processPayload(payload: unknown) {
  assertPet(payload)

  // payload is narrowed to PetSchemaType here
  console.log(payload.name)
}
```

Because `assertPet` tests with `petSchema.validate(payload)` on the happy path, valid data incurs zero allocation overhead and runs at maximum speed. Only invalid data pays the cost of formatting a full `z.ZodError`.
