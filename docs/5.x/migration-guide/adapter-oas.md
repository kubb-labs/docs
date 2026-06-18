---
title: 'Migration: @kubb/adapter-oas'
description: Configuration changes for @kubb/adapter-oas when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/adapter-oas`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/adapter-oas`](/adapters/adapter-oas).

v4 repeated the same schema-level options on every plugin. In v5 they live on [`adapterOas`](/adapters/adapter-oas) and apply once across all plugins. Remove them from each plugin and set them on the adapter.

| Option            | Removed from                              | v5 location                       |
| ----------------- | ----------------------------------------- | --------------------------------- |
| `dateType`        | `plugin-ts`, `plugin-faker`, `plugin-zod` | `adapterOas({ dateType })`        |
| `integerType`     | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ integerType })`     |
| `unknownType`     | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ unknownType })`     |
| `emptySchemaType` | `plugin-ts`, `plugin-zod`, `plugin-faker` | `adapterOas({ emptySchemaType })` |
| `enumSuffix`      | `plugin-ts`                               | `adapterOas({ enumSuffix })`      |
| `contentType`     | `plugin-ts`, `plugin-msw`                 | `adapterOas({ contentType })`     |

> [!IMPORTANT]
> The default `integerType` changed from `'number'` to `'bigint'`. OpenAPI `int64` fields now map to `bigint`. Set `integerType: 'number'` on `adapterOas` to keep the old output.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
      emptySchemaType: 'unknown',
      enumSuffix: 'enum',
    }),
    pluginZod({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
    }),
    pluginFaker({
      dateType: 'date',
      integerType: 'number',
      unknownType: 'unknown',
    }),
  ],
})
```

```typescript twoslash [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({
    dateType: 'date',
    integerType: 'number',
    unknownType: 'unknown',
    emptySchemaType: 'unknown',
    enumSuffix: 'enum',
  }),
  plugins: [pluginTs(), pluginZod(), pluginFaker()],
})
```

:::

`pluginOas()` no longer belongs in `plugins`. Its `validate`, `discriminator`, and `contentType` options move to the same `adapter` key, and the old `serverIndex` and `serverVariables` become a single `server: { index, variables }` object. See [`@kubb/plugin-oas` removed](/docs/5.x/migration-guide#kubb-plugin-oas-removed) on the main guide.

The `discriminator` values are also renamed. Use `'preserve'` in place of `'strict'`, and `'propagate'` in place of `'inherit'`.

::: code-group

```typescript [v4 server + discriminator]
pluginOas({
  serverIndex: 0,
  serverVariables: { env: 'prod' },
  discriminator: 'inherit',
})
```

```typescript [v5 server + discriminator]
adapterOas({
  server: { index: 0, variables: { env: 'prod' } },
  discriminator: 'propagate',
})
```

:::
