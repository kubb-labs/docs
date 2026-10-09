---
layout: doc
title: Installation
description: Install Kubb, verify the CLI, and choose output plugins for your project.
outline: [2, 3]
order: 1
navigation:
  title: Installation
  icon: i-iconoir-download
---

# Installation

Install Kubb in an existing project using your package manager. If you want to learn generation with a supplied specification and expected output, follow [Generate your first client](/docs/5.x/tutorials/quickstart).

## Prerequisites

- [Node.js](https://nodejs.org/) 22 or higher.
- TypeScript 5 or higher if you use a TypeScript config or import generated types.

::steps{level="2"}

## Install Kubb

Add `kubb` as a development dependency. It includes the CLI, core runtime, default OpenAPI adapter, and TypeScript, TSX, and Markdown parsers.

::code-group

```shell [pnpm]
pnpm add -D kubb
```

```shell [npm]
npm install -D kubb
```

```shell [yarn]
yarn add -D kubb
```

```shell [bun]
bun add -d kubb
```

::

## Verify the installation

Run the CLI from your project directory:

```shell [Terminal]
npx kubb --version
```

The command prints the installed Kubb version. Use `pnpm exec kubb --version`, `yarn kubb --version`, or `bunx kubb --version` with the corresponding package manager.

## Install plugins

Each output is provided by a plugin package. Install only the plugins you need. For TypeScript types, install the TypeScript plugin and compiler:

::code-group

```shell [pnpm]
pnpm add -D @kubb/plugin-ts typescript
```

```shell [npm]
npm install -D @kubb/plugin-ts typescript
```

```shell [yarn]
yarn add -D @kubb/plugin-ts typescript
```

```shell [bun]
bun add -d @kubb/plugin-ts typescript
```

::

Browse [available plugins](/plugins) to choose outputs for your project.

## Configure your project

Run the [initialization wizard](/docs/5.x/reference/commands/init) to choose your specification, output directory, and plugins:

```shell [Terminal]
npx kubb init
```

For an existing config, use [Configure generation](/docs/5.x/how-to/recipes). Install the runtime libraries required by your chosen output too: an Axios client uses `axios`, and React Query hooks use React and `@tanstack/react-query`. Each plugin documents its requirements.

Once configured, run `npx kubb generate` from the project directory. Kubb writes the generated files to `output.path`.

::

## Next steps

::card-group

:::card{title="Generate your first client" icon="i-iconoir-rocket" to="/docs/5.x/tutorials/quickstart"}
Follow a complete example with a supplied specification.
:::

:::card{title="Configure generation" icon="i-iconoir-settings" to="/docs/5.x/how-to/recipes"}
Choose a stack for your existing project.
:::

:::card{title="Configuration reference" icon="i-iconoir-bookmark" to="/docs/5.x/reference/configuration"}
Look up options and defaults.
:::

::
