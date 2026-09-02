---
layout: doc
title: kubb init
description: The init command bootstraps a fresh Kubb project with an interactive wizard.
outline: [2, 3]
---

# `kubb init`

Run `kubb init` for an interactive setup wizard. Answer a few questions and Kubb creates a `package.json` if one is missing, installs your chosen plugins, and writes a ready-to-use `kubb.config.ts`.

```terminal
command: npx kubb init
output:
  - ◆  Kubb Init
  - ◇  Detected package manager: pnpm
  - ◇  Where is your OpenAPI specification located?
  - │  ./openapi.yaml
  - ◇  Where should the generated files be output?
  - │  ./src/gen
  - ◇  Select plugins to use:
  - │  plugin-ts, plugin-axios, plugin-zod
  - ◇  Installed 4 packages
  - ◇  Created kubb.config.ts
  - ◇  All set! Run `npx kubb generate` to start generating.
```

## Usage

Run the command in the directory where your Kubb project lives:

```shell [Terminal]
npx kubb init
```

The wizard prompts for three things:

- The path to your OpenAPI/Swagger spec, a local file or a URL.
- The output directory for generated files.
- Which [plugins](/plugins) to install, such as clients, hooks, validators, and mocks.

Kubb detects the package manager (`bun`, `pnpm`, `npm`, or `yarn`) from your project, so it does not prompt for one.

When the wizard finishes, you have:

- A `kubb.config.ts` wired up with the plugins you selected.
- A `package.json` with `kubb` and the chosen plugins added as dependencies.
- All selected dependencies installed.

The wizard installs `kubb` at the exact version of the CLI you ran and takes the plugins from that same release channel, so `npx kubb@beta init` scaffolds a beta project and a stable CLI scaffolds a stable one.

## Options

| Option           | Default | Description                                                                                                                                                                                                                                                         |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--yes`, `-y`    | `false` | Skip all prompts and use the default values.                                                                                                                                                                                                                        |
| `--input`, `-i`  |         | Path to the OpenAPI specification (local file or URL). Bypasses the spec path prompt.                                                                                                                                                                               |
| `--output`, `-o` |         | Output directory for generated files. Bypasses the output directory prompt.                                                                                                                                                                                         |
| `--plugins`      |         | Comma-separated list of plugins to install. Bypasses the plugin selection prompt. Valid values: `plugin-ts`, `plugin-axios`, `plugin-fetch`, `plugin-react-query`, `plugin-vue-query`, `plugin-zod`, `plugin-faker`, `plugin-msw`, `plugin-cypress`, `plugin-mcp`, `plugin-redoc`. |
| `--dryRun`      | `false` | Preview the wizard without installing packages or writing `kubb.config.ts`.                                                                                                                                                                                        |

Each flag skips only its own prompt and combines with `--yes`. Pass all three value flags and the wizard runs without prompts, no `--yes` needed.

## Examples

Run with the defaults and no prompts:

```shell [Terminal]
npx kubb init --yes
```

Run with no prompts and a specific spec, output directory, and plugins:

```shell [Terminal]
npx kubb init --input ./openapi.yaml --output ./src/gen --plugins plugin-ts,plugin-zod
```

Pass a plugin selection but still prompt for the spec path:

```shell [Terminal]
npx kubb init --plugins plugin-ts,plugin-axios,plugin-react-query
```

Preview what the wizard would install and write, without changing anything:

```shell [Terminal]
npx kubb init --yes --dryRun
```

> [!TIP]
> Prefer to wire things up by hand? See the [Installation](/docs/5.x/getting-started/installation) guide for a manual walkthrough.

## See also

- [Installation](/docs/5.x/getting-started/installation): manual setup guide
- [Configuration](/docs/5.x/reference/configuration): full `kubb.config.ts` reference
- [Plugins](/plugins): browse available plugins
