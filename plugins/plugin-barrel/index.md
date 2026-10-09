---
layout: doc
title: Kubb Barrel Plugin
description: Generates an index.ts barrel for every plugin output and one root
  barrel, so you import all generated code from a single entry point. Ships with
  Kubb, but only generates barrels once output.barrel is configured.
outline: deep
kind: plugin
id: plugin-barrel
name: Barrel
category: output
type: official
npmPackage: "@kubb/plugin-barrel"
repo: https://github.com/kubb-labs/kubb
docsPath: /plugins/plugin-barrel
featured: true
icon:
  light: https://kubb.dev/feature/typescript.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - barrel
  - index
  - exports
  - output
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-barrel
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md
---

# @kubb/plugin-barrel

Generate `index.ts` exports for plugin outputs and the root entry point.

- Runs automatically with Kubb.
- Configure exports through [`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel).

## Installation

Ships with `kubb`, no extra install.

## Dependencies

- No plugin dependencies.
- `defineConfig` adds it to `plugins` for you. Do not add it yourself.

## Example

Set `output.barrel` on the root configuration to enable a root barrel and the default inherited by plugins without their own barrel setting.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginTs()],
})
```

See [options](/plugins/plugin-barrel/reference/options) for the export `type`, `nested` barrels, and per-plugin overrides.
