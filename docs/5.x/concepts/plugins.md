---
layout: doc
title: Plugins - Build Custom Generators for Any Spec
description: Build Kubb plugins that hook into the lifecycle, register generators, declare resolvers, and emit files. The hook-style definePlugin API mirrors Astro integrations.
outline: deep
---

# Plugins

Plugins teach Kubb to generate something new. A plugin owns its file naming, its output folder, its lifecycle hooks, and the [generators](/docs/5.x/api/core#generator) that walk the [AST](/docs/5.x/concepts/ast) and emit `FileNode`s. Most of what you see in a generated `src/gen/` folder comes from a plugin.

> [!TIP]
> Need a TanStack Query client, a Zod schema set, or MSW handlers? Check the [Plugins](/plugins) registry first. Build a custom plugin only when no existing one fits.

## Quick start

A plugin is a factory created with `definePlugin`. It returns an object with a `name` and a `hooks` map.

```typescript twoslash [my-plugin.ts]
import { definePlugin } from '@kubb/core'

export const pluginHello = definePlugin(() => ({
  name: 'plugin-hello',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.injectFile({
        baseName: 'hello.ts',
        path: `${ctx.config.root}/hello.ts`,
        sources: [{ kind: 'Source', nodes: [{ kind: 'Text', value: '// Hello from a plugin\n' }] }],
      })
    },
  },
}))
```

Register it in `kubb.config.ts`:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb'
import { pluginHello } from './my-plugin.ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginHello()],
})
```

## Anatomy

| Property        | Type                                   | Required | Purpose                                                                                          |
| --------------- | -------------------------------------- | -------- | ------------------------------------------------------------------------------------------------ |
| `name`          | `string`                               | Yes      | Unique plugin identifier (`plugin-<thing>` by convention).                                       |
| `hooks`         | `{ [K in keyof KubbHooks]?: handler }` | Yes      | Map of lifecycle event handlers. Keys mirror the [`KubbHooks`](#lifecycle-events) event names.   |
| `dependencies?` | `Array<string>`                        | No       | Other plugin names that must be registered. Kubb throws at startup when a dependency is missing. |
| `enforce?`      | `'pre' \| 'post'`                      | No       | Run this plugin before (`pre`) or after (`post`) all normal plugins. Dependencies always win.    |
| `options?`      | `TFactory['options']`                  | No       | The user options forwarded by the factory. Typed via the `PluginFactoryOptions` generic.         |

## Lifecycle events

The `hooks` map can subscribe to any event in [`KubbHooks`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts). Here is the full list, in the order they fire during a build:

| Phase       | Event                                                                    | Context                                                                                                    | When it fires                                                            |
| ----------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Lifecycle   | `kubb:lifecycle:start`                                                   | [`KubbLifecycleStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)       | Beginning of the Kubb run, before configuration loading.                 |
| Lifecycle   | `kubb:lifecycle:end`                                                     | none                                                                                                       | End of the run, after every other event.                                 |
| Generation  | `kubb:generation:start`                                                  | [`KubbGenerationStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)      | Code generation phase begins.                                            |
| Plugin      | `kubb:plugin:setup`                                                      | [`KubbPluginSetupContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts)    | Once per plugin. Register generators, resolver, macros, renderer.        |
| Plugin      | `kubb:build:start`                                                       | [`KubbBuildStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)     | After all `kubb:plugin:setup` handlers, before the plugin loop.          |
| Plugin      | `kubb:plugin:start`                                                      | [`KubbPluginStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts)          | Just before this plugin's generators run.                                |
| Plugin      | `kubb:generate:schema`                                                   | `(node: SchemaNode, ctx: GeneratorContext)`                                                                | For each schema node during the AST walk.                                |
| Plugin      | `kubb:generate:operation`                                                | `(node: OperationNode, ctx: GeneratorContext)`                                                             | For each operation node during the AST walk.                             |
| Plugin      | `kubb:generate:operations`                                               | `(nodes: OperationNode[], ctx: GeneratorContext)`                                                          | Once per plugin after every operation has been walked.                   |
| Plugin      | `kubb:plugin:end`                                                        | [`KubbPluginEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/definePlugin.ts)      | This plugin finished. `files` snapshot is available.                     |
| Plugin      | `kubb:plugins:end`                                                       | [`KubbPluginsEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)           | All plugins finished, before files are written. Inject final files here. |
| Generation  | `kubb:generation:end`                                                    | [`KubbGenerationEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)        | Code generation phase complete. Carries the run's `diagnostics`, `status`, and file count. |
| Files       | `kubb:files:processing:start`                                            | [`KubbFilesProcessingStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts) | File processing starts.                                                  |
| Files       | `kubb:files:processing:update`                                           | [`KubbFilesProcessingUpdateContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts) | Batched per-flush progress updates. The context exposes a `files` array of `KubbFileProcessingUpdate` items.                                              |
| Files       | `kubb:files:processing:end`                                              | [`KubbFilesProcessingEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)   | All files written.                                                       |
| Build       | `kubb:build:end`                                                         | [`KubbBuildEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)             | Build finished, after files are on disk.                                 |
| Format      | `kubb:format:start`                                                      | none                                                                                                       | Formatter (Biome, Prettier, …) starts.                                   |
| Format      | `kubb:format:end`                                                        | none                                                                                                       | Formatter completes.                                                     |
| Lint        | `kubb:lint:start`                                                        | none                                                                                                       | Linter starts.                                                           |
| Lint        | `kubb:lint:end`                                                          | none                                                                                                       | Linter completes.                                                        |
| Hooks       | `kubb:hooks:start`                                                       | none                                                                                                       | User-defined `hooks.done` execution starts.                              |
| Hooks       | `kubb:hook:start`                                                        | [`KubbHookStartContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)            | Each individual user hook command starts.                                |
| Hooks       | `kubb:hook:end`                                                          | [`KubbHookEndContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)              | Each individual user hook completes.                                     |
| Hooks       | `kubb:hooks:end`                                                         | none                                                                                                       | All user hooks finished.                                                 |
| Diagnostics | `kubb:diagnostic`                                                        | [`KubbDiagnosticContext`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/types.ts)     | Emitted for each collected [diagnostic](/docs/5.x/reference/diagnostics) during the run. |
| Diagnostics | `kubb:info` / `kubb:success` / `kubb:warn` / `kubb:error`                | corresponding `KubbInfoContext`, `KubbSuccessContext`, …                                                   | Logging events. Subscribe to forward into your own observability stack.  |

> [!TIP]
> Plugins with `enforce: 'post'` run after all normal plugins for any given event, which suits cross-plugin concerns like barrel generation. See [`@kubb/plugin-barrel`](/plugins/plugin-barrel) for an example.

## The setup context

`kubb:plugin:setup` receives a `KubbPluginSetupContext` that wires the plugin into the build:

| Method / Property | Purpose                                                                                |
| ----------------- | -------------------------------------------------------------------------------------- |
| `addGenerator`    | Register a [`Generator`](/docs/5.x/api/core#generator) that walks the AST.             |
| `setResolver`     | Set or override the [resolver](/docs/5.x/api/core#resolver) (file naming + paths).     |
| `addMacro`        | Add a [macro](/docs/5.x/concepts/macros) that rewrites AST nodes before generators.   |
| `setMacros`       | Replace this plugin's [macros](/docs/5.x/concepts/macros) with a new list.             |
| `setOptions`      | Provide resolved options to the build loop.                                            |
| `injectFile`      | Inject a raw `UserFileNode` into the build, bypassing generators.                      |
| `updateConfig`    | Merge a partial config update into the running build.                                  |
| `config`          | The resolved `Config` at setup time.                                                   |
| `options`         | The user-supplied plugin options.                                                      |

## Generators

A generator is what walks the AST for a plugin. Register one with `addGenerator` inside `kubb:plugin:setup`:

```typescript twoslash [generator.ts]
import { ast, definePlugin, defineGenerator } from '@kubb/core'

const operationGenerator = defineGenerator({
  name: 'operation-files',
  async operation(node, ctx) {
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

export const pluginOperations = definePlugin(() => ({
  name: 'plugin-operations',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(operationGenerator)
    },
  },
}))
```

A generator may implement any combination of three handlers:

| Handler      | Called for…                                              | Returns                            |
| ------------ | -------------------------------------------------------- | ---------------------------------- |
| `schema`     | Each `SchemaNode` in the AST.                            | `Array<FileNode>`, `void`, or JSX. |
| `operation`  | Each `OperationNode` in the AST.                         | `Array<FileNode>`, `void`, or JSX. |
| `operations` | Once with all `OperationNode`s after the operation walk. | `Array<FileNode>`, `void`, or JSX. |

Each handler receives a `GeneratorContext` with helpers like `addFile`, `upsertFile` (merge with another generator's output), `getResolver(name)`, `requirePlugin(name)`, `info`, `warn`, `error`, plus the resolved `adapter`, the document `meta` (an `InputMeta` with `title`, `version`, `baseURL`, `circularNames`, and `enumNames`), and per-node `options`.

A handler returns `Array<FileNode>` built with the `create*` factories from [`@kubb/ast`](/docs/5.x/concepts/ast), which is the default. It may instead return JSX, in which case the generator sets `renderer: jsxRenderer` and `@kubb/renderer-jsx` walks the JSX into the same `FileNode`s. The [creating-plugins guide](/docs/5.x/guides/creating-plugins#emit-roles) names the printer, renderer, and serializer roles around that path.

## Resolvers

Every plugin owns a resolver that decides where files live and how they are named. Other plugins call `ctx.getResolver('plugin-name')` to refer to those names without hard-coding paths.

```typescript twoslash [resolver.ts]
import { defineResolver } from '@kubb/core'
import path from 'node:path'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

type PluginHello = PluginFactoryOptions<'plugin-hello', object, object, Resolver>

export const resolverHello = defineResolver<PluginHello>(() => ({
  name: 'default',
  pluginName: 'plugin-hello',
  resolvePath({ baseName }, { root, output }) {
    return path.resolve(root, output.path, 'hello', baseName)
  },
}))
```

Use it inside the plugin:

```typescript twoslash [resolver-plugin.ts]
import { defineResolver, definePlugin } from '@kubb/core'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

type PluginHello = PluginFactoryOptions<'plugin-hello', object, object, Resolver>
const resolverHello = defineResolver<PluginHello>(() => ({
  name: 'default',
  pluginName: 'plugin-hello',
}))

export const pluginHello = definePlugin<PluginHello>(() => ({
  name: 'plugin-hello',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.setResolver(resolverHello)
    },
  },
}))
```

Other plugins consume it through the generator context:

```typescript twoslash [consumer.ts]
import { definePlugin, defineGenerator } from '@kubb/core'

