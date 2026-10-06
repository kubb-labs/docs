---
layout: doc
title: Create, extend, and publish a plugin
description: Create and test a Kubb plugin, add a configurable comment prefix, and package it for npm.
outline:
  - 2
  - 3
order: 2
navigation:
  title: Create, extend, and publish a plugin
  icon: i-iconoir-ev-plug
---

# Create, extend, and publish a plugin

Build a plugin that writes `listPets.ts` containing the method and path of one API operation, add a configurable prefix, then prepare an npm package. You need Node.js 22 or higher, npm, and TypeScript knowledge.

## 1. Create a project

```shell [Terminal]
mkdir kubb-first-plugin
cd kubb-first-plugin
npm init -y
npm pkg set type=module
npm install -D kubb typescript @types/node vitest
mkdir src
```

All authoring APIs come from `kubb/kit`, included with `kubb`.

## 2. Add the specification

Create `petStore.yaml` in the project root:

```yaml [petStore.yaml]
openapi: 3.0.3
info:
  title: Pets
  version: 1.0.0
paths:
  /pets:
    get:
      operationId: listPets
      responses:
        '200':
          description: A list of pets
```

## 3. Create the plugin

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

The `operation` handler writes a comment containing the operation’s HTTP method and path.

## 4. Generate

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

Read the generated file:

```shell [Terminal]
node -e "console.log(require('node:fs').readFileSync('src/gen/listPets.ts', 'utf8'))"
```

It contains a comment naming `GET` and `/pets`.

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

Run the test:

```shell [Terminal]
npx vitest run src/plugin.test.ts
```

Vitest reports one passing test. It checks the generated file in memory without writing to disk.

## 6. Extend the plugin {#extend-the-plugin}

Add a `prefix` option so users can label the generated comment. Replace `src/plugin.ts` with:

```typescript [src/plugin.ts]
import { ast, createResolver, defineGenerator, definePlugin } from 'kubb/kit'
import type { PluginFactoryOptions } from 'kubb/kit'

type ExamplePlugin = PluginFactoryOptions<
  'plugin-example',
  { prefix?: string },
  { prefix: string }
>

const resolver = createResolver<ExamplePlugin>({ pluginName: 'plugin-example' })

const operationsGenerator = defineGenerator<ExamplePlugin>({
  name: 'operation-comments',
  operation(node, ctx) {
    const name = ctx.resolver.name(node.operationId)
    return [ast.factory.createFile({
      baseName: `${name}.ts`,
      path: `${ctx.root}/${name}.ts`,
      sources: [ast.factory.createSource({
        nodes: [ast.factory.createText(`// ${ctx.options.prefix}${node.method} ${node.path}\n`)],
      })],
    })]
  },
})

export const pluginExample = definePlugin<ExamplePlugin>((options = {}) => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.setOptions({ prefix: options.prefix ?? '' })
      ctx.setResolver(resolver)
      ctx.addGenerator(operationsGenerator)
    },
  },
}))
```

The factory accepts an optional prefix, resolves its default to an empty string, and stores the result with `ctx.setOptions`. The generator reads the resolved value from `ctx.options`.

Change the config to `plugins: [pluginExample({ prefix: 'API: ' })]`, then run `npx kubb generate` again. The generated comment now reads:

```typescript [src/gen/listPets.ts]
// API: GET /pets
```

Add this test inside the existing `describe` block in `src/plugin.test.ts`:

```typescript [src/plugin.test.ts]
it('applies the configured prefix', async () => {
  const { files, storage } = await createKubb({
    input,
    output: { path: './gen' },
    storage: memoryStorage(),
    plugins: [pluginExample({ prefix: 'API: ' })],
  }).build()

  const file = files.find((file) => file.baseName === 'listPets.ts')
  expect(file).toBeDefined()
  expect(await storage.readItem(file!.path)).toContain('// API: GET /pets')
})
```

Run `npx vitest run src/plugin.test.ts` again. Both tests should pass: the original behavior remains available, and the new option changes the output.

For further extensions, use the [Plugin reference](/docs/5.x/reference/kit/plugins) and [Generator reference](/docs/5.x/reference/kit/generators). A dependency on another plugin lets your generator reuse its resolver rather than guessing generated names; see [Dependencies and ordering](/docs/5.x/explanation/extensions#dependencies).

## 7. Build the package

Export the factory from a package entrypoint. Use a `.js` extension for the relative import so the compiled ESM works in Node:

```typescript [src/index.ts]
export { pluginExample } from './plugin.js'
```

Create a TypeScript build config:

```json [tsconfig.json]
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "declaration": true,
    "skipLibCheck": true,
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/index.ts", "src/plugin.ts"]
}
```

Add the following fields to your existing `package.json`, keeping the development dependencies installed earlier. Replace the package name with an available name you own before publishing:

```json [package.json fields]
{
  "name": "kubb-plugin-example",
  "version": "1.0.0",
  "type": "module",
  "files": ["dist"],
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run src/plugin.test.ts",
    "prepack": "npm run build && npm test"
  },
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "peerDependencies": { "kubb": "^5.0.0" }
}
```

`kubb` remains a development dependency so you can build and test locally. The peer dependency asks consumers to supply a compatible Kubb version.

Build, inspect the files npm would include, and create a local tarball:

```shell [Terminal]
npm run build
npm pack --dry-run
npm pack
```

The dry run should list `dist/index.js`, `dist/index.d.ts`, `dist/plugin.js`, and `dist/plugin.d.ts`, along with `package.json`. The tarball should contain compiled output rather than the fixture, tests, or generated client files. `prepack` runs the build and both tests before packaging.

## 8. Publish

Add a README showing installation and `pluginExample({ prefix: 'API: ' })` in a Kubb config. Choose a license and include its file. Review the tarball and confirm the package name and version before publishing to npm.

When you are ready, sign in to your npm account and publish:

```shell [Terminal]
npm login
npm publish --access public
```

Consumers install your package as a development dependency and import its factory from the package name, rather than from `./src/plugin`.

## See also

- [Extension model](/docs/5.x/explanation/extensions)
- [Plugin API](/docs/5.x/reference/kit/plugins)
- [Lifecycle hooks](/docs/5.x/reference/kit/hooks)
