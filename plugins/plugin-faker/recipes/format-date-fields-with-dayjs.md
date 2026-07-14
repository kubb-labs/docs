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
