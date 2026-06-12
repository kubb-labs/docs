---
layout: doc
title: Basic Usage
description: Write your first kubb.config.ts, pick a few plugins, run kubb generate and import the generated types, client and hooks in your app.
outline: [2, 3]
---

# Basic Usage

## 1. Create the config

`kubb.config.ts` drives everything Kubb does. The minimum config points at your spec and an output directory:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
})
```

`input.path` accepts a local file path or a URL. `output.clean: true` wipes the output directory before each run.

## 2. Pick your plugins

Each output format is its own plugin. Add only the ones you need:

::: code-group

```typescript twoslash [TypeScript types]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})
```

```typescript twoslash [Types + HTTP client]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } }), pluginClient({ output: { path: 'clients' } })],
})
```

```typescript twoslash [+ React Query hooks]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } }), pluginClient({ output: { path: 'clients' } }), pluginReactQuery({ output: { path: 'hooks' } })],
})
```

```typescript twoslash [+ Zod + MSW]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({ output: { path: 'models' } }),
    pluginClient({ output: { path: 'clients' } }),
    pluginReactQuery({ output: { path: 'hooks' } }),
    pluginZod({ output: { path: 'schemas' } }),
    pluginMsw({ output: { path: 'mocks' } }),
  ],
})
```

:::

| Plugin                                            | Package                    | Generates                                          |
| ------------------------------------------------- | -------------------------- | -------------------------------------------------- |
| [`pluginTs`](/plugins/plugin-ts)                  | `@kubb/plugin-ts`          | TypeScript types and interfaces                    |
| [`pluginClient`](/plugins/plugin-client)          | `@kubb/plugin-client`      | Fetch-based HTTP client functions                  |
| [`pluginReactQuery`](/plugins/plugin-react-query) | `@kubb/plugin-react-query` | [TanStack Query](https://tanstack.com/query) hooks |
| [`pluginZod`](/plugins/plugin-zod)                | `@kubb/plugin-zod`         | [Zod](https://zod.dev) validation schemas          |
| [`pluginMsw`](/plugins/plugin-msw)                | `@kubb/plugin-msw`         | [MSW](https://mswjs.io) request handlers           |

> [!NOTE]
> `pluginClient`, `pluginReactQuery`, and `pluginMsw` each require `pluginTs` in the same config.

See the [plugins catalogue](/plugins) for the full list.

## 3. Run generate

```terminal
command: kubb generate
output:
  - ◆  Generation started
  - ◇  @kubb/plugin-ts          completed in 98ms
  - ◇  @kubb/plugin-client      completed in 77ms
  - ◇  @kubb/plugin-react-query completed in 201ms
  - ◇  @kubb/plugin-zod         completed in 134ms
  - ◇  @kubb/plugin-msw         completed in 63ms
  - ◇  Generation completed
  -
  -  Plugins  5 passed (5)
  -    Files  156 generated
  - Duration  1.2s
  -   Output  ./src/gen
```

Kubb creates one folder per plugin under `output.path`. Re-run after every spec change. See [`kubb generate`](../api/commands/generate) for flags like `--watch` and `--reporter`.

## 4. Use the generated code

Import paths follow the `output.path` values you set for each plugin:

::: code-group

```typescript twoslash [Types]
// @filename: src/gen/models/Pet.ts
export type Pet = { id: number; name: string }
// @filename: src/app.ts
// ---cut---
import type { Pet } from './gen/models/Pet'

const pet: Pet = { id: 1, name: 'Cat' }
```

```typescript [HTTP client]
import { getPetById } from './gen/clients/getPetById'

const pet = await getPetById({ pathParams: { petId: 1 } })
```

```typescript [React Query]
import { useGetPetById } from './gen/hooks/useGetPetById'

function Pet({ id }: { id: number }) {
  const { data, isLoading } = useGetPetById({ pathParams: { petId: id } })
  if (isLoading) return null
  return <span>{data?.name}</span>
}
```

```typescript [Zod]
import { petSchema } from './gen/schemas/petSchema'

const result = petSchema.safeParse(unknown)
```

```typescript [MSW handlers]
import { setupServer } from 'msw/node'
import { getPetByIdHandler } from './gen/mocks/getPetByIdHandler'

const server = setupServer(getPetByIdHandler())
server.listen()
```

:::

## 5. Keep it in sync

- **Manual**: run `npm run generate` whenever the spec changes and commit the output.
- **Bundler integration**: use [`unplugin-kubb`](../integrations/) to run generation as part of [Vite](https://vite.dev), [Rollup](https://rollupjs.org), [Webpack](https://webpack.js.org), and others.
