---
layout: doc
title: Kubb Zod Plugin
description: Generate Zod v4 schemas from OpenAPI for runtime validation that
  stays in sync with your TypeScript types.
outline: 2
kind: plugin
id: plugin-zod
---

# @kubb/plugin-zod

Generate [Zod](https://zod.dev/) v4 schemas from your OpenAPI spec. Use them to validate API responses at runtime, build form schemas, or feed back into router libraries that consume Zod (`tRPC`, `Hono`, `Elysia`).

Pair with `@kubb/plugin-client` and set the client's `parser: 'zod'` to validate every response automatically.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-zod@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-zod@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-zod@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-zod@beta
```

:::

## Options

### output

Where the generated Zod schemas are written and how they are exported.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Output`                                     |
| Required: | `false`                                      |
|  Default: | `{ path: 'zod', barrel: { type: 'named' } }` |

### importPath

Module specifier used in the `import { z } from '...'` statement at the top of generated files.

|           |                             |
| --------: | :-------------------------- |
|     Type: | `string`                    |
| Required: | `false`                     |
|  Default: | `mini ? 'zod/mini' : 'zod'` |

### typed

Adds a type annotation that ties each Zod schema to its TypeScript counterpart from `@kubb/plugin-ts`.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### coercion

Wraps schemas in `z.coerce` so input is coerced to the expected type before validation.

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` |
| Required: | `false`                                                                |
|  Default: | `false`                                                                |

### operations

Emits an `operations.ts` file that groups schemas per operation.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### paramsCasing

Renames properties inside the path/query/header schemas to the chosen casing.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### guidType

Validator used for OpenAPI properties with `format: uuid`.

|           |                    |
| --------: | :----------------- |
|     Type: | `'uuid' \| 'guid'` |
| Required: | `false`            |
|  Default: | `'uuid'`           |

### mini

Switches code generation to [Zod Mini](https://zod.dev/packages/mini).

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### include

Restricts generation to operations that match at least one entry in the list.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

### exclude

Skips any operation that matches at least one entry in the list.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

### override

Applies a different set of plugin options to operations that match a pattern.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

### generators

Adds custom generators that run alongside the plugin's built-in generators.

|           |                               |
| --------: | :---------------------------- |
|     Type: | `Array<Generator<PluginZod>>` |
| Required: | `false`                       |

### transformer

Modifies AST nodes before they are printed to source code.

|           |           |
| --------: | :-------- |
|     Type: | `Visitor` |
| Required: | `false`   |

### printer

Replaces the Zod handler for a specific schema type.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` |
| Required: | `false`                                              |

### wrapOutput

Lets you wrap the generated Zod schema string with extra calls before it is written to disk.

|           |                                                                        |
| --------: | :--------------------------------------------------------------------- |
|     Type: | `(arg: { output: string; schema: SchemaNode }) => string \| undefined` |
| Required: | `false`                                                                |

## Example

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod({
      output: { path: './zod' },
      group: { type: 'tag', name: ({ group }) => `${group}Schemas` },
      typed: true,
      importPath: 'zod',
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-zod/CHANGELOG.md)
