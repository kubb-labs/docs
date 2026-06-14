---
layout: doc
title: Creating your first plugin
description: Learn how to build a Kubb plugin from scratch. Step-by-step guide covering setup, lifecycle hooks, generators, and publishing.
outline: [2, 3]
---

# Creating your first plugin

A [plugin](/docs/5.x/concepts/plugins) teaches Kubb to generate something new. It owns its output folder, file naming, [generators](/docs/5.x/concepts/plugins#generators) that walk the [AST](/docs/5.x/concepts/ast), and lifecycle hooks that react to the build.

This guide walks you through building a complete `kubb-plugin-example` package from scratch and publishing it to npm.

> [!TIP]
> Before writing a plugin, check the [Plugins registry](/plugins) to see if an existing plugin already covers your use case.

## Prerequisites

This guide assumes you have:

- Node.js 22 or higher and pnpm (or npm/yarn)
- Working TypeScript knowledge
- A Kubb project with a valid [configuration](/docs/5.x/reference/configuration)
- Familiarity with the [plugin concepts](/docs/5.x/concepts/plugins) page

## Quick start

A plugin is a factory function created with `definePlugin` from [`@kubb/core`](/docs/5.x/api/core). It returns an object with a `name` string and a `hooks` map.

The `kubb:plugin:setup` hook is where you wire generators and resolvers into the build.

```typescript twoslash [my-plugin.ts]
import { ast, definePlugin, defineGenerator } from '@kubb/core'

export const pluginHello = definePlugin(() => ({
  name: 'plugin-hello',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(
        defineGenerator({
          name: 'hello-generator',
          operation(node, _ctx) {
            return [
              ast.factory.createFile({
                baseName: `${node.operationId}.ts`,
                path: `${_ctx.root}/${node.operationId}.ts`,
                sources: [
                  ast.factory.createSource({
                    nodes: [ast.factory.createText(`// ${node.method} ${node.path}\n`)],
                  }),
                ],
              }),
            ]
          },
        }),
      )
    },
  },
}))
```

Wire it into your `kubb.config.ts`:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb'
import { pluginHello } from './my-plugin.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginHello()],
})
```

Run the CLI to see it in action:

```bash
kubb generate
```

## Project layout

