---
layout: doc
title: Customize generated types
description: Prefix TypeScript names, change schema type output, and remove descriptions.
outline: deep
---

# Customize generated types

Start with the [TypeScript plugin configuration](/plugins/plugin-ts/#example). Apply these changes to `pluginTs()` in that configuration.

## Prefix type names

Use `resolverTs.name` to preserve the plugin's PascalCase rule before adding a prefix.

```typescript [kubb.config.ts]
import { pluginTs, resolverTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    name(name) {
      return 'Api' + resolverTs.name(name)
    },
  },
})
```

A generated `Pet` becomes `ApiPet`. File names stay unchanged unless you also customize the file resolver.

## Map schema types

Replace [printer handlers](/plugins/plugin-ts/reference/options#printer) with TypeScript AST nodes.

```typescript [kubb.config.ts]
import ts from 'typescript'
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  printer: {
    nodes: {
      date() {
        return ts.factory.createTypeReferenceNode('Date', [])
      },
      integer() {
        return ts.factory.createKeywordTypeNode(ts.SyntaxKind.BigIntKeyword)
      },
    },
  },
})
```

This maps `date` fields to `Date` and `int32` integers to `bigint`. The separate `bigint` handler controls `int64` fields, which already use `bigint` by default. A `date-time` field uses the `datetime` handler.

## Remove descriptions

Clear schema descriptions with a [macro](/docs/5.x/reference/plugin-options#macros).

```typescript [kubb.config.ts]
import { pluginTs } from '@kubb/plugin-ts'
import { ast } from 'kubb/kit'

const dropDescriptions = ast.defineMacro({
  name: 'drop-descriptions',
  schema(node) {
    return 'description' in node && node.description
      ? { ...node, description: undefined }
      : undefined
  },
})

pluginTs({ macros: [dropDescriptions] })
```

The generated types omit description JSDoc. The OpenAPI document stays unchanged. The same macro works with `pluginZod`.
