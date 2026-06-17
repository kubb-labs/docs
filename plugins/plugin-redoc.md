---
layout: doc
title: Kubb Redoc Plugin
description: Render your OpenAPI spec as a single-file HTML page using Redoc,
  regenerated as part of the Kubb build.
outline: 2
kind: plugin
id: plugin-redoc
name: Redoc
category: documentation
type: official
npmPackage: "@kubb/plugin-redoc"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-redoc
featured: false
icon:
  light: https://kubb.dev/feature/openapi.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - redoc
  - api-docs
  - documentation
  - interactive-docs
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-redoc
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/simple-single
---

# @kubb/plugin-redoc

Generate a static HTML documentation page for your OpenAPI spec using [Redoc](https://redocly.com/). The page is self-contained, so you can drop it on any static host or open it locally.

Kubb regenerates the file on every build, so your docs stay in step with the spec your code was generated from.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-redoc@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-redoc@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-redoc@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-redoc@beta
```

:::

## Options

### output

Sets where the generated Redoc HTML file lands. The path resolves against the global `output.path` you set on `defineConfig`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ path: string }`      |
| Required: | `false`                 |
|  Default: | `{ path: 'docs.html' }` |

#### output.path

File path of the generated HTML, resolved relative to the global `output.path`. Unlike most plugins, this points at a single file rather than a directory.

End the path with a `.html` extension. If you leave the extension off, Kubb still writes the file and uses the path as the plugin output name.

|           |               |
| --------: | :------------ |
|     Type: | `string`      |
| Required: | `true`        |
|  Default: | `'docs.html'` |

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginRedoc } from '@kubb/plugin-redoc'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginRedoc({
      output: { path: 'docs.html' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── docs.html
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md)