const consumerGenerator = defineGenerator({
  name: 'consumer',
  schema(node, ctx) {
    const helloResolver = ctx.getResolver('plugin-hello')
    if ('name' in node && typeof node.name === 'string') {
      const name = helloResolver.default(node.name, 'function')
      console.log(`hello name: ${name}`)
    }
  },
})

export const pluginConsumer = definePlugin(() => ({
  name: 'plugin-consumer',
  dependencies: ['plugin-hello'],
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(consumerGenerator)
    },
  },
}))
```

## Macros

A [macro](/docs/5.x/concepts/macros) is a named, composable transform that rewrites nodes before they reach this plugin's generators. Whatever a macro returns replaces the original node for that plugin only, so other plugins keep seeing the untransformed AST.

```ts
type Plugin<TFactory> = {
  // ...
  macros?: Array<ast.Macro>
}
```

Use macros to rename, filter, or rewrite nodes before generation, without forking the adapter or mutating shared state. Register them from `kubb:plugin:setup` with `ctx.addMacro` or `ctx.setMacros`:

```typescript twoslash [macros.ts]
import { ast, definePlugin } from '@kubb/core'

const macroRename = ast.defineMacro({
  name: 'rename',
  operation(node) {
    return {
      ...node,
      operationId: node.operationId.replace(/^get/, 'fetch'),
    }
  },
  schema(node) {
    if (node.type === 'object') {
      return { ...node, name: `${node.name}Dto` }
    }
  },
})

