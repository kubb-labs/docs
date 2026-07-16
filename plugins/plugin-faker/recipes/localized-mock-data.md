---
layout: doc
title: Localized mock data
description: Generate region-specific mock values from @kubb/plugin-faker by setting the locale option.
outline: deep
---

# Localized mock data

Generate values that read as German by setting [`locale`](/plugins/plugin-faker/reference/options#locale) to `'de'`. The plugin switches the Faker import to `fakerDE`, so names, addresses, and phone numbers match that region.

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
      locale: 'de',
    }),
  ],
})
```

## Output example

```typescript [src/gen/mocks/createPet.ts]
import type { Pet } from '../types/Pet'
import { createCategory } from './createCategory'
import { createTag } from './createTag'
import { fakerDE as faker } from '@faker-js/faker'

export function createPet<TData extends Partial<Pet> = object>(data?: TData)
{
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

// faker.number/string calls come from fakerDE, so text-like fields read as German
const pet = createPet()
```
