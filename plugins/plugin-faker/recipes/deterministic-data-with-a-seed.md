---
layout: doc
title: Deterministic data with a seed
description: Produce the same mock values on every run by setting the seed option in @kubb/plugin-faker.
outline: deep
---

# Deterministic data with a seed

Set [`seed`](/plugins/plugin-faker/reference/options#seed) so the factories call `faker.seed(...)` and return the same values on every run. This keeps snapshot tests stable and makes a failing case reproducible.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFaker({
      seed: [100],
    }),
  ],
})
```

## Output example

```typescript [src/gen/mocks/createPet.ts]
import type { Pet } from '../types/Pet'
import { createCategory } from './createCategory'
import { createTag } from './createTag'
import { fakerEN as faker } from '@faker-js/faker'

export function createPet<TData extends Partial<Pet> = object>(data?: TData)
{
  faker.seed([100])
  const defaultFakeData = {
  id: faker.number.bigInt(),
  name: faker.string.alpha(),
  category: createCategory(),
  photoUrls: faker.helpers.multiple(() => (faker.string.alpha())),
  tags: faker.helpers.multiple(() => (createTag())),
  status: faker.helpers.arrayElement<NonNullable<Pet>["status"]>(['available', 'pending', 'sold']),
}
  return {
    ...defaultFakeData,
    ...(data || {}),
  } as Omit<typeof defaultFakeData, keyof TData> & TData
}
```

```typescript [usage.ts]
import { createPet } from './src/gen/mocks/createPet'

const pet = createPet()
const overridden = createPet({ name: 'Rex' })
```
