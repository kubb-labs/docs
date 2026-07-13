---
layout: doc
title: Create your first plugin
description: Learn how to build a Kubb plugin from scratch. Step-by-step guide covering setup, lifecycle hooks, generators, and publishing.
outline: [2, 3]
---

# Create your first plugin

A [plugin](/docs/5.x/guide/concepts/plugins) teaches Kubb to generate something new. It owns its output folder and file naming, runs [generators](/docs/5.x/guide/concepts/generators) that walk the [AST](/docs/5.x/guide/concepts/ast), and hooks into the build lifecycle. Everything this guide uses comes from [`kubb/kit`](/docs/5.x/reference/kit) and its `kubb/kit/testing` subpath, so installing `kubb` is the only setup.

This guide builds a `kubb-plugin-example` package from scratch and publishes it to npm.

> [!TIP]
> Before writing a plugin, check the [Plugins registry](/plugins). An existing plugin may already cover your case.

## Prerequisites

You need:

- Node.js 22 or higher and pnpm (or npm/yarn)
- Working TypeScript knowledge
- A Kubb project with a valid [configuration](/docs/5.x/reference/configuration)
- A read of the [plugin concepts](/docs/5.x/guide/concepts/plugins) page

## Quick start

A plugin is a factory function built with `definePlugin` from [`kubb/kit`](/docs/5.x/reference/kit). It returns an object with a `name` string and a `hooks` map.

The `kubb:plugin:setup` hook is where you wire generators and resolvers into the build.

```typescript twoslash [my-plugin.ts]
import { ast, definePlugin, defineGenerator } from 'kubb/kit'

const helloGenerator = defineGenerator({
  name: 'hello-generator',
  operation(node, ctx) {
    return [
      ast.factory.createFile({
        baseName: `${node.operationId}.ts`,
        path: `${ctx.root}/${node.operationId}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`// ${node.method} ${node.path}\n`)],
          }),
        ],
      }),
    ]
  },
})

export const pluginHello = definePlugin(() => ({
  name: 'plugin-hello',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(helloGenerator)
    },
  },
}))
```

Wire it into `kubb.config.ts`:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { pluginHello } from './my-plugin.ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginHello()],
})
```

Run the CLI to see it work:

```shell [Terminal]
kubb generate
```

## Project layout

