---
layout: doc
title: Recipes
description: Copy-paste kubb.config.ts configurations for the most common stacks including TypeScript, React Query, Zod, MSW, multi-spec setups and more.
outline: [2, 3]
---

# Recipes

Ready-made `kubb.config.ts` snippets for the setups people use most. Copy one in, install the matching packages, and run [`kubb generate`](./api/commands/generate).

## TypeScript only

The minimum setup. Generates TypeScript types and interfaces from your OpenAPI spec.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs()],
})
```

## TypeScript + React Query

Generates TypeScript types and [TanStack Query](https://tanstack.com/query) hooks for React.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginClient(), pluginReactQuery()],
})
```

## TypeScript + Vue Query

Generates TypeScript types and [TanStack Query](https://tanstack.com/query) hooks for Vue.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginVueQuery()],
})
```

## Zod schemas + MSW handlers

Runtime validation with [Zod](https://zod.dev) and ready-to-import [MSW](https://mswjs.io) request handlers backed by [Faker.js](https://fakerjs.dev) mock data.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginZod(), pluginFaker(), pluginMsw()],
})
```

## Faker + Zod for testing

Generate [Faker.js](https://fakerjs.dev) data factories alongside [Zod](https://zod.dev) schemas for use in unit and integration tests.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginZod(), pluginFaker()],
})
```

## Custom HTTP client

Pass a custom client implementation via `importPath` instead of using the built-in [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) or [Axios](https://axios-http.com) presets.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginClient({
      importPath: './my-client.ts',
    }),
  ],
})
```

## Multiple specifications

Generate from several specs in a single run. Pass an array to [`defineConfig`](./reference/configuration). Each entry runs independently with its own plugins and output directory.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig([
  {
    name: 'petStore',
    input: { path: './petStore.yaml' },
    output: { path: './src/gen/petStore', clean: true },
    plugins: [pluginTs()],
  },
  {
    name: 'userApi',
    input: { path: './userApi.yaml' },
    output: { path: './src/gen/userApi', clean: true },
    plugins: [pluginTs()],
  },
])
```

## Conditional config (watch-aware)

Pass a function to [`defineConfig`](./reference/configuration) to access CLI context. Use it to disable `clean` in watch mode so incremental runs are faster.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig(({ watch }) => ({
  input: { path: './petStore.yaml' },
  output: {
    path: './src/gen',
    clean: !watch,
  },
  plugins: [pluginTs()],
}))
```

Run with `kubb generate --watch` to enable incremental regeneration on spec changes.

## Format with Biome, lint with Oxlint

Run [Biome](https://biomejs.dev) formatting and [Oxlint](https://oxc.rs/docs/guide/usage/linter) linting on generated files as part of each build.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: {
    path: './src/gen',
    clean: true,
    format: 'biome',
    lint: 'oxlint',
  },
  plugins: [pluginTs()],
})
```

## Run a hook after generation

Use [`hooks.done`](./reference/configuration#hooks) to run shell commands after generation completes, for example to format or validate the output.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs()],
  hooks: {
    done: ['biome check --write ./src/gen'],
  },
})
```

## Monorepo with multiple outputs

Generate different client libraries for separate packages or teams from a single config file.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig([
  {
    name: 'public-api',
    input: { path: './specs/public.yaml' },
    output: { path: './packages/public-api/src/gen' },
    plugins: [pluginTs(), pluginClient(), pluginReactQuery()],
  },
  {
    name: 'admin-api',
    input: { path: './specs/admin.yaml' },
    output: { path: './packages/admin-api/src/gen' },
    plugins: [pluginTs(), pluginClient()],
  },
])
```

## Environment-aware configuration

Select input and output based on `NODE_ENV` so the same config works across development, staging, and production.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

const env = process.env['NODE_ENV'] ?? 'development'

const envConfig = {
  development: {
    input: { path: 'http://localhost:3000/openapi.json' },
    output: { path: './src/gen', clean: true },
  },
  staging: {
    input: { path: 'https://staging-api.example.com/openapi.json' },
    output: { path: './src/gen', clean: true },
  },
  production: {
    input: { path: './specs/production.json' },
    output: { path: './src/gen', clean: true },
  },
} as const

export default defineConfig({
  ...envConfig[env as keyof typeof envConfig],
  plugins: [pluginTs(), pluginClient()],
})
```

## Programmatic build

Drive Kubb from a script using [`createKubb`](./api/core#createkubb) from `@kubb/core`. Useful for monorepo orchestration or custom build pipelines.

Unlike `defineConfig`, `createKubb` does not inject defaults. You must provide `adapter`, `parsers`, and any plugins explicitly.

```typescript twoslash [generate.ts]
import { createKubb, Diagnostics } from '@kubb/core'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { pluginTs } from '@kubb/plugin-ts'

const kubb = createKubb({
  adapter: adapterOas(),
  parsers: [parserTs, parserTsx],
  input: { path: './petStore.yaml' },
  output: { path: './gen' },
  plugins: [pluginTs()],
})

kubb.hooks.on('kubb:plugin:end', ({ plugin, duration }) => {
  console.log(`${plugin.name} completed in ${duration}ms`)
})

const { files, diagnostics } = await kubb.safeBuild()

if (Diagnostics.hasError(diagnostics)) {
  console.error('Generation failed')
  process.exit(1)
}

console.log(`Generated ${files.length} files`)
```

Use `.build()` instead of `.safeBuild()` if you prefer exceptions over checking `diagnostics` in the result. See the [Core API](./api/core#createkubb) for the full `Kubb` instance API.

## CI validation

Validate the OpenAPI spec and fail the build on errors. Use [`hooks.done`](./reference/configuration#hooks) to run the [`kubb validate`](./api/commands/validate) command after generation.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs()],
  hooks: {
    done: ['kubb validate -i ./petStore.yaml'],
  },
})
```
