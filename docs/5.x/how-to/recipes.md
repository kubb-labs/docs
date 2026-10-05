---
layout: doc
title: Recipes
description: Configure common Kubb outputs, multiple specifications, watch mode,
  formatters, and programmatic builds.
outline:
  - 2
  - 3
order: 1
navigation:
  title: Configure generation
---

# Recipes

Ready-made `kubb.config.ts` snippets for common setups. Copy one in, install the matching packages, and run [`kubb generate`](/docs/5.x/reference/commands/generate).

## TypeScript only

The smallest setup, generating TypeScript types and interfaces from your OpenAPI spec.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs()],
})
```

## TypeScript + React Query

Generates types and [TanStack Query](https://tanstack.com/query) hooks for React.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginAxios(), pluginReactQuery({ hooks: true })],
})
```

## TypeScript + Vue Query

Generates types and [TanStack Query](https://tanstack.com/query) hooks for Vue.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginAxios(), pluginVueQuery({ hooks: true })],
})
```

## Zod schemas + MSW handlers

Runtime validation with [Zod](https://zod.dev), plus [MSW](https://mswjs.io) request handlers backed by [Faker.js](https://fakerjs.dev) mock data.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginZod(), pluginFaker(), pluginMsw({ parser: 'faker', handlers: true })],
})
```

## Pick the HTTP client

Choose [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) or [Axios](https://axios-http.com) by registering the matching plugin. Swap `pluginFetch` for `pluginAxios` to use the global `fetch` instead.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginAxios()],
})
```

## Multiple specifications

Generate from several specs in one run. Pass an array to [`defineConfig`](/docs/5.x/reference/configuration). Each entry runs on its own, with its own plugins and output directory.

Set a `name` per entry so each one shows up in the CLI output.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig([
  {
    name: 'petStore',
    input: './petStore.yaml',
    output: { path: './src/gen/petStore', clean: true },
    plugins: [pluginTs()],
  },
  {
    name: 'userApi',
    input: './userApi.yaml',
    output: { path: './src/gen/userApi', clean: true },
    plugins: [pluginTs()],
  },
])
```

## Conditional config (watch-aware)

Pass a function to [`defineConfig`](/docs/5.x/reference/configuration) to read CLI context. Here it turns off `clean` in watch mode so incremental runs stay fast.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig(({ watch }) => ({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
    clean: !watch,
  },
  plugins: [pluginTs()],
}))
```

Run `kubb generate --watch` to regenerate on spec changes.

## Format with Biome, lint with Oxlint

Format generated files with [Biome](https://biomejs.dev) and lint them with [Oxlint](https://oxc.rs/docs/guide/usage/linter) on every build. Set `format` and `lint` to `'auto'` to pick whichever tool is installed.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
    clean: true,
    format: 'biome',
    lint: 'oxlint',
  },
  plugins: [pluginTs()],
})
```

## Run a command after generation

Use [`output.postGenerate`](/docs/5.x/reference/configuration#output-postgenerate) to run shell commands, such as a formatter pass or a type check, once the generated files are formatted and linted.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
    postGenerate: ['biome check --write ./src/gen'],
  },
  plugins: [pluginTs()],
})
```

## Programmatic build

Drive Kubb from a script with [`createKubb`](/docs/5.x/reference/kit/engine#createkubb) from the `kubb` package, paired with `Diagnostics` from `kubb/kit`. This fits monorepo orchestration and custom build pipelines. It applies the same defaults as `defineConfig`, so a shared config generates the same files through the CLI and a script.

```typescript twoslash [generate.ts]
import { createKubb } from 'kubb'
import { Diagnostics } from 'kubb/kit'
import { pluginTs } from '@kubb/plugin-ts'

const kubb = createKubb({
  input: './petStore.yaml',
  output: { path: './gen' },
  plugins: [pluginTs()],
})

kubb.hooks.hook('kubb:plugin:end', ({ plugin, duration }) => {
  console.log(`${plugin.name} completed in ${duration}ms`)
})

const { files, diagnostics } = await kubb.safeBuild()

if (Diagnostics.hasError(diagnostics)) {
  for (const diagnostic of diagnostics.filter(Diagnostics.isProblem)) {
    if (diagnostic.severity === 'error') {
      console.error(`${diagnostic.plugin ?? 'kubb'}: ${diagnostic.message}`)
    }
  }
  process.exit(1)
}

console.log(`Generated ${files.length} files`)
```

Use `.build()` instead of `.safeBuild()` if you want it to throw on errors rather than return `diagnostics`. See the [Kit API](/docs/5.x/reference/kit/engine#createkubb) for the full `Kubb` instance API.

## Validate in CI

Run `kubb validate ./petStore.yaml` before generation to fail on an invalid specification. See [Validate command](/docs/5.x/reference/commands/validate) and [CI snapshots](/docs/5.x/how-to/ci).