Every official Kubb plugin follows the same package layout. The reference implementation at [`@kubb/plugin-client`](https://github.com/kubb-labs/plugins/tree/main/packages/plugin-client) uses dedicated folders per concern: `generators/`, `resolvers/`, `components/`, and `templates/`.

Mirror this layout in your own plugin so contributors can navigate it without surprises:

```
kubb-plugin-example/
├── src/
│   ├── index.ts              # Public exports (factory, generators, resolvers, types)
│   ├── plugin.ts             # definePlugin factory + plugin<Name>Name constant
│   ├── types.ts              # PluginExample = PluginFactoryOptions<...>
│   ├── generators/           # One file per generator (e.g. operationsGenerator.ts)
│   │   └── exampleGenerator.ts
│   ├── resolvers/            # One file per resolver
│   │   └── resolverExample.ts
│   ├── components/           # Optional: JSX components when using @kubb/renderer-jsx
│   └── templates/            # Optional: source templates exposed at runtime
├── mocks/                    # OpenAPI fixtures consumed by tests
│   └── petStore.yaml
├── package.json
├── tsconfig.json
└── README.md
```

> [!TIP]
> Use [`@kubb/plugin-client`](https://github.com/kubb-labs/plugins/tree/main/packages/plugin-client) as the canonical example. Its `src/index.ts` re-exports each generator, resolver, and the plugin factory by name, and its `src/plugin.ts` declares a `pluginClientName satisfies PluginClient['name']` constant that other plugins consume.

Scaffold the directories:

```bash
mkdir kubb-plugin-example && cd kubb-plugin-example
npm init -y
npm install --save-peer @kubb/core @kubb/ast
npm install --save-dev typescript @types/node vitest
mkdir -p src/generators src/resolvers mocks
```

## Naming conventions

Choose the package name and internal identifiers to match Kubb conventions so the registry and other tooling can discover them.

| Surface                 | Pattern                                 | Example               |
| ----------------------- | --------------------------------------- | --------------------- |
| npm package (official)  | `@kubb/plugin-<name>`                   | `@kubb/plugin-ts`     |
| npm package (community) | `kubb-plugin-<name>`                    | `kubb-plugin-example` |
| Runtime plugin name     | `plugin-<name>` (kebab-case, lowercase) | `'plugin-example'`    |
| Factory export          | `plugin<Name>` (camelCase)              | `pluginExample`       |
| Name constant           | `plugin<Name>Name`                      | `pluginExampleName`   |

Use `satisfies` to export a typed name constant so other plugins can reference it without typos:

```typescript twoslash [pluginExampleName.ts]
import type { Plugin } from '@kubb/core'

export const pluginExampleName = 'plugin-example' satisfies Plugin['name']
```

> [!IMPORTANT]
> Use `kubb-plugin-<name>` for community packages. The `@kubb/plugin-*` namespace is reserved for official Kubb Labs packages.

## Plugin anatomy

The following four files form the skeleton of a plugin package. Each file is shown in the order it is typically read: types first, then the implementation files, then the public entry point.

```typescript twoslash
// @filename: src/types.ts
import type { PluginFactoryOptions } from '@kubb/core'

/** User-facing options for kubb-plugin-example. */
export interface PluginExampleOptions {
  /** Output filename for the generated operations index. Defaults to `'operations.ts'`. */
  filename?: string
  /** Whether to emit the operations index file. Defaults to `true`. */
  generateIndex?: boolean
}

/**
 * `PluginFactoryOptions` binds the plugin name, the user-facing option type,
 * and the resolved option type together so generators, resolvers, and the
 * build loop share a consistent interface.
 */
export type PluginExample = PluginFactoryOptions<'plugin-example', PluginExampleOptions, Required<PluginExampleOptions>>

// @filename: src/generators/exampleGenerator.ts
import { ast, defineGenerator } from '@kubb/core'
import type { PluginExample } from '../types'

/**
 * Creates a generator that emits one file per operation and, optionally,
 * an index file listing every operation ID.
 *
 * `defineGenerator` returns a `TElement | Array<FileNode> | void` union so
 * handlers may return a single element, an array, or nothing.
 */
export function createExampleGenerator(filename: `${string}.${string}`, generateIndex: boolean) {
  const collected: string[] = []

  return defineGenerator<PluginExample>({
    name: 'example-generator',
    operation(node, ctx) {
      // OperationNode.operationId is a required string, so no nullability guard is needed.
      collected.push(node.operationId)

      return [
        ast.factory.createFile({
          baseName: `${node.operationId}.ts`,
          path: `${ctx.root}/${node.operationId}.ts`,
          sources: [
            ast.factory.createSource({
              nodes: [ast.factory.createText(`// ${node.method} ${node.path}\n`), ast.factory.createText(`export const operationId = '${node.operationId}'\n`)],
            }),
          ],
        }),
      ]
    },
    async operations(_nodes, ctx) {
      if (!generateIndex) return

      return [
        ast.factory.createFile({
          baseName: filename,
          path: `${ctx.root}/${filename}`,
          sources: [
            ast.factory.createSource({
              nodes: [ast.factory.createText(`export const operations = ${JSON.stringify(collected)}\n`)],
            }),
          ],
        }),
      ]
    },
  })
}

// @filename: src/resolvers/resolverExample.ts
import { defineResolver } from '@kubb/core'
import type { PluginExample } from '../types'

/**
 * `defineResolver` automatically injects defaults for `default`, `resolveOptions`,
 * `resolvePath`, `resolveFile`, `resolveBanner`, and `resolveFooter`.
 * Only `name` and `pluginName` are required in the builder object.
 * Override any of the injected methods when you need custom naming or path logic.
 */
export const resolverExample = defineResolver<PluginExample>(() => ({
  name: 'default',
  pluginName: 'plugin-example',
}))

// @filename: src/plugin.ts
import { definePlugin } from '@kubb/core'
import type { Plugin } from '@kubb/core'
import type { PluginExample } from './types'
import { createExampleGenerator } from './generators/exampleGenerator'
import { resolverExample } from './resolvers/resolverExample'

export const pluginExampleName = 'plugin-example' satisfies Plugin['name']

export const pluginExample = definePlugin<PluginExample>((options) => {
  const filename = (options?.filename ?? 'operations.ts') as `${string}.${string}`
  const generateIndex = options?.generateIndex ?? true

  return {
    name: pluginExampleName,
    hooks: {
      'kubb:plugin:setup'(ctx) {
        ctx.setResolver(resolverExample)
        ctx.addGenerator(createExampleGenerator(filename, generateIndex))
        ctx.setOptions({ filename, generateIndex })
      },
    },
  }
})