export const pluginRename = definePlugin(() => ({
  name: 'plugin-rename',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addMacro(macroRename)
    },
  },
}))
```

A few rules apply:

Each macro callback (`input`, `output`, `operation`, `schema`, `property`, `parameter`, `response`) is optional, and unhandled node types pass through unchanged. Returning `undefined` keeps the original node, while returning a node of the same type replaces it. Macros run per plugin and in order, so a later macro sees the output of an earlier one. To share a macro across plugins, export it and add it from each plugin's setup. Macros run before resolver options are computed, so renamed `operationId`s and `SchemaNode.name`s flow into `resolveOptions`, `resolvePath`, and `resolveFile`. Keep macros pure: build a new node and return it rather than mutating the input, since the AST is shared by reference.

## Naming convention

Kubb expects every plugin to follow the same naming pattern, so other plugins, the CLI, and the docs find them by inference. The convention applies to four places at once:

| Surface                      | Pattern                                          | Example                                 |
| ---------------------------- | ------------------------------------------------ | --------------------------------------- |
| npm package                  | `@<scope>/plugin-<name>` or `kubb-plugin-<name>` | `@kubb/plugin-ts`, `kubb-plugin-stripe` |
| Plugin runtime name          | `plugin-<name>` (kebab-case, lowercase)          | `'plugin-ts'`                           |
| Factory export               | `plugin<Name>` (camelCase)                       | `pluginTs`, `pluginReactQuery`          |
| `PluginFactoryOptions` alias | `Plugin<Name>` (PascalCase)                      | `PluginTs`, `PluginReactQuery`          |

Export the runtime name as a constant so consumers reference it without typos when declaring `dependencies`:

```typescript twoslash [naming.ts]
import { definePlugin } from '@kubb/core'
import type { PluginFactoryOptions, Resolver } from '@kubb/core'

