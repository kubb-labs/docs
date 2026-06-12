---
layout: doc
title: Kubb Redoc Plugin
description: Render your OpenAPI spec as a single-file HTML page using Redoc,
  regenerated as part of the Kubb build.
outline: 2
kind: plugin
id: plugin-redoc
---

# @kubb/plugin-redoc

Generate a static HTML documentation page for your OpenAPI spec using [Redoc](https://redocly.com/). The page is self-contained — drop it on any static host or open it locally.

Because the file is regenerated on every Kubb build, your docs stay in lockstep with the spec your code was generated from.

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

Output location of the generated HTML file.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ path: string }`      |
| Required: | `false`                 |
|  Default: | `{ path: 'docs.html' }` |

#### output.path

File path of the generated HTML, relative to the global `output.path`.

Use a `.html` extension. Unlike most plugins, this option points at a single file rather than a directory.

|           |               |
| --------: | :------------ |
|     Type: | `string`      |
| Required: | `true`        |
|  Default: | `'docs.html'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. See `output.mode` for the single-file and one-file-per-group layouts.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── types/
        ├── Pet.ts
        └── Store.ts
```

:::

## Example

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

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md)
