---
layout: doc
title: Installation
description: Install Kubb in any Node.js project. Use the interactive kubb init wizard or set up manually with the kubb package and a handful of plugins.
outline: [2, 3]
---

# Installation

## Prerequisites

- [Node.js](https://nodejs.org/) 22 or higher ([Download](https://nodejs.org/en/download))
- [TypeScript](https://www.typescriptlang.org/) 4.7 or higher, if you use a `kubb.config.ts` or import generated types

## Quick start (recommended)

The `kubb init` wizard detects your package manager, asks where your spec lives and where generated files should go, then installs the plugins you pick and writes a `kubb.config.ts`.

```shell
npx kubb@beta init
```

Then run:

```shell
npx kubb@beta generate
```

## Manual installation

### 1. Install Kubb

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
> The `kubb` package includes the CLI, the core runtime, the [OpenAPI adapter](/adapters/adapter-oas), and the [TypeScript parser](/parsers/parser-ts) by default. You only need to add plugins for the outputs you want.

### 2. Add plugins

Each output format is its own package. Install only what you need.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta @kubb/plugin-client@beta @kubb/plugin-react-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta @kubb/plugin-client@beta @kubb/plugin-react-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts@beta @kubb/plugin-client@beta @kubb/plugin-react-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta @kubb/plugin-client@beta @kubb/plugin-react-query@beta
```

:::

| Package                                                   | Generates                                                                                                                             |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts)                   | [TypeScript](https://www.typescriptlang.org/) types and interfaces                                                                    |
| [`@kubb/plugin-client`](/plugins/plugin-client)           | HTTP client functions ([Axios](https://axios-http.com/), [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API), custom) |
| [`@kubb/plugin-react-query`](/plugins/plugin-react-query) | [TanStack Query](https://tanstack.com/query) hooks for React                                                                          |
| [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query)     | [TanStack Query](https://tanstack.com/query) hooks for Vue                                                                            |
| [`@kubb/plugin-zod`](/plugins/plugin-zod)                 | [Zod](https://zod.dev/) schemas for runtime validation                                                                                |
| [`@kubb/plugin-faker`](/plugins/plugin-faker)             | [Faker.js](https://fakerjs.dev/) mock data generators                                                                                 |
| [`@kubb/plugin-msw`](/plugins/plugin-msw)                 | [MSW](https://mswjs.io/) request handlers                                                                                             |
| [`@kubb/plugin-cypress`](/plugins/plugin-cypress)         | [Cypress](https://www.cypress.io/) end-to-end tests                                                                                   |
| [`@kubb/plugin-mcp`](/plugins/plugin-mcp)                 | [MCP](https://modelcontextprotocol.io/) server from your spec                                                                         |
| [`@kubb/plugin-redoc`](/plugins/plugin-redoc)             | [Redoc](https://redocly.com/docs/redoc/) API documentation                                                                            |

See the [plugins](/plugins) page for a complete list.

### 3. Create `kubb.config.ts`

The config points Kubb at your spec and your output directory. `defineConfig` wires up the OpenAPI adapter for you.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs()],
})
```

Kubb looks for `kubb.config.ts` (recommended) in the project root and the `.config/` and `configs/` subdirectories. JavaScript variants (`.js`, `.mjs`, `.cjs`) and TypeScript `.mts`/`.cts` are also supported.

> [!TIP]
> Use `--config <path>` to point Kubb at a config file in a custom location.

### 4. Add a script

Add a `generate` script to `package.json` so you run generation with one command:

```json [package.json]
{
  "scripts": {
    "generate": "kubb generate"
  }
}
```

### 5. Generate

```shell
npm run generate
```

Generated files appear under `output.path`. Re-run this command whenever your spec changes.

Continue to [Basic Usage](./basic-usage) to write a full config with multiple plugins, or jump to [Configuration](../reference/configuration) for every available option. To run generation as part of your bundler, see [Integrations](/docs/5.x/integrations/).
