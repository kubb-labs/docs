---
layout: doc
title: Introduction
description: Kubb is the meta framework for code generation. A plugin-based system that turns any API specification into TypeScript types, API clients, hooks, validators, and mocks.
outline: [2, 3]
---

# Introduction

Kubb is a meta framework for code generation. It runs a plugin-based pipeline on top of any API specification. An [adapter](/adapters) reads your spec. [Parsers](/parsers) turn the [AST](/docs/5.x/guide/concepts/ast) into source files. [Plugins](/plugins) generate the output. The pipeline writes, formats, and lints the result, all from a single config file.

The default adapter reads [OpenAPI](https://www.openapis.org/) 2.0, 3.0, and 3.1. For [GraphQL](https://graphql.org/), [JSON Schema](https://json-schema.org/), [gRPC](https://grpc.io/), or any other format, you write your own adapter. From there Kubb generates TypeScript types, React Query hooks, Zod validators, MSW mocks, or a custom output. You stop hand-maintaining generated code. The output is deterministic. The same spec always produces the same result.

## See it work

Here is the whole loop, start to finish. Install Kubb together with one plugin:

```shell [Terminal]
npm install -D @kubb/core @kubb/plugin-ts
```

Create a `kubb.config.ts` next to your spec. It points at the spec, sets an output directory, and lists the plugins you want. This one generates TypeScript types with [`@kubb/plugin-ts`](/plugins/plugin-ts):

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
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

## What you can generate

Each output format is its own plugin, so you add only the ones you need. The starter set covers [TypeScript types](/plugins/plugin-ts), HTTP clients for [Axios](/plugins/plugin-axios) or [Fetch](/plugins/plugin-client), [React Query](/plugins/plugin-react-query) and [Vue Query](/plugins/plugin-vue-query) hooks, [Zod](/plugins/plugin-zod) validators, [MSW](/plugins/plugin-msw) handlers, and [Faker](/plugins/plugin-faker) mock data.

Beyond the app code, you can generate [Cypress](/plugins/plugin-cypress) tests and [Model Context Protocol](/plugins/plugin-mcp) servers that let AI assistants call your API. When nothing fits, [write your own plugin](/docs/5.x/guide/going-further/creating-plugins) with the same APIs the official ones use. The [plugins catalogue](/plugins) lists them all.

Ready for more? Read [Installation](./installation) and [Basic Usage](./basic-usage), then reach for [Configuration](/docs/5.x/api/configuration), [Recipes](/docs/5.x/guide/recipes), and [Integrations](/docs/5.x/guide/integrations/) when you need them.

## Community

Join the [Discord server](https://discord.gg/shfBFeczrm), file an issue on [GitHub](https://github.com/kubb-labs/kubb/issues), or sponsor the project on [GitHub Sponsors](https://github.com/sponsors/stijnvanhulle) or [Open Collective](https://opencollective.com/kubb).
