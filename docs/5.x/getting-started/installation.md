---
layout: doc
title: Installation
description: Install Kubb in any Node.js project. Use the interactive kubb init wizard or set up manually with the kubb package and a handful of plugins.
outline: [2, 3]
---

# Installation

This page walks you through getting Kubb running in your project, from the first install to your first generated files. Pick the quick start if you want the wizard to set everything up for you, or follow the manual steps to see each piece.

## Prerequisites

Before you start, make sure your machine has these two tools installed:

- [Node.js](https://nodejs.org/) 22 or higher ([Download](https://nodejs.org/en/download))
- [TypeScript](https://www.typescriptlang.org/) 5.0 or higher, if you use a `kubb.config.ts` or import generated types

## Quick start (recommended)

The fastest way to start is the `kubb init` wizard. It detects your package manager, asks where your spec lives and where generated files should go, installs the plugins you pick, and writes a `kubb.config.ts` for you.

Run the wizard and answer its prompts:

```shell [Terminal]
npx kubb@beta init
```

Once the wizard finishes, generate your files:

```shell [Terminal]
npx kubb@beta generate
```

That is all you need to get started. If you would rather set things up by hand, the manual steps below walk through the same result one piece at a time.

## Manual installation

Prefer to do it yourself? These five steps install Kubb, add the plugins you want, write a config, and run your first generation.

### 1. Install Kubb

Start by adding the `kubb` package as a dev dependency. Use the tab for your package manager:

::: code-group

```shell [bun]
bun add -d kubb@beta
```

```shell [pnpm]
pnpm add -D kubb@beta
```

```shell [npm]
npm install --save-dev kubb@beta
```

```shell [yarn]
yarn add -D kubb@beta
```

:::

> [!NOTE]
> The `kubb` package includes the CLI, the core runtime, the [OpenAPI adapter](/adapters/adapter-oas/), and the TypeScript, TSX, and Markdown parsers by default. You only need to add plugins for the outputs you want.

### 2. Add plugins

Each output format is its own package, so you install only what you need. The example below adds TypeScript types, an Axios client, and React Query hooks, but you can swap in any plugins from the table that follows:

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta @kubb/plugin-axios@beta @kubb/plugin-react-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta @kubb/plugin-axios@beta @kubb/plugin-react-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts@beta @kubb/plugin-axios@beta @kubb/plugin-react-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta @kubb/plugin-axios@beta @kubb/plugin-react-query@beta
```

:::

| Package                                                   | Generates                                                                                                                             |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts/)                   | [TypeScript](https://www.typescriptlang.org/) types and interfaces                                                                    |
| [`@kubb/plugin-axios`](/plugins/plugin-axios/)             | [Axios](https://axios-http.com/) HTTP client functions                                                                               |
| [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)             | [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) HTTP client functions                                           |
| [`@kubb/plugin-react-query`](/plugins/plugin-react-query/) | [TanStack Query](https://tanstack.com/query) hooks for React                                                                          |
| [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/)     | [TanStack Query](https://tanstack.com/query) hooks for Vue                                                                            |
| [`@kubb/plugin-zod`](/plugins/plugin-zod/)                 | [Zod](https://zod.dev/) schemas for runtime validation                                                                                |
| [`@kubb/plugin-faker`](/plugins/plugin-faker/)             | [Faker.js](https://fakerjs.dev/) mock data generators                                                                                 |
| [`@kubb/plugin-msw`](/plugins/plugin-msw/)                 | [MSW](https://mswjs.io/) request handlers                                                                                             |
| [`@kubb/plugin-cypress`](/plugins/plugin-cypress/)         | [Cypress](https://www.cypress.io/) end-to-end tests                                                                                   |
| [`@kubb/plugin-mcp`](/plugins/plugin-mcp/)                 | [MCP](https://modelcontextprotocol.io/) server from your spec                                                                         |
| [`@kubb/plugin-redoc`](/plugins/plugin-redoc/)             | [Redoc](https://redocly.com/docs/redoc/) API documentation                                                                            |

See the [plugins](/plugins) page for a complete list.

### 3. Create `kubb.config.ts`

Next, create a `kubb.config.ts` file in your project root. The config points Kubb at your spec and your output directory, and `defineConfig` wires up the OpenAPI adapter, the default parsers, and a barrel plugin for you. Here is a minimal starting point:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs()],
})
```

Kubb looks for `kubb.config.ts` in the project root and the `.config/` and `configs/` subdirectories. JavaScript variants (`.js`, `.mjs`, `.cjs`) and TypeScript `.mts`/`.cts` also work.

> [!TIP]
> Use `--config <path>` to point Kubb at a config file in a custom location.

### 4. Add a script

To save typing, add a `generate` script to your `package.json` so you can run generation with one command:

```json [package.json]
{
  "scripts": {
    "generate": "kubb generate"
  }
}
```

### 5. Generate

You are ready for the payoff. Run the script to generate your files:

```shell [Terminal]
npm run generate
```

Your generated files appear under `output.path`. Re-run this command whenever your spec changes, and the output updates to match.

Nice work, your project is set up. Continue to [Basic Usage](./basic-usage) to write a full config with multiple plugins. Jump to [Configuration](/docs/5.x/reference/configuration) for every option. To run generation from your bundler, see [Integrations](/docs/5.x/guide/integrations/).
