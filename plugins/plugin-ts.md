---
layout: doc
title: Kubb TypeScript Plugin
description: Generate TypeScript types and interfaces from OpenAPI schemas with
  full type safety end to end.
outline: 2
kind: plugin
id: plugin-ts
---

# @kubb/plugin-ts

`@kubb/plugin-ts` turns your OpenAPI schema into TypeScript `type` aliases and `interface` declarations. It is the foundation that every other Kubb plugin builds on — clients, query hooks, mocks, and validators all reference the names this plugin produces.

Add it once and every request payload, response, path parameter, and enum becomes a compile-time check.

**See also**

- [TypeScript](https://www.typescriptlang.org/)
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta
```

:::

## Options

### output

Where the generated `.ts` files are written and how they are exported.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Output`                                       |
| Required: | `false`                                        |
|  Default: | `{ path: 'types', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Use a folder to keep each generator's output isolated (`'types'`, `'clients'`, `'hooks'`). To put everything in one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'types'` |

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

|           |                                                                                       |
| --------: | :------------------------------------------------------------------------------------ |
|     Type: | `EnumOptions`                                                                         |
| Required: | `false`                                                                               |
|  Default: | `{ type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' }` |

#### enum.type

How OpenAPI enums are represented in the generated TypeScript.

- `'asConst'` (default) generates an `as const` object plus a key/value type. It is tree-shakeable and adds no enum runtime.
- `'enum'` generates a regular TypeScript `enum`, which produces JavaScript runtime code.
- `'constEnum'` generates a `const enum`. It inlines at compile time and is not compatible with `--isolatedModules`.
- `'literal'` generates a plain union type (`'dog' | 'cat'`) with no runtime value.
- `'inlineLiteral'` inlines the union at every usage site instead of giving it a name.

|           |                                                                      |
| --------: | :------------------------------------------------------------------- |
|     Type: | `'asConst' \| 'enum' \| 'constEnum' \| 'literal' \| 'inlineLiteral'` |
| Required: | `false`                                                              |
|  Default: | `'asConst'`                                                          |

### syntaxType

Whether object schemas are emitted as `type` aliases or `interface` declarations.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'type' \| 'interface'` |
| Required: | `false`                 |
|  Default: | `'type'`                |

::: code-group

```typescript ['type' (default)]
export type Pet = {
  name: string
}
```

```typescript ['interface']
export interface Pet {
  name: string
}
```

:::

### optionalType

How optional properties are written in generated types.

- `'questionToken'` (default) — `type?: string`. The property may be missing.
- `'undefined'` — `type: string | undefined`. The property is required to exist but may be `undefined`.
- `'questionTokenAndUndefined'` — `type?: string | undefined`. Strictest — the property may be missing or explicitly set to `undefined`.

|           |                                                                 |
| --------: | :-------------------------------------------------------------- |
|     Type: | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` |
| Required: | `false`                                                         |
|  Default: | `'questionToken'`                                               |

### arrayType

Syntax used for array types in generated code.

- `'array'` (default) — postfix `Type[]`. Slightly shorter.
- `'generic'` — `Array<Type>`. More readable for complex element types (`Array<{ id: number }>`).

|           |                        |
| --------: | :--------------------- |
|     Type: | `'array' \| 'generic'` |
| Required: | `false`                |
|  Default: | `'array'`              |

### paramsCasing

Renames properties inside `PathParams`, `QueryParams`, and `HeaderParams` types. Response and request body types are not touched.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### resolver

Overrides how the plugin builds names and paths for generated files and symbols.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Partial<ResolverTs> & ThisType<ResolverTs>` |
| Required: | `false`                                      |

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

|           |                              |
| --------: | :--------------------------- |
|     Type: | `Array<Generator<PluginTs>>` |
| Required: | `false`                      |

### transformer

Modifies AST nodes before they are printed to source code.

|           |           |
| --------: | :-------- |
|     Type: | `Visitor` |
| Required: | `false`   |

### printer

Replaces the TypeScript node handler for a specific schema type.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `{ nodes?: PrinterTsNodes }` |
| Required: | `false`                      |

## Example

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
      exclude: [{ type: 'tag', pattern: 'store' }],
      group: { type: 'tag' },
      enumType: 'asConst',
      optionalType: 'questionTokenAndUndefined',
      paramsCasing: 'camelcase',
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md)
