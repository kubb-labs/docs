---
layout: doc
title: TypeScript - End-to-End Type Safety in Kubb
description: Kubb is built in TypeScript and gives you fully typed plugins, adapters, parsers, and AST visitors. Learn how to enable strict mode, infer plugin and adapter options, and narrow AST nodes with type guards.
outline: deep
---

# TypeScript

Kubb is built in TypeScript end-to-end. Every public surface accepts a generic that pins down options, resolved options, and the resolver shape. This includes [`defineConfig`](https://github.com/kubb-labs/kubb/blob/main/packages/kubb/src/defineConfig.ts), [`definePlugin`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts#L79), [`defineMiddleware`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineMiddleware.ts), [`defineParser`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineParser.ts), [`createAdapter`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/createAdapter.ts), [`defineGenerator`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineGenerator.ts), and the AST factories. The result is a config file where IntelliSense leads you through every choice and the compiler catches mistakes before generation runs.

## Quick start

Use the [`kubb.config.ts`](/docs/5.x/reference/configuration) entry point and the compiler will infer everything from there:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      output: { path: 'models' },
      // Hover any option to see the inferred type.
    }),
  ],
})
```

## Strict mode

Kubb assumes [TypeScript strict mode](https://www.typescriptlang.org/tsconfig#strict). All exported types are written to compile cleanly under `"strict": true`, and several APIs (notably the AST node guards and resolvers) only narrow correctly when `strictNullChecks` is on:

```json [tsconfig.json]
{
  "compilerOptions": {
    "strict": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ES2022"
  }
}
```

> [!IMPORTANT]
> If you cannot enable full `strict`, enable at least `strictNullChecks`. Without it, [`RefSchemaNode.ref`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/schema.ts#L378) and resolver helpers return widened types and you'll have to cast manually.

## Typing plugin options

Plugins use a single generic, [`PluginFactoryOptions`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts#L201), that carries four pieces of information through the entire plugin lifecycle:

| Generic            | Purpose                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `TName`            | The plugin's name literal (e.g. `'plugin-ts'`). Used by `dependencies` lookups.                                                                  |
| `TOptions`         | The user-facing options accepted by the factory.                                                                                                 |
| `TResolvedOptions` | The shape of `options` after defaults have been applied (what runs at runtime).                                                                  |
| `TResolver`        | The plugin's [`Resolver`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts) extension (`pluginName`, naming helpers). |

Declare a `PluginFactoryOptions` alias once and reuse it:

```typescript twoslash [plugin-example.ts]
import { definePlugin } from '@kubb/core'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

type Options = { suffix?: string }
type ResolvedOptions = Required<Options>
type PluginExample = PluginFactoryOptions<'plugin-example', Options, ResolvedOptions, Resolver>

export const pluginExample = definePlugin<PluginExample>((options) => {
  const resolvedOptions: ResolvedOptions = { suffix: options.suffix ?? '.ts' }

  return {
    name: 'plugin-example',
    options: resolvedOptions,
    hooks: {
      'kubb:plugin:end'({ files }) {
        // `files` is FileNode[]; no cast required.
        console.log(`${files.length} files emitted with suffix ${resolvedOptions.suffix}`)
      },
    },
  }
})
```

> [!TIP]
> Inside hooks, `ctx.options` is typed as `TResolvedOptions` and `ctx.config` is the fully-resolved [`Config`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts). No casts required.

## Typing adapter options

Adapters follow the same pattern with [`AdapterFactoryOptions`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts). Pin `TName`, `TOptions`, `TResolvedOptions`, and the parsed `TDocument` once:

```typescript twoslash [adapter-example.ts]
import { createAdapter } from '@kubb/core'
import { createInput } from '@kubb/ast'
import type { AdapterFactoryOptions } from '@kubb/core'

type Options = { strict?: boolean }
type ResolvedOptions = Required<Options>
type Document = { paths: Record<string, unknown> }
type AdapterExample = AdapterFactoryOptions<'adapter-example', Options, ResolvedOptions, Document>

export const adapterExample = createAdapter<AdapterExample>((options) => ({
  name: 'adapter-example',
  options: { strict: options.strict ?? false },
  document: null,
  async parse() {
    return createInput()
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

The same alias flows into [`Adapter<AdapterExample>`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts), so consumers that import the adapter type get full type information about its options and document.

## Typing parsers

Parsers receive a [`FileNode<TMeta>`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/file.ts) in `parse`, so typing the parameter keeps plugin-attached metadata typed:

```typescript twoslash [parser-typed.ts]
import { defineParser } from '@kubb/core'
import type { FileNode } from '@kubb/ast'

type Meta = { language: 'ts' | 'tsx' }

export const parserTyped = defineParser({
  name: 'parser-typed',
  extNames: ['.ts'],
  parse(file: FileNode<Meta>) {
    const meta = file.meta // typed as Meta
    return `// ${meta?.language ?? 'unknown'}\n`
  },
  print() {
    return ''
  },
})
```

## Narrowing AST nodes

The [`SchemaNode`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/schema.ts#L640) union shares one `kind: 'Schema'` discriminator and uses `node.type` to differentiate variants. Use the type guards from [`@kubb/ast`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/guards.ts) to narrow without casts:

```typescript twoslash [narrow.ts]
import { isSchemaNode, narrowSchema } from '@kubb/ast'
import type { SchemaNode } from '@kubb/ast'

declare const node: SchemaNode

const ref = narrowSchema(node, 'ref')
if (ref?.ref) {
  const refName: string = ref.ref
  console.log(refName)
}

const child: unknown = node
if (isSchemaNode(child)) {
  // child is now SchemaNode
  const _kind: 'Schema' = child.kind
}
```

Available guards on [`@kubb/ast`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/guards.ts): `isInputNode`, `isOutputNode`, `isOperationNode`, `isHttpOperationNode`, `isSchemaNode`. For schema variants use `narrowSchema(node, type)`; for HTTP operations use `isHttpOperationNode(node)` to narrow to an `HttpOperationNode` with non-nullable `method`/`path`.

## See also

- [Plugins](/docs/5.x/concepts/plugins): `definePlugin`, `PluginFactoryOptions`, resolvers, generators.
- [Adapters](/docs/5.x/concepts/adapters): `createAdapter` and `AdapterFactoryOptions`.
- [AST](/docs/5.x/concepts/ast): node types, visitors, guards.
- [Configuration](/docs/5.x/reference/configuration): top-level `defineConfig` shape.