Every official Kubb plugin uses the same layout, one folder per concern: `generators/`, `resolvers/`, `components/`, and `templates/`. The reference implementation is [`@kubb/plugin-axios`](https://github.com/kubb-labs/plugins/tree/main/packages/plugin-axios). Mirror it so other contributors find their way around:

```text [Resulting tree]
kubb-plugin-example/
├── src/
│   ├── index.ts              # Public exports (factory, generators, resolvers, types)
│   ├── plugin.ts             # definePlugin factory + plugin<Name>Name constant
│   ├── types.ts              # PluginExample = PluginFactoryOptions<...>
│   ├── generators/           # One file per generator (e.g. operationsGenerator.ts)
│   │   └── exampleGenerator.ts
│   ├── resolvers/            # One file per resolver
│   │   └── resolverExample.ts
│   ├── components/           # Optional: JSX components when using kubb/jsx
│   └── templates/            # Optional: source templates exposed at runtime
├── mocks/                    # OpenAPI fixtures consumed by tests
│   └── petStore.yaml
├── package.json
├── tsconfig.json
└── README.md
```

> [!TIP]
> In [`@kubb/plugin-axios`](https://github.com/kubb-labs/plugins/tree/main/packages/plugin-axios), `src/index.ts` re-exports each generator, resolver, and the plugin factory by name. `src/plugin.ts` declares a `pluginAxiosName satisfies PluginAxios['name']` constant that other plugins consume.

Scaffold the directories:

```shell [Terminal]
mkdir kubb-plugin-example && cd kubb-plugin-example
npm init -y
npm install --save-peer kubb@beta
npm install --save-dev typescript @types/node vitest kubb@beta
mkdir -p src/generators src/resolvers mocks
```

## Naming conventions

Match the package name and internal identifiers to Kubb conventions so the registry and other tooling find them.

| Surface                 | Pattern                                 | Example               |
| ----------------------- | --------------------------------------- | --------------------- |
| npm package (official)  | `@kubb/plugin-<name>`                   | `@kubb/plugin-ts`     |
| npm package (community) | `kubb-plugin-<name>`                    | `kubb-plugin-example` |
| Runtime plugin name     | `plugin-<name>` (kebab-case, lowercase) | `'plugin-example'`    |
| Factory export          | `plugin<Name>` (camelCase)              | `pluginExample`       |
| Name constant           | `plugin<Name>Name`                      | `pluginExampleName`   |

Use `satisfies` to export a typed name constant. Other plugins then reference it without typos:

```typescript twoslash [pluginExampleName.ts]
import type { Plugin } from 'kubb/kit'

export const pluginExampleName = 'plugin-example' satisfies Plugin['name']
```

> [!IMPORTANT]
> Use `kubb-plugin-<name>` for community packages. The `@kubb/plugin-*` namespace is reserved for official Kubb Labs packages.

## Plugin anatomy

These files form the skeleton, in reading order: the option types, then the generator and resolver that do the work, then the plugin that wires them together and the barrel that exports them.

::: code-group

```typescript [src/types.ts]
import type { PluginFactoryOptions } from 'kubb/kit'

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
```

```typescript [src/generators/exampleGenerator.ts]
import { ast, defineGenerator } from 'kubb/kit'
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
```

```typescript [src/resolvers/resolverExample.ts]
import { createResolver } from 'kubb/kit'
import type { PluginExample } from '../types'

/**
 * `createResolver` fills in the built-in machinery under `resolver.default`
 * (`name`, `options`, `path`, `file`, `banner`, `footer`) and injects the
 * top-level `name`/`file` entries that delegate to it. Only `pluginName` is
 * required; override `name`/`file` when you need custom naming or file logic.
 */
export const resolverExample = createResolver<PluginExample>({
  pluginName: 'plugin-example',
})
```

```typescript [src/plugin.ts]
import { definePlugin } from 'kubb/kit'
import type { Plugin } from 'kubb/kit'
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
```

```typescript [src/index.ts]
export { createExampleGenerator } from './generators/exampleGenerator'
export { resolverExample } from './resolvers/resolverExample'
export { pluginExample, pluginExampleName } from './plugin'
export type { PluginExampleOptions, PluginExample } from './types'
```

:::

## Generators

A generator walks the [AST](/docs/5.x/guide/concepts/ast) produced by the [adapter](/docs/5.x/guide/concepts/adapters) and emits `FileNode`s. Register generators in `kubb:plugin:setup` with `ctx.addGenerator`. Each generator implements any combination of three handlers:

| Handler      | Called for                                              | Return type                                       |
| ------------ | ------------------------------------------------------- | ------------------------------------------------- |
| `schema`     | Each `SchemaNode` in the AST                            | `Array<FileNode>`, an element, or `null`/`undefined` |
| `operation`  | Each `OperationNode` in the AST                         | `Array<FileNode>`, an element, or `null`/`undefined` |
| `operations` | Once with all `OperationNode`s after the operation walk | `Array<FileNode>`, an element, or `null`/`undefined` |

Each handler can return a Promise of any of these.

### Emit roles

Most generators return `Array<FileNode>` built with the `create*` factories from `kubb/kit` (`ast.factory`). That is the default. Three named roles cover the cases beyond it.

A printer renders one `SchemaNode` to a string, such as a TypeScript type or a `z.object({ ... })`. A handler calls it and stages the result on a `FileNode`.

A renderer turns JSX into `FileNode`s. Return an element instead of `Array<FileNode>`, set `renderer: jsxRenderer` on the generator, and `kubb/jsx` walks the JSX into the same nodes the builder produces. It is sugar over the builder, not a second pipeline.

A parser handles serialization and runs last. It belongs to the build driver. Once every plugin finishes, the matching [parser](/docs/5.x/guide/concepts/parsers) writes each `FileNode` out as the final file string. Plugins never call it.

### src/generators/exampleGenerator.ts

Inside a handler, `ctx` is a `GeneratorContext`. It carries helpers such as `addFile`, `upsertFile`, `getResolver`, `requirePlugin`, `warn`, `error`, and `info`, plus the resolved `config`, `root`, `adapter`, and document `meta`. The `meta` is an `InputMeta` with `title`, `version`, `baseURL`, `circularNames`, and `enumNames`.

```typescript twoslash [exampleGenerator.ts]
import { ast, defineGenerator } from 'kubb/kit'

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

A [resolver](/docs/5.x/reference/kit/resolvers) decides the file names and output paths for a plugin's files. Other plugins call `ctx.getResolver('plugin-example')` to reuse those names without hard-coding paths.

### src/resolvers/resolverExample.ts

`createResolver` fills in the built-in machinery under `resolver.default` and injects the top-level `name`/`file` entries. Provide `pluginName`, then set `name` for identifier casing and `file` for file naming: `file.baseName` builds the base name (extension included) and `file.path` returns the full path. Returning `null` from `resolver.default.options` drops the node from generation, so return `null` only when you mean to filter a node out.

```typescript twoslash [resolvers.ts]
import { createResolver } from 'kubb/kit'
import type { PluginFactoryOptions, Resolver } from 'kubb/kit'

type PluginExample = PluginFactoryOptions<'plugin-example', object, object, Resolver>

export const resolverExample = createResolver<PluginExample>({
  pluginName: 'plugin-example',
  // Prefix every generated identifier with `Example`.
  name(name) {
    return `Example${this.default.name(name)}`
  },
  // Derive the file base name from the identifier, so a config override of `name` follows through.
  file: {
    baseName({ name, extname }) {
      return `${this.name(name)}${extname}`
    },
  },
})
```

Users override a plugin's resolver through its `resolver` option in `kubb.config.ts`. Pass a plain object with the parts you want to change, and each part merges over the plugin defaults. The option only patches the existing resolver. To build a whole new one, write a custom plugin. Inside every method `this` is the full resolver, so you reach `this.name`, `this.file`, and the plugin's namespaces.

```typescript twoslash [config-resolver.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  resolver: {
    name(name) {
      return `${this.default.name(name)}Faker`
    },
    file: {
      baseName({ name, extname }) {
        return `${this.name(name)}${extname}`
      },
    },
  },
})
```

Namespaces merge per method, so override a single one and the siblings keep the plugin default.

```typescript twoslash [config-namespace.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

function capitalize(text: string): string {
  return `${text.charAt(0).toUpperCase()}${text.slice(1)}`
}

pluginReactQuery({
  resolver: {
    query: {
      name(node) {
        return `use${capitalize(this.name(node.operationId))}Hook`
      },
    },
  },
})
```

## The setup context

`kubb:plugin:setup` receives a `KubbPluginSetupContext` that wires the plugin into the build. The full interface from [`kubb/kit`](/docs/5.x/reference/kit):

| Method / Property | Purpose                                                                           |
| ----------------- | --------------------------------------------------------------------------------- |
| `addGenerator`    | Register one or more [`Generator`](/docs/5.x/guide/concepts/generators)s for the AST walk. Pass them as separate arguments, or spread an existing list. |
| `setResolver`     | Set or override the resolver (file naming and paths).                             |
| `addMacro`        | Add a [macro](/docs/5.x/guide/going-further/macros) that rewrites AST nodes before generators. |
| `setMacros`       | Replace this plugin's macros with a new list.                                     |
| `setOptions`      | Provide resolved options to the build loop.                                       |
| `injectFile`      | Inject a raw `UserFileNode` into the build, bypassing generators.                 |
| `config`          | The resolved `Config` at setup time.                                              |
| `options`         | The user-supplied plugin options.                                                 |

```typescript twoslash [setup-context.ts]
import { fileURLToPath } from 'node:url'
import { ast, definePlugin, defineGenerator } from 'kubb/kit'

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

      // Copy a real file shipped in your package into the output, verbatim.
      ctx.injectFile({
        baseName: 'runtime.ts',
        path: `${outputPath}/runtime.ts`,
        copy: fileURLToPath(new URL('../templates/runtime.ts', import.meta.url)),
      })
    },
  },
}))
```

Set `copy` to an absolute on-disk path and Kubb writes that file's content into the output unchanged. It applies only `banner`/`footer` and skips the language parser. This keeps a hand-authored template as a real `.ts` file (linted, type-checked, and tested) and drops it into the generated folder without inlining its source as a string. The JSX renderer takes the same field: `<File baseName="runtime.ts" path={…} copy={templatePath} />`.

## Options

`PluginFactoryOptions` binds the plugin name, the user-facing options, and the resolved options together. The type flows through `definePlugin`, `defineGenerator`, and the resolver, keeping all three in sync.

```typescript twoslash [options.ts]
import { definePlugin } from 'kubb/kit'
import type { PluginFactoryOptions } from 'kubb/kit'

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

