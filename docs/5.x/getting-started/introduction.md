---
layout: doc
title: Introduction
description: Kubb is the meta framework for code generation. A plugin-based system that turns any API specification into TypeScript types, API clients, hooks, validators, and mocks.
outline: [2, 3]
---

# Introduction

Kubb is a meta framework for code generation. It runs a plugin-based pipeline on top of any API specification. An [adapter](/adapters) reads your spec. [Parsers](/parsers) turn the [AST](/docs/5.x/guide/concepts/ast) into source files. [Plugins](/plugins) generate the output. The pipeline writes, formats, and lints the result, all from a single config file.

The default adapter reads [OpenAPI](https://www.openapis.org/) 2.0, 3.0, and 3.1. From there Kubb generates TypeScript types, React Query hooks, Zod validators, MSW mocks, or a custom output. You stop hand-maintaining generated code. The output is deterministic. The same spec always produces the same result.

## See it work

Here is the whole loop, start to finish. Install Kubb together with one plugin:

```shell [Terminal]
npm install -D @kubb/core@beta @kubb/plugin-ts@beta
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

## Features

- Generate [TypeScript types](/plugins/plugin-ts), [React Query](/plugins/plugin-react-query) and [Vue Query](/plugins/plugin-vue-query) hooks, [SWR](/plugins/plugin-swr) hooks, [Zod](/plugins/plugin-zod) validators, [Faker](/plugins/plugin-faker) mock data, and [MSW](/plugins/plugin-msw) handlers, each from its own plugin so you add only the ones you need.
- Call your API through a generated [Axios](/plugins/plugin-axios) or [Fetch](/plugins/plugin-fetch) client that hands you one typed function per operation, a result keyed on the HTTP status, runtime validation, auth resolved from your OpenAPI security schemes, typed [server-sent events](/docs/5.x/guide/going-further/server-sent-events), [interceptors](/docs/5.x/guide/going-further/interceptors), and a [swappable transport](/docs/5.x/guide/going-further/transport).
- Read any OpenAPI 2.0, 3.0, or 3.1 spec through the [OpenAPI adapter](/adapters/adapter-oas), or add an [adapter](/docs/5.x/guide/concepts/adapters) for another input format.
- Shape the output by grouping files by tag or path, emitting [barrel files](/docs/5.x/guide/concepts/barrel-files), and including or excluding operations.
- Generate [Cypress](/plugins/plugin-cypress) tests, a [Model Context Protocol server](/plugins/plugin-mcp) that lets AI assistants call your API, or output no plugin covers by [writing your own](/docs/5.x/guide/going-further/creating-plugins) on the same APIs the official plugins use.
- Run generation inside [Vite](/docs/5.x/guide/integrations/vite), [Nuxt](/docs/5.x/guide/integrations/nuxt), and other build tools with `unplugin-kubb`, or drive it from [AI assistants](/docs/5.x/ai/mcp) and [Claude Code](/docs/5.x/ai/claude).

Ready for more? Read [Installation](./installation) and [Basic Usage](./basic-usage), then reach for [Configuration](/docs/5.x/reference/configuration), [Recipes](/docs/5.x/guide/recipes), and [Integrations](/docs/5.x/guide/integrations/) when you need them.

## Community

Join the [Discord server](https://discord.gg/shfBFeczrm), file an issue on [GitHub](https://github.com/kubb-labs/kubb/issues), or sponsor the project on [GitHub Sponsors](https://github.com/sponsors/stijnvanhulle) or [Open Collective](https://opencollective.com/kubb).
