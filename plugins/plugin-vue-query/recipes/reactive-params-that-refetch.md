---
layout: doc
title: Reactive params that refetch
description: Pass a ref or getter to a generated Vue Query composable so the query re-runs when the value changes.
outline: deep
---

# Reactive params that refetch

Set [`hooks: true`](/plugins/plugin-vue-query/reference/options#hooks) to generate `use*` composables. Their parameters accept a plain value, a `ref`, or a getter (`MaybeRefOrGetter`), so passing a getter makes the query re-run whenever the value it reads changes.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginFetch(), pluginVueQuery({ hooks: true })],
})
```

```typescript
import { ref } from 'vue'
import { useFindPetsByTags } from './gen/hooks/useFindPetsByTags'

const tags = ref(['dog'])
const { data, error, isLoading } = useFindPetsByTags({ query: () => ({ tags: tags.value }) })
```