Use `createKubb` from `kubb` to run an in-process build and check that your generator emits the files you expect. Pair it with a small [OpenAPI](https://spec.openapis.org/oas/latest.html) fixture so tests stay fast and predictable.

`createKubb` does not apply the default adapter or parsers, so pass `adapter: adapterOas()` and the parsers your generator emits. (The `kubb` package's `defineConfig` is what wires those up automatically.) Without an adapter, Kubb runs in plugin-only mode and the `operation` and `schema` handlers never fire.

```typescript twoslash [plugin.test.ts]
// @errors: 2307
import { describe, it, expect } from 'vitest'
import { createKubb } from 'kubb'
import { ast, definePlugin, defineGenerator } from 'kubb/kit'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs } from '@kubb/parser-ts'

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
      input: './test/fixtures/petStore.yaml',
      output: { path: './dist/test' },
      adapter: adapterOas(),
      parsers: [parserTs()],
      plugins: [pluginExample()],
    })

    const { files } = await kubb.build()
    expect(files.length).toBeGreaterThan(0)
  })
})
```

### Observing lifecycle events

Subscribe to `kubb.hooks` before you call `build()` to trace plugin activity or collect metrics. Each hook receives one typed context object.

```typescript twoslash [lifecycle.ts]
import { createKubb } from 'kubb'
import { definePlugin } from 'kubb/kit'
import { adapterOas } from '@kubb/adapter-oas'

const kubb = createKubb({
  input: './petStore.yaml',
  output: { path: './gen' },
  adapter: adapterOas(),
  plugins: [definePlugin(() => ({ name: 'plugin-example', hooks: {} }))()],
})

// kubb:plugin:end receives a single KubbPluginEndContext, not two separate arguments.
kubb.hooks.hook('kubb:plugin:end', ({ plugin, duration, success }) => {
  console.log(`[${plugin.name}] finished in ${duration}ms (ok=${success})`)
})

// kubb:files:processing:update fires once per flush batch with an array of per-file updates.
kubb.hooks.hook('kubb:files:processing:update', ({ files }) => {
  for (const { file, processed, total, percentage } of files) {
    console.log(`[${processed}/${total}] (${percentage.toFixed(0)}%) ${file.path}`)
  }
})

await kubb.build()
```

## Publishing your plugin

### Configure package.json

Peer-depend on `kubb` at v5 to keep the runtime out of your bundle, and list it under `devDependencies` too, for local builds, typechecking, and any tests that call `createKubb`.

```json [package.json]
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
    "kubb": "^5.0.0"
  },
  "devDependencies": {
    "kubb": "^5.0.0",
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

Before you publish, run through the checklist:

- Exported TypeScript types compile without errors
- Public APIs carry JSDoc comments
- The README covers installation and usage
- All tests pass
- The version follows [Semantic Versioning](https://semver.org/)

See the [npm publishing docs](https://docs.npmjs.com/cli/v11/commands/npm-publish) for the full workflow:

```shell [Terminal]
npm login
npm publish --access public
```

### tsconfig.json

```json [tsconfig.json]
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

The [`kubb-labs/plugins`](https://github.com/kubb-labs/plugins) repository holds the official plugins that follow these conventions. Read the source to see how generators, resolvers, and options fit together in published packages.

### Schema generator

Generate a file for each schema definition in the spec:

```typescript twoslash [schema-generator.ts]
import { ast, defineGenerator } from 'kubb/kit'

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

Declare `dependencies` when your plugin must run after another. Kubb verifies the dependency at startup and throws when it is missing:

```typescript twoslash [plugin-with-dep.ts]
import { ast, definePlugin, defineGenerator } from 'kubb/kit'

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
            const name = resolver.name(node.operationId)
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
