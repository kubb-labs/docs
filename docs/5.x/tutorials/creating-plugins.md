---
layout: doc
title: Create your first plugin
description: Build and test a Kubb plugin that generates a comment file for an API operation.
outline:
  - 2
  - 3
order: 2
navigation:
  title: Create your first plugin
---

# Create your first plugin

Build a plugin that writes `listPets.ts` containing the method and path of one API operation. You need Node.js 22 or higher, npm, and TypeScript knowledge.

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

## See also

- [Extend and publish a plugin](/docs/5.x/how-to/extending-plugins)
- [Extension model](/docs/5.x/explanation/extensions)
- [Plugin API](/docs/5.x/reference/kit/plugins)
- [Lifecycle hooks](/docs/5.x/reference/kit/hooks)