export type PluginExample = PluginFactoryOptions<'plugin-example', { greeting?: string }, { greeting: string }, Resolver>
export const pluginExampleName = 'plugin-example' satisfies PluginExample['name']

export const pluginExample = definePlugin<PluginExample>((options) => ({
  name: pluginExampleName,
  options: { greeting: options.greeting ?? 'Hello' },
  hooks: {},
}))
```

> [!TIP]
> Built-in plugins (`@kubb/plugin-ts`, `@kubb/plugin-zod`, `@kubb/plugin-client`, …) all follow this layout. Match it so users swap your plugin in without rewiring imports.

## Built-in plugins

The Kubb monorepo ships official plugins for the most common use cases. Browse them in the [Plugins registry](/plugins) or in source:

| Plugin                                                    | Generates                        |
| --------------------------------------------------------- | -------------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts)                   | TypeScript types from your spec. |
| [`@kubb/plugin-zod`](/plugins/plugin-zod)                 | Zod schemas.                     |
| [`@kubb/plugin-client`](/plugins/plugin-client)           | Type-safe HTTP client functions. |
| [`@kubb/plugin-react-query`](/plugins/plugin-react-query) | React Query (TanStack) hooks.    |
| [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query)     | Vue Query (TanStack) hooks.      |
| [`@kubb/plugin-msw`](/plugins/plugin-msw)                 | MSW request handlers.            |
| [`@kubb/plugin-faker`](/plugins/plugin-faker)             | Faker-based mock data.           |
| [`@kubb/plugin-cypress`](/plugins/plugin-cypress)         | Cypress request helpers.         |
| [`@kubb/plugin-mcp`](/plugins/plugin-mcp)                 | MCP tool definitions.            |
| [`@kubb/plugin-redoc`](/plugins/plugin-redoc)             | Redoc API documentation.         |

## Examples

### Inject a single file from setup

Use `ctx.injectFile` from `kubb:plugin:setup` when a plugin emits a fixed asset that does not depend on the input spec, such as a README, a barrel file, or a pre-baked runtime helper.

```typescript twoslash [inject.ts]
import { definePlugin } from '@kubb/core'

export const pluginBanner = definePlugin(() => ({
  name: 'plugin-banner',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.injectFile({
        baseName: 'README.md',
        path: `${ctx.config.root}/README.md`,
        sources: [{ kind: 'Source', nodes: [{ kind: 'Text', value: '# Generated by Kubb\n' }] }],
      })
    },
  },
}))
```

### Declare a dependency on another plugin

Use `dependencies` to guarantee a sibling plugin runs first. Order in the `plugins` array stops mattering, and a missing dependency fails the build with a clear error.

```typescript twoslash [depends.ts]
import { definePlugin } from '@kubb/core'

export const pluginClientWrapper = definePlugin(() => ({
  name: 'plugin-client-wrapper',
  dependencies: ['plugin-ts'],
  hooks: {
    'kubb:plugin:setup'() {
      console.log('Starting plugin-client-wrapper after plugin-ts')
    },
  },
}))
```

### Read sibling output in `kubb:plugin:end`

`kubb:plugin:end` runs after all generators in the plugin finish. Use it to emit aggregate files (barrels, manifests, type re-exports) from the files the plugin already produced.

```typescript twoslash [barrel.ts]
import { definePlugin } from '@kubb/core'

export const pluginBarrel = definePlugin(() => ({
  name: 'plugin-barrel',
  hooks: {
    'kubb:plugin:end'({ files }) {
      const exports = files.map((file) => `export * from './${file.name}'`).join('\n')
      console.log(`Generated ${files.length} files\n${exports}`)
    },
  },
}))
```

## Best practices

Split unrelated outputs into separate plugins so users opt in or out. Prefix the name with `plugin-` (or `@scope/plugin-`) and keep it stable, since other plugins look it up by name. Use `dependencies` instead of declaration order, which is fragile. Have generators ask `ctx.getResolver(name)` rather than building paths inline. Use closure state inside the factory or the setup context, and avoid global state, since plugins may run in parallel. Throw early in `kubb:plugin:setup` when required options are missing, so the build aborts before any file is written.
