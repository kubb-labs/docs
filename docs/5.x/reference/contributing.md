---
layout: doc
title: Contributing
description: A concise guide to contributing to Kubb core and Kubb plugins.
outline: [2, 3]
---

# Contributing

There are two places to contribute:

1. [Kubb core](#kubb-core): the runtime, [AST](/docs/5.x/concepts/ast), [adapter](/docs/5.x/concepts/adapters), [parsers](/docs/5.x/concepts/parsers), and built-in plugins in [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb).
2. [Kubb plugins](#kubb-plugins): community and official plugins in the registry at [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins).

First, check the open [issues](https://github.com/kubb-labs/kubb/issues) and [pull requests](https://github.com/kubb-labs/kubb/pulls) so you don't duplicate work. Say hello on [Discord](https://discord.gg/4dQjA6vrWX).

## Prerequisites

- [Node.js](https://nodejs.org/en/download) 22 or later.
- [pnpm](https://pnpm.io/installation) 10 or later.
- [Git](https://git-scm.com/) and, optionally, the [GitHub CLI](https://cli.github.com/).

## Kubb core

The monorepo at [`kubb-labs/kubb`](https://github.com/kubb-labs/kubb) holds everything in the `kubb` and `@kubb/*` packages.

### 1. Fork and clone

```bash
gh repo fork kubb-labs/kubb --clone
cd kubb
```

### 2. Install dependencies

```bash
pnpm install
```

### 3. Create a branch

```bash
git checkout -b feat/your-feature-name
```

### 4. Iterate

Run a single package in watch mode:

```bash
pnpm -F @kubb/core dev
```

Run the test suite:

```bash
pnpm run test
```

### What lives where

| Path                          | What lives there                                                        |
| ----------------------------- | ----------------------------------------------------------------------- |
| `packages/core/`              | Plugin runtime, build loop, `definePlugin`/`createKubb` API.            |
| `packages/ast/`               | Universal AST and visitor utilities.                                    |
| `packages/adapter-oas/`       | OpenAPI adapter that produces the AST.                                  |
| `packages/parser-ts/`         | Parser that turns `FileNode` AST into TypeScript source.                |
| `packages/plugin-barrel/`     | Barrel file plugin (`enforce: 'post'`).                                 |
| `packages/middleware-barrel/` | Deprecated shim that re-exports `@kubb/plugin-barrel`.                  |
| `packages/renderer-jsx/`      | JSX renderer used by plugins that emit components.                      |
| `packages/cli/`               | The `kubb` CLI entry point.                                             |
| `packages/mcp/`               | MCP server runtime.                                                     |
| `packages/unplugin-kubb/`     | Bundler integrations (Vite, webpack, Rollup, Nuxt, Astro).              |
| `packages/kubb/`              | The meta package that re-exports `defineConfig` with sensible defaults. |

### Quality gates

Run these locally before pushing. CI runs the same commands.

```bash
pnpm run typecheck
pnpm run lint
pnpm run test
```

## Kubb plugins

Contribute a plugin in two ways. Build a community plugin in your own repository, or propose an official one in the core monorepo.

### Build a community plugin

1. Follow the [Creating Your First Plugin](/docs/5.x/guides/creating-plugins) guide.
2. Use [`@kubb/plugin-client`](https://github.com/kubb-labs/plugins/tree/main/packages/plugin-client) as the layout to copy.
3. Publish to npm under the `kubb-plugin-*` or `@scope/plugin-*` naming convention.
4. Submit it to the [community registry](https://github.com/kubb-labs/plugins). Add a YAML entry under `plugins/`.

### Propose an official plugin

Official plugins ship under `@kubb/plugin-*`. First, [open an issue](https://github.com/kubb-labs/plugins/issues/new/choose) on the [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins) repo to discuss scope and naming. Once approved, scaffold the package under `packages/plugin-<name>/`. Follow the structure of an existing plugin.

## Testing

Kubb uses [Vitest](https://vitest.dev/). Place each test file next to the source file it tests.

```ts
import { describe, expect, it } from 'vitest'
import { resolverExample } from './resolverExample.ts'

describe('resolverExample', () => {
  it('returns a default resolver name', () => {
    const resolver = resolverExample({})
    expect(resolver.name).toBe('default')
  })
})
```

Run tests for a single package:

```bash
pnpm -F @kubb/core test
```

## Commits and changesets

Follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`.

Add a [changeset](https://github.com/changesets/changesets) for any change that ships in a published package:

```bash
pnpm run changeset
```

Skip the changeset only when the change does not affect published code, such as CI, internal tests, or docs.

## Opening a pull request

1. Push your branch to your fork.
2. Open a pull request against `main`.
3. Fill in the PR template and link the related issue.
4. Make sure CI is green and re-request review after each round of changes.

## Getting help

Open an [issue](https://github.com/kubb-labs/kubb/issues) or join the [Discord](https://discord.gg/4dQjA6vrWX).
