---
layout: doc
title: kubb init
description: The init command bootstraps a fresh Kubb project with an interactive wizard.
outline: [2, 3]
---

# `kubb init`

The interactive setup wizard. Answer a few questions and Kubb creates a `package.json` if one is missing, installs your chosen plugins, and writes a ready-to-use `kubb.config.ts`.

```terminal
command: npx kubb init
output:
  - ◆  Welcome to Kubb!
  - ◇  Where is your OpenAPI spec?
  - │  ./openapi.yaml
  - ◇  Where should generated files go?
  - │  ./src/gen
  - ◇  Which plugins do you want?
  - │  plugin-ts, plugin-client, plugin-zod
  - ◇  Package manager?
  - │  pnpm
  - ◇  Installing dependencies…
  - ◇  Created kubb.config.ts
  - ◇  All set — run `pnpm kubb generate` to start generating.
```

## Usage

Run the command in the directory where you want your Kubb project to live:

```shell
npx kubb init
```

The wizard prompts for:

- The path to your OpenAPI/Swagger spec (local file or URL).
- The output directory for generated files.
- Which [plugins](/plugins) to install (clients, hooks, validators, mocks, and more).
- Your preferred package manager (`bun`, `pnpm`, `npm`, or `yarn`).

When the wizard finishes, you have:

- A `kubb.config.ts` wired up with the plugins you selected.
- A `package.json` with `kubb` and the chosen plugins added as dev dependencies.
- All selected dependencies installed.

## Options

| Option           | Default | Description                                                                                                                                                                                                                                                         |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--yes`, `-y`    | `false` | Skip all prompts and use the default values.                                                                                                                                                                                                                        |
| `--input`, `-i`  | —       | Path to the OpenAPI specification (local file or URL). Bypasses the spec path prompt.                                                                                                                                                                               |
| `--output`, `-o` | —       | Output directory for generated files. Bypasses the output directory prompt.                                                                                                                                                                                         |
| `--plugins`      | —       | Comma-separated list of plugins to install. Bypasses the plugin selection prompt. Valid values: `plugin-ts`, `plugin-client`, `plugin-react-query`, `plugin-vue-query`, `plugin-zod`, `plugin-faker`, `plugin-msw`, `plugin-cypress`, `plugin-mcp`, `plugin-redoc`. |

Each flag bypasses only its specific prompt and composes freely with `--yes`. Providing all three non-boolean flags runs the wizard completely non-interactively without needing `--yes`.

## Examples

Initialize a project from scratch:

```shell
npx kubb init
```

Initialize non-interactively with the defaults:

```shell
npx kubb init --yes
```

Initialize with a specific spec and output directory:

```shell
npx kubb init --input ./openapi.yaml --output ./src/gen
```

Initialize fully non-interactively with specific plugins:

```shell
npx kubb init --input ./openapi.yaml --output ./src/gen --plugins plugin-ts,plugin-zod
```

Initialize with a plugin selection but still prompt for the spec path:

```shell
npx kubb init --plugins plugin-ts,plugin-client,plugin-react-query
```

> [!TIP]
> To wire things up by hand instead, see the [Installation](/docs/5.x/getting-started/installation) guide for a manual setup walkthrough.

## See also

- [Installation](/docs/5.x/getting-started/installation): manual setup guide
- [Configuration](/docs/5.x/reference/configuration): full `kubb.config.ts` reference
- [Plugins](/plugins): browse available plugins
