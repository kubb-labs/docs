---
layout: doc
title: Introduction
description: Kubb is the meta framework for code generation. A plugin-based system that turns any API specification into TypeScript types, API clients, hooks, validators, and mocks.
outline: [2, 3]
---

# Introduction

Kubb is a meta framework for code generation. It runs a plugin-based pipeline on top of any API specification. An [adapter](/adapters) reads your spec. [Parsers](/parsers) turn the [AST](/docs/5.x/guide/concepts/ast) into source files. [Plugins](/plugins) generate the output. The pipeline writes, formats, and lints the result, all from a single config file.

The default adapter reads [OpenAPI](https://www.openapis.org/) 2.0, 3.0, and 3.1. From there Kubb generates TypeScript types, React Query hooks, Zod validators, MSW mocks, or a custom output. You stop hand-maintaining generated code. The output is deterministic. The same spec always produces the same result.

Follow one schema through that pipeline. The `Pet` schema enters as YAML, becomes an AST node, turns into a file node, and lands on disk as TypeScript:

<SpecJourney />

The [architecture guide](/docs/5.x/guide/concepts/architecture) covers each layer in depth.

## Features

- Generate [TypeScript types](/plugins/plugin-ts/), [React Query](/plugins/plugin-react-query/) and [Vue Query](/plugins/plugin-vue-query/) hooks, [SWR](/plugins/plugin-swr/) hooks, [Zod](/plugins/plugin-zod/) validators, [Faker](/plugins/plugin-faker/) mocks, and [MSW](/plugins/plugin-msw/) handlers, each from its own plugin.
- Generate a typed [Axios](/plugins/plugin-axios/) or [Fetch](/plugins/plugin-fetch/) client with status-keyed results, auth, validation, file uploads, [server-sent events](/plugins/plugin-fetch/guide/server-sent-events), [interceptors](/plugins/plugin-fetch/guide/interceptors), and a [swappable transport](/plugins/plugin-fetch/guide/transport).
- Read any OpenAPI 2.0, 3.0, or 3.1 spec through the [OpenAPI adapter](/adapters/adapter-oas/), or add your own [adapter](/docs/5.x/guide/concepts/adapters).
- Shape the output by grouping files by tag or path, including or excluding operations, and writing to disk, memory, or a [custom storage backend](/docs/5.x/guide/concepts/storage).
- Generate [Cypress](/plugins/plugin-cypress/) tests and a [Model Context Protocol server](/plugins/plugin-mcp/), or [write your own plugin](/docs/5.x/guide/going-further/creating-plugins).
- Run generation in [Vite](/docs/5.x/guide/integrations/vite), [Nuxt](/docs/5.x/guide/integrations/nuxt), and other bundlers with `unplugin-kubb`, or from [AI assistants](/docs/5.x/ai/mcp) and [Claude Code](/docs/5.x/ai/claude).

Ready for more? Read [Installation](./installation) and [Basic Usage](./basic-usage), then reach for [Configuration](/docs/5.x/reference/configuration), [Recipes](/docs/5.x/guide/recipes), and [Integrations](/docs/5.x/guide/integrations/) when you need them.

## See it work

Here is the whole loop, start to finish. Install Kubb together with one plugin:

```shell [Terminal]
npm install -D kubb@beta @kubb/plugin-ts@beta
```

Create a `kubb.config.ts` next to your spec. It points at the spec, sets an output directory, and lists the plugins you want. This one generates TypeScript types with [`@kubb/plugin-ts`](/plugins/plugin-ts/):

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})
```

Run the generator:

```shell [Terminal]
kubb generate
```

Kubb writes one `.ts` file per schema into `./src/gen/models`. Import a type and the editor knows your API:

```typescript twoslash
// @filename: src/gen/models/Pet.ts
export type Pet = { id: number; name: string }
// @filename: src/app.ts
// ---cut---
import type { Pet } from './gen/models/Pet'

const pet: Pet = { id: 1, name: 'Cat' }
```

That is the full cycle. Change the spec, run `kubb generate` again, and the types follow.

## Community

Join the [Discord server](https://discord.gg/shfBFeczrm), file an issue on [GitHub](https://github.com/kubb-labs/kubb/issues), or sponsor the project on [GitHub Sponsors](https://github.com/sponsors/stijnvanhulle) or [Open Collective](https://opencollective.com/kubb).
