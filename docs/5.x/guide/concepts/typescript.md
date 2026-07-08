---
layout: doc
title: TypeScript - End-to-End Type Safety in Kubb
description: Kubb is built in TypeScript and gives you fully typed plugins, adapters, parsers, and AST visitors. Learn how to enable strict mode, infer plugin and adapter options, and narrow AST nodes with type guards.
outline: deep
---

# TypeScript

Kubb is built in TypeScript end to end, and that choice shapes how you work with it. The point is not that the source happens to be typed. It is that types travel with you: from the config you write, through the plugins and adapters that run, down to the AST nodes a generator visits. When the compiler already knows the shape of everything in the pipeline, IntelliSense can lead you through each choice and most mistakes surface before generation ever runs.

Every public surface takes a generic that pins down the same four things: the user-facing options, the resolved options after defaults, the plugin name, and the resolver shape. That generic threads through [`defineConfig`](https://github.com/kubb-labs/kubb/blob/main/packages/kubb/src/defineConfig.ts), [`definePlugin`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts#L79), [`defineParser`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineParser.ts), [`createAdapter`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/createAdapter.ts), [`defineGenerator`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineGenerator.ts), and the AST factories. Declare it once and the rest of the surface follows from it.

## Inference starts at the config

You rarely write a type annotation. The [`kubb.config.ts`](/docs/5.x/reference/configuration) entry point is where inference begins, and everything downstream reads from it. Pass a plugin to `defineConfig` and its options are checked against that plugin's own `Options` type, so a typo in `pluginTs` is a compiler error, not a silent no-op at runtime.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      output: { path: 'models' },
      // Hover any option to see the inferred type.
    }),
  ],
})
```

Hovering an option shows the type the compiler resolved for it. That feedback loop is the whole idea: the config is the source of truth, and the editor reflects back what Kubb will actually do with it.

## Why strict mode matters

Kubb assumes [TypeScript strict mode](https://www.typescriptlang.org/tsconfig#strict), and a few of its APIs only behave the way you expect with it on. All exported types compile cleanly under `"strict": true`. The AST node guards and resolvers in particular rely on `strictNullChecks`, because that is what lets the compiler treat a possibly-absent value as possibly-absent and narrow it once you check.

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
> If you cannot enable full `strict`, enable at least `strictNullChecks`. Without it, [`RefSchemaNode.ref`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/schema.ts#L378) and resolver helpers return widened types and you cast manually.

## How a plugin's types thread through the pipeline

A plugin is described by a single generic, [`PluginFactoryOptions`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts#L201). It is the contract between the options a user passes and the values a plugin works with at runtime, and it carries four pieces of information through the plugin lifecycle:

| Generic            | Purpose                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `TName`            | The plugin's name literal (e.g. `'plugin-ts'`). Used by `dependencies` lookups.                                                                  |
| `TOptions`         | The user-facing options accepted by the factory.                                                                                                 |
| `TResolvedOptions` | The shape of `options` after defaults are applied (what runs at runtime).                                                                  |
| `TResolver`        | The plugin's [`Resolver`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts) extension (`pluginName`, naming helpers). |

The split between `TOptions` and `TResolvedOptions` is the part worth understanding. `TOptions` is what a user is allowed to leave out, and `TResolvedOptions` is what the plugin sees once defaults are filled in. Declare the alias once and both halves stay in sync across the factory and its hooks.

```typescript twoslash [plugin-example.ts]
import { definePlugin } from 'kubb/kit'
import type { PluginFactoryOptions, Resolver } from 'kubb/kit'

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
> Inside hooks, `ctx.options` is typed as `TResolvedOptions` and `ctx.config` is the fully resolved [`Config`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts). No casts required.

## Adapters extend the same idea

Adapters follow the same pattern with [`AdapterFactoryOptions`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts), with one extra slot. Alongside `TName`, `TOptions`, and `TResolvedOptions`, an adapter also pins `TDocument`, the shape of the parsed spec it produces. That is the type every downstream plugin reads from, so getting it right here is what keeps the rest of the pipeline honest.

```typescript twoslash [adapter-example.ts]
import { ast, createAdapter } from 'kubb/kit'
import type { AdapterFactoryOptions } from 'kubb/kit'

type Options = { strict?: boolean }
type ResolvedOptions = Required<Options>
type Document = { paths: Record<string, unknown> }
type AdapterExample = AdapterFactoryOptions<'adapter-example', Options, ResolvedOptions, Document>

export const adapterExample = createAdapter<AdapterExample>((options) => ({
  name: 'adapter-example',
  options: { strict: options.strict ?? false },
  document: null,
  async parse() {
    return ast.factory.createInput()
  },
  getImports() {
    return []
  },
  async validate() {
    // Throw or call ctx.error here when the spec is invalid.
  },
}))
```

The same alias flows into [`Adapter<AdapterExample>`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts), so consumers that import the adapter type get the options and document for free, without redeclaring anything.

## Parsers carry their own metadata

Parsers see the files a plugin produced, and each [`FileNode<TMeta>`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/file.ts) keeps the metadata its plugin attached. The `TMeta` generic is how that survives the trip: type the `parse` parameter and `file.meta` comes back as your own shape rather than `unknown`.

```typescript twoslash [parser-typed.ts]
import { ast, defineParser } from 'kubb/kit'

type Meta = { language: 'ts' | 'tsx' }

export const parserTyped = defineParser({
  name: 'parser-typed',
  extNames: ['.ts'],
  parse(file: ast.FileNode<Meta>) {
    const meta = file.meta // typed as Meta
    return `// ${meta?.language ?? 'unknown'}\n`
  },
  print() {
    return ''
  },
})
```

## How the AST narrows

The AST is a set of discriminated unions, which is what makes it safe to walk. The [`SchemaNode`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/schema.ts#L640) union shares one `kind: 'Schema'` discriminator and uses `node.type` to tell variants apart, so once you check a node's `type`, the compiler knows exactly which fields exist. Two helpers cover the cases the discriminants alone do not: `narrowSchema` narrows a `SchemaNode` to a specific variant, and `isHttpOperationNode` narrows an `OperationNode` to an `HttpOperationNode`.

```typescript twoslash [narrow.ts]
import { ast } from 'kubb/kit'

declare const node: ast.SchemaNode

const ref = ast.narrowSchema(node, 'ref')
if (ref?.ref) {
  const refName: string = ref.ref
  console.log(refName)
}

declare const op: ast.OperationNode
if (ast.isHttpOperationNode(op)) {
  // op is now HttpOperationNode. method and path are non-nullable
  const _method: ast.HttpMethod = op.method
}
```

These are the only two guards the [AST](/docs/5.x/reference/kit#guards-and-narrowing) exposes. Everything else narrows through the `kind` and `type` discriminants directly.

## See also

- [Plugins](/docs/5.x/guide/concepts/plugins): `definePlugin`, `PluginFactoryOptions`, resolvers, generators.
- [Adapters](/docs/5.x/guide/concepts/adapters): `createAdapter` and `AdapterFactoryOptions`.
- [AST](/docs/5.x/guide/concepts/ast): node types, visitors, guards.
- [Configuration](/docs/5.x/reference/configuration): top-level `defineConfig` shape.