// @filename: src/index.ts
export { createExampleGenerator } from './generators/exampleGenerator'
export { resolverExample } from './resolvers/resolverExample'
export { pluginExample, pluginExampleName } from './plugin'
export type { PluginExampleOptions, PluginExample } from './types'
```

## Generators

A generator walks the [AST](/docs/5.x/concepts/ast) produced by the [adapter](/docs/5.x/concepts/adapters) and emits `FileNode`s. Register generators in the `kubb:plugin:setup` hook using `ctx.addGenerator`. Each generator may implement any combination of three handlers:

| Handler      | Called for                                              | Return type                           |
| ------------ | ------------------------------------------------------- | ------------------------------------- |
| `schema`     | Each `SchemaNode` in the AST                            | `Array<FileNode>`, element, or `void` |
| `operation`  | Each `OperationNode` in the AST                         | `Array<FileNode>`, element, or `void` |
| `operations` | Once with all `OperationNode`s after the operation walk | `Array<FileNode>`, element, or `void` |

### Emit roles

A generator returns `Array<FileNode>` built with the `create*` factories from `@kubb/ast`. That is the default, and most plugins need nothing else. Three named roles cover the cases beyond it.

A printer renders one `SchemaNode` to a string, such as a TypeScript type or `z.object({ ... })`. A handler calls it and stages the result on a `FileNode`.

A renderer turns JSX into `FileNode`s. Return an element instead of `Array<FileNode>` and set `renderer: jsxRenderer`, and `@kubb/renderer-jsx` walks the JSX into the same nodes the builder would. It is sugar over the builder rather than a separate pipeline.

A parser, the serializer role, runs last and belongs to the build driver. After every plugin finishes, the matching [parser](/docs/5.x/concepts/parsers) writes each `FileNode` out as the final file string. Plugins never call it.

### src/generators/exampleGenerator.ts

The `ctx` argument inside a handler is a `GeneratorContext` with helpers such as `addFile`, `upsertFile`, `getResolver`, `requirePlugin`, `warn`, `error`, `info`, and the resolved `config`, `root`, `adapter`, and document `meta` (an `InputMeta` with `title`, `version`, `baseURL`, `circularNames`, and `enumNames`).

```typescript twoslash [exampleGenerator.ts]
import { ast, defineGenerator } from '@kubb/core'

const operationGenerator = defineGenerator({
  name: 'operation-files',
  operation(node, ctx) {
    // node.operationId is a required string on OperationNode.
    return [
      ast.factory.createFile({
        baseName: `${node.operationId}.ts`,
        path: `${ctx.root}/${node.operationId}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`// Generated from ${node.method} ${node.path}\n`), ast.factory.createText(`export const operationId = '${node.operationId}'\n`)],
          }),
        ],
      }),
    ]
  },
  schema(node, ctx) {
    // Runs for each SchemaNode. Return void to skip emitting a file.
    ctx.info(`Visiting schema: ${node.name}`)
    return []
  },
})
```

## Resolvers

A [resolver](/docs/5.x/api/core#resolver) controls how file names and output paths are computed for a plugin's files. Other plugins call `ctx.getResolver('plugin-example')` to reference those names without hard-coding paths.

### src/resolvers/resolverExample.ts

`defineResolver` injects sensible defaults for every resolver method. Provide only `name` and `pluginName` in the builder and override specific methods when you need custom behavior. Returning `null` from `resolveOptions` excludes the node from generation, so only return `null` when you explicitly want to filter a node out.

```typescript twoslash [resolvers.ts]
import { defineResolver } from '@kubb/core'
import path from 'node:path'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

type PluginExample = PluginFactoryOptions<'plugin-example', object, object, Resolver>

