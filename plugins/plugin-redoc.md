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

`@kubb/plugin-redoc` turns your OpenAPI spec into a static HTML documentation page with [Redoc](https://redocly.com/). The page is self-contained. Drop it on any static host or open it locally.

Kubb rebuilds the file on every run. Your docs stay in step with the spec your code was generated from.

This plugin reads the OpenAPI adapter. Kubb uses `adapterOas()` by default, so it works out of the box. You set `adapter` yourself only if you replaced that default with another adapter.

**See also**

- [Redoc](https://redocly.com/redoc)
- [adapterOas](/adapters/adapter-oas)

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

Where the generated Redoc HTML file is written. The path is resolved against the global `output.path` on `defineConfig`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ path: string }`      |
| Required: | `false`                 |
|  Default: | `{ path: 'docs.html' }` |

#### output.path

File path of the generated HTML, resolved against the global `output.path`. Unlike most plugins, this points at a single file, not a directory.

End the path with a `.html` extension. If you leave the extension off, Kubb still writes the file and uses the path as the plugin output name.

|           |               |
| --------: | :------------ |
|     Type: | `string`      |
| Required: | `true`        |
|  Default: | `'docs.html'` |

With `output.path` set to `'docs.html'` and the global `output.path` set to `'./src/gen'`, the plugin writes one file:

```text [Resulting tree]
src/
└── gen/
    └── docs.html
```

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginRedoc } from '@kubb/plugin-redoc'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  plugins: [
    pluginRedoc({
      output: { path: 'docs.html' },
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md)
