---
layout: doc
title: Basic Usage
description: Write your first kubb.config.ts, pick a few plugins, run kubb generate and import the generated types, client and hooks in your app.
outline: [2, 3]
---

# Basic Usage

In this tutorial you start from an empty config and finish with generated types, a client, and hooks imported into your app. Work through the five steps in order. By the end you will have run Kubb once and seen real code land in `./src/gen`.

## 1. Create the config

Everything Kubb does starts from `kubb.config.ts`. Begin with a minimal config that points at your spec and names an output directory.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
})
```

A couple of details to note here. `input.path` accepts a local file path or a URL, so you can point it at a spec on disk or one served over HTTP. `output.clean: true` wipes the output directory before each run, which keeps stale files from piling up.

## 2. Pick your plugins

Each output format is its own plugin, so you only generate what you ask for. Start small and add plugins as you need them. The tabs below build up from types alone to a full setup with types, a client, hooks, schemas, and mocks.

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
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } }), pluginAxios({ output: { path: 'clients' } })],
})
```

```typescript twoslash [+ React Query hooks]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } }), pluginAxios({ output: { path: 'clients' } }), pluginReactQuery({ output: { path: 'hooks' } })],
})
```

```typescript twoslash [+ Zod + MSW]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({ output: { path: 'models' } }),
    pluginAxios({ output: { path: 'clients' } }),
    pluginReactQuery({ output: { path: 'hooks' } }),
    pluginZod({ output: { path: 'schemas' } }),
    pluginMsw({ output: { path: 'mocks' } }),
  ],
})
```

:::

Here is what each plugin in those examples gives you.

| Plugin                                            | Package                    | Generates                                          |
| ------------------------------------------------- | -------------------------- | -------------------------------------------------- |
| [`pluginTs`](/plugins/plugin-ts)                  | `@kubb/plugin-ts`          | TypeScript types and interfaces                    |
| [`pluginAxios`](/plugins/plugin-axios)            | `@kubb/plugin-axios`       | Axios-based HTTP client functions                  |
| [`pluginReactQuery`](/plugins/plugin-react-query) | `@kubb/plugin-react-query` | [TanStack Query](https://tanstack.com/query) hooks |
| [`pluginZod`](/plugins/plugin-zod)                | `@kubb/plugin-zod`         | [Zod](https://zod.dev) validation schemas          |
| [`pluginMsw`](/plugins/plugin-msw)                | `@kubb/plugin-msw`         | [MSW](https://mswjs.io) request handlers           |

> [!NOTE]
> `pluginAxios`, `pluginReactQuery`, and `pluginMsw` each require `pluginTs` in the same config. `pluginReactQuery` also calls a registered client plugin, so add `pluginAxios` or `pluginFetch` alongside it.

See the [plugins catalogue](/plugins) for the full list.

## 3. Run generate

With the config saved, run the generate command. You should see each plugin report in turn and a summary at the end.

```shell [Terminal]
command: kubb generate
output:
  - ◆  Generation started
  - ◇  @kubb/plugin-ts          completed in 98ms
  - ◇  @kubb/plugin-axios       completed in 77ms
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

Kubb creates one folder per plugin under `output.path`, so the layout mirrors the config you wrote. Re-run it after every spec change. See [`kubb generate`](../api/commands/generate) for flags like `--watch` and `--reporter`.

## 4. Use the generated code

Now for the payoff. Import the generated code into your app. The import paths follow the `output.path` values you set for each plugin, so a plugin pointed at `models` lives under `gen/models`.

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

const { data: pet } = await getPetById({ path: { petId: 1 } })
```

```typescript [React Query]
import { useGetPetById } from './gen/hooks/useGetPetById'

function Pet({ id }: { id: number }) {
  const { data, isLoading } = useGetPetById({ path: { petId: id } })
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

That is the full loop. From now on, run `npm run generate` whenever the spec changes, then commit the output. To skip the manual step, [`unplugin-kubb`](/docs/5.x/guide/integrations/) generates during your build with [Vite](https://vite.dev), [Rollup](https://rollupjs.org), [Webpack](https://webpack.js.org), and others.