export const resolverExample = defineResolver<PluginExample>(() => ({
  name: 'default',
  pluginName: 'plugin-example',
  // Override resolvePath to place files in a custom sub-folder.
  resolvePath({ baseName }, { root, output }) {
    return path.resolve(root, output.path, 'example', baseName)
  },
}))
```

## The setup context

`kubb:plugin:setup` receives a `KubbPluginSetupContext` that wires the plugin into the build. The full interface from [`@kubb/core`](/docs/5.x/api/core):

| Method / Property | Purpose                                                                           |
| ----------------- | --------------------------------------------------------------------------------- |
| `addGenerator`    | Register a [`Generator`](/docs/5.x/concepts/plugins#generators) for the AST walk. |
| `setResolver`     | Set or override the resolver (file naming and paths).                             |
| `setTransformer`  | Pre-process AST nodes with a [`Visitor`](/docs/5.x/concepts/ast#visitors).        |
| `setRenderer`     | Set the renderer factory for JSX-style generator returns.                         |
| `setOptions`      | Provide resolved options to the build loop.                                       |
| `injectFile`      | Inject a raw `UserFileNode` into the build, bypassing generators.                 |
| `updateConfig`    | Merge a partial config update into the running build.                             |
| `config`          | The resolved `Config` at setup time.                                              |
| `options`         | The user-supplied plugin options.                                                 |

```typescript twoslash [setup-context.ts]
import { ast, definePlugin, defineGenerator } from '@kubb/core'

export const pluginExample = definePlugin(() => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      // ctx.config gives access to the full Kubb configuration.
      const outputPath = ctx.config.output.path

      // Register a generator that emits one file per operation.
      ctx.addGenerator(
        defineGenerator({
          name: 'example-generator',
          operation(node, genCtx) {
            return [
              ast.factory.createFile({
                baseName: `${node.operationId}.ts`,
                path: `${genCtx.root}/${node.operationId}.ts`,
                sources: [ast.factory.createSource({ nodes: [ast.factory.createText(`// output: ${outputPath}\n`)] })],
              }),
            ]
          },
        }),
      )

      // Inject a static file directly, bypassing generators entirely.
      ctx.injectFile({
        baseName: 'README.md',
        path: `${outputPath}/README.md`,
        sources: [{ kind: 'Source', nodes: [{ kind: 'Text', value: '# Generated\n' }] }],
      })
    },
  },
}))
```

## Options

Use `PluginFactoryOptions` to bind the plugin name, user-facing options, and resolved options together. This type flows through `definePlugin`, `defineGenerator`, and the resolver, keeping all three in sync.

```typescript twoslash [options.ts]
import { definePlugin } from '@kubb/core'
import type { PluginFactoryOptions } from '@kubb/core'

interface PluginExampleOptions {
  /** Output filename for the index. Defaults to `'operations.ts'`. */
  filename?: string
  /** Whether to emit the index file. Defaults to `true`. */
  generateIndex?: boolean
}

type PluginExample = PluginFactoryOptions<'plugin-example', PluginExampleOptions, Required<PluginExampleOptions>>

export const pluginExample = definePlugin<PluginExample>((options) => {
  // Apply defaults in the factory closure so each build invocation
  // gets its own resolved copy.
  const filename = options?.filename ?? 'operations.ts'
  const generateIndex = options?.generateIndex ?? true

  return {
    name: 'plugin-example',
    hooks: {
      'kubb:plugin:setup'(ctx) {
        // Store the resolved options so generators can read them from ctx.plugin.options.
        ctx.setOptions({ filename, generateIndex })
      },
    },
  }
})
```

## Testing

Use `createKubb` from `@kubb/core` to create an in-process build and verify that your generator emits the expected files. Pair it with a small [OpenAPI](https://spec.openapis.org/oas/latest.html) fixture to keep tests fast and deterministic.

```typescript twoslash [plugin.test.ts]
// @errors: 2307
import { describe, it, expect } from 'vitest'
import { ast, createKubb, definePlugin, defineGenerator } from '@kubb/core'

const pluginExample = definePlugin(() => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(
        defineGenerator({
          name: 'example-generator',
          operation(node, genCtx) {
            return [
              ast.factory.createFile({
                baseName: `${node.operationId}.ts`,
                path: `${genCtx.root}/${node.operationId}.ts`,
                sources: [ast.factory.createSource({ nodes: [ast.factory.createText(`// ${node.operationId}\n`)] })],
              }),
            ]
          },
        }),
      )
    },
  },
}))

