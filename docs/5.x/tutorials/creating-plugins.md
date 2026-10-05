---
layout: doc
title: Create your first plugin
description: Build, test, and publish a Kubb plugin that generates one file per
  API operation.
outline:
  - 2
  - 3
order: 2
navigation:
  title: Create your first plugin
---

# Create your first plugin

Build a plugin that writes one comment file per API operation. You need Node.js 22 or higher, TypeScript knowledge, and an OpenAPI specification. Check the [plugin catalogue](/plugins) before building an output that already exists.

## 1. Install

```shell [Terminal]
npm install -D kubb typescript @types/node vitest
```

All authoring APIs come from `kubb/kit`, included with `kubb`.

## 2. Create the plugin

A plugin factory returns its name and lifecycle hooks. Register a generator and resolver in `kubb:plugin:setup`:

```typescript twoslash [src/plugin.ts]
import { ast, createResolver, defineGenerator, definePlugin } from 'kubb/kit'

const resolver = createResolver({ pluginName: 'plugin-example' })

const operationsGenerator = defineGenerator({
  name: 'operation-comments',
  operation(node, ctx) {
    const name = ctx.resolver.name(node.operationId)
    return [
      ast.factory.createFile({
        baseName: `${name}.ts`,
        path: `${ctx.root}/${name}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`// ${node.method} ${node.path}\n`)],
          }),
        ],
      }),
    ]
  },
})

export const pluginExample = definePlugin(() => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.setResolver(resolver)
      ctx.addGenerator(operationsGenerator)
    },
  },
}))
```

The `operation` handler runs once per operation and returns `FileNode`s. Use `schema` for reusable schemas or `operations` for a single file covering the whole operation set. The [generator reference](/docs/5.x/reference/kit/generators) lists the context properties and return types.

## 3. Generate

Register the plugin in your config:

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginExample } from './src/plugin'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [pluginExample()],
})
```

```shell [Terminal]
npx kubb generate
```

Each generated file contains the operation's method and path. For an operation named `listPets`, inspect `src/gen/listPets.ts`.

## 4. Add options or dependencies

Use `PluginFactoryOptions` to type user options and their resolved values. Apply defaults in the plugin factory and store resolved options with `ctx.setOptions`. Generators read them from the plugin context. See [Plugin reference](/docs/5.x/reference/kit/plugins).

Declare `dependencies` when another plugin must run first. In the generator, call `ctx.requirePlugin(name)` to require it and `ctx.getResolver(name)` to reuse its names and paths. Missing dependencies fail when requested, not during ordering.

For identifier or file naming, adjust your resolver. Users override its defaults through their plugin configuration. See [Override a resolver](/docs/5.x/how-to/resolvers).

## 5. Test the output

Run an in-process build with memory storage and a small fixture. `createKubb` from `kubb` supplies the same adapter and parser defaults as `defineConfig`.

```typescript [src/plugin.test.ts]
import { describe, expect, it } from 'vitest'
import { createKubb } from 'kubb'
import { memoryStorage } from 'kubb/kit'
import { pluginExample } from './plugin'

const input = {
  openapi: '3.0.3',
  info: { title: 'Pets', version: '1.0.0' },
  paths: {
    '/pets': {
      get: {
        operationId: 'listPets',
        responses: { '200': { description: 'A list of pets' } },
      },
    },
  },
}

describe('pluginExample', () => {
  it('emits an operation comment', async () => {
    const { files, storage } = await createKubb({
      input,
      output: { path: './gen' },
      storage: memoryStorage(),
      plugins: [pluginExample()],
    }).build()

    const file = files.find((file) => file.baseName === 'listPets.ts')
    expect(file).toBeDefined()
    expect(await storage.readItem(file!.path)).toContain('/pets')
  })
})
```

`build()` throws on errors. Use `safeBuild()` to inspect diagnostics without throwing, then check `Diagnostics.hasError`. See [Engine reference](/docs/5.x/reference/kit/engine) and [Testing helpers](/docs/5.x/reference/kit/testing).

## 6. Publish

Use `kubb-plugin-<name>` for the npm package, `plugin-<name>` for the internal name, and `plugin<Name>` for its factory. Export the factory from `src/index.ts`.

Keep generators and resolvers in separate folders as the plugin grows. Official [plugin source](https://github.com/kubb-labs/plugins) provides examples.

Build TypeScript declarations and JavaScript into `dist`. Configure the package entrypoints and dependencies:

```json [package.json]
{
  "name": "kubb-plugin-example",
  "version": "1.0.0",
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "peerDependencies": { "kubb": "^5.0.0" },
  "devDependencies": { "kubb": "^5.0.0" }
}
```

Before publishing, compile the package, run its tests, and document installation and usage in the README. Then run `npm publish --access public` from the package directory.

## See also

- [Extension model](/docs/5.x/explanation/extensions)
- [Plugin API](/docs/5.x/reference/kit/plugins)
- [Lifecycle hooks](/docs/5.x/reference/kit/hooks)
