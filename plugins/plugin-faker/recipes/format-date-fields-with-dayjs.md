---
layout: doc
title: Format date fields with Day.js
description: Format generated date and time fields with Day.js by setting the dateParser option in @kubb/plugin-faker.
outline: deep
---

# Format date fields with Day.js

Format string `date` and `time` fields with Day.js by setting [`dateParser`](/plugins/plugin-faker/reference/options#dateparser) to `'dayjs'`. The plugin emits `dayjs(...).format(...)` and adds the import for you, so the factories reuse the date library your project already ships.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFaker({
      dateParser: 'dayjs',
    }),
  ],
})
```

## Output example

```typescript twoslash [src/gen/mocks/createOrder.ts]
import dayjs from 'dayjs'
import type { Order } from '../types/Order'
import { fakerEN as faker } from '@faker-js/faker'

export function createOrder<TData extends Partial<Order> = object>(data?: TData)
{
  const defaultFakeData = {
  id: faker.number.bigInt(),
  petId: faker.number.bigInt(),
  quantity: faker.number.int(),
  shipDateTime: faker.date.anytime().toISOString(),
  shipDate: dayjs(faker.date.anytime()).format("YYYY-MM-DD"),
  shipTime: dayjs(faker.date.anytime()).format("HH:mm:ss"),
  status: faker.helpers.arrayElement<NonNullable<Order>["status"]>(['placed', 'approved', 'delivered']),
  complete: faker.datatype.boolean(),
}
  return {
    ...defaultFakeData,
    ...(data || {}),
  } as Omit<typeof defaultFakeData, keyof TData> & TData
}
```

```typescript twoslash [usage.ts]
import { createOrder } from './src/gen/mocks/createOrder'

// shipDate/shipTime are formatted with dayjs, shipDateTime keeps the plain ISO string
const order = createOrder()
console.log(order.shipDate) // '2024-03-11'
```