describe('pluginExample', () => {
  it('emits one file per operation', async () => {
    const kubb = createKubb({
      input: { path: './test/fixtures/petStore.yaml' },
      output: { path: './dist/test' },
      plugins: [pluginExample()],
    })

    const { files } = await kubb.build()
    expect(files.length).toBeGreaterThan(0)
  })
})
```

### Observing lifecycle events

Subscribe to `kubb.hooks` before calling `build()` to trace plugin activity or collect metrics. Each hook receives a single typed context object.

```typescript twoslash [lifecycle.ts]
import { createKubb, definePlugin } from '@kubb/core'

const kubb = createKubb({
  input: { path: './petStore.yaml' },
  output: { path: './gen' },
  plugins: [definePlugin(() => ({ name: 'plugin-example', hooks: {} }))()],
})

// kubb:plugin:end receives a single KubbPluginEndContext, not two separate arguments.
kubb.hooks.on('kubb:plugin:end', ({ plugin, duration, success }) => {
  console.log(`[${plugin.name}] finished in ${duration}ms (ok=${success})`)
})

// kubb:files:processing:update fires once per flush batch with an array of per-file updates.
kubb.hooks.on('kubb:files:processing:update', ({ files }) => {
  for (const { file, processed, total, percentage } of files) {
    console.log(`[${processed}/${total}] (${percentage.toFixed(0)}%) ${file.path}`)
  }
})

await kubb.build()
```

## Publishing your plugin

### Configure package.json

Set up `package.json` for dual-format publishing. Peer-depend on `@kubb/core` and `@kubb/ast` at v5 to keep the runtime out of your bundle, and mark them as `devDependencies` for local builds.

```json
{
  "name": "kubb-plugin-example",
  "version": "1.0.0",
  "description": "A Kubb plugin that generates example files from OpenAPI specs.",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "scripts": {
    "build": "tsc",
    "test": "vitest",
    "prepublishOnly": "npm run build && npm test"
  },
  "peerDependencies": {
    "@kubb/core": "^5.0.0",
    "@kubb/ast": "^5.0.0"
  },
  "devDependencies": {
    "@kubb/ast": "^5.0.0",
    "@kubb/core": "^5.0.0",
    "@types/node": "^22.0.0",
    "typescript": "^5.0.0",
    "vitest": "^3.0.0"
  },
  "keywords": ["kubb", "plugin", "openapi", "codegen"],
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/yourname/kubb-plugin-example"
  }
}
```

### Publish to npm

Before publishing, verify the checklist:

- Exported TypeScript types compile without errors
- JSDoc comments on public APIs
- README with installation and usage examples
- All tests pass
- Version follows [Semantic Versioning](https://semver.org/)

See the [npm publishing docs](https://docs.npmjs.com/cli/v11/commands/npm-publish) for the full publish workflow:

```bash
npm login
npm publish --access public
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "declaration": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "skipLibCheck": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist", "test"]
}
```

## Examples

The [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins) repository contains official community plugins that follow all conventions described in this guide. Browse the source to see how generators, resolvers, and options are wired together in production packages.

### Schema generator

Generate code for each schema definition in the spec:

```typescript twoslash [schema-generator.ts]
import { ast, defineGenerator } from '@kubb/core'

export const schemaGenerator = defineGenerator({
  name: 'schema-generator',
  schema(node, ctx) {
    return [
      ast.factory.createFile({
        baseName: `${node.name}.ts`,
        path: `${ctx.root}/${node.name}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`// Schema: ${node.name}\nexport type ${node.name} = unknown\n`)],
          }),
        ],
      }),
    ]
  },
})
```

### Extending an existing plugin

Declare `dependencies` when your plugin must run after another plugin so Kubb verifies the dependency at startup:

```typescript twoslash [plugin-with-dep.ts]
import { ast, definePlugin, defineGenerator } from '@kubb/core'

export const pluginCustom = definePlugin(() => ({
  name: 'plugin-custom',
  // plugin-ts must be registered before plugin-custom starts.
  dependencies: ['plugin-ts'],
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(
        defineGenerator({
          name: 'custom-generator',
          operation(node, genCtx) {
            // Use the plugin-ts resolver for consistent naming.
            const resolver = genCtx.getResolver('plugin-ts')
            const name = resolver.default(node.operationId, 'function')
            return [
              ast.factory.createFile({
                baseName: `${name}.custom.ts`,
                path: `${genCtx.root}/${name}.custom.ts`,
                sources: [ast.factory.createSource({ nodes: [ast.factory.createText(`// extends ${name}\n`)] })],
              }),
            ]
          },
        }),
      )
    },
  },
}))
```
