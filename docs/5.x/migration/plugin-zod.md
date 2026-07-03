---
title: 'Migration: @kubb/plugin-zod'
description: Configuration and generated-output changes for @kubb/plugin-zod when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-zod`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). See the full option reference in [`@kubb/plugin-zod`](/plugins/plugin-zod/).

## Zod v3 no longer supported

The `version` option (`'3' | '4'`) is removed. v5 always generates [Zod v4](https://zod.dev) schemas.

Upgrade your `zod` dependency:

::: code-group

```shell [bun]
bun add zod@^4
```

```shell [pnpm]
pnpm add zod@^4
```

```shell [npm]
npm install zod@^4
```

```shell [yarn]
yarn add zod@^4
```

:::

## Removed: `mapper`

Use [`macros`](/plugins/plugin-zod/reference/options#macros) or [`printer`](/plugins/plugin-zod/reference/options#printer) instead.

## Removed: `typed`

In v4, `typed: true` annotated each schema with a `ToZod` type from the matching `@kubb/plugin-ts` output. v5 removes the option. Delete `typed` from your `pluginZod` options. To keep a type next to each schema, use [`inferred: true`](/plugins/plugin-zod/reference/options#inferred), which exports a `z.infer` alias instead.

```diff [kubb.config.ts]
pluginZod({
-  typed: true,
+  inferred: true,
})
```

## Removed: `wrapOutput`

The `wrapOutput` callback only fired on object property values, so a top-level string, enum, or union schema was never wrapped. v5 removes it in favor of a [`printer`](/plugins/plugin-zod/reference/options#printer) override, which targets any node type, including the whole schema. Inside an override, `this.base(node)` returns what the built-in handler would have emitted, so you wrap it instead of rebuilding it.

```diff [kubb.config.ts]
pluginZod({
-  wrapOutput: ({ output, schema }) => `${output}.openapi(${JSON.stringify({ description: schema.description })})`,
+  printer: {
+    nodes: {
+      object(node) {
+        return `${this.base(node)}.openapi(${JSON.stringify({ description: node.description })})`
+      },
+    },
+  },
})
```

## Removed: `operations`

The `operations` option is gone, so `plugin-zod` no longer emits an `operations.ts` file with the `operations` and `paths` maps. If you wired that file into a server framework, add a small custom plugin that rebuilds it. The plugin reuses the Zod resolver, so the generated schema names stay in sync with the rest of the output. See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for the plugin API.

::: code-group

```typescript [operationsPlugin.ts]
import { ast, defineGenerator, definePlugin } from 'kubb/kit'
import { pluginZodName, type ResolverZod } from '@kubb/plugin-zod'

const operationSchemaType = `{
  readonly request: z.ZodTypeAny | undefined
  readonly parameters: {
    readonly path: z.ZodTypeAny | undefined
    readonly query: z.ZodTypeAny | undefined
    readonly header: z.ZodTypeAny | undefined
  }
  readonly responses: {
    readonly [status: number]: z.ZodTypeAny
    readonly default: z.ZodTypeAny
  }
  readonly errors: {
    readonly [status: number]: z.ZodTypeAny
  }
}`

function renderKey(key: string): string {
  if (/^\d+$/.test(key)) return key
  if (/^[A-Za-z_$][\w$]*$/.test(key)) return key
  return JSON.stringify(key)
}

function renderObject(value: unknown, pad: string): string {
  if (value === null) return 'null'
  if (typeof value !== 'object') return String(value)

  const entries = Object.entries(value as Record<string, unknown>)
  if (entries.length === 0) return '{}'

  const inner = `${pad}  `
  const body = entries
    .map(([key, val]) => {
      const rendered = typeof val === 'string' ? val : renderObject(val, inner)
      return `${inner}${renderKey(key)}: ${rendered}`
    })
    .join(',\n')

  return `{\n${body}\n${pad}}`
}

function buildSchemaNames(node: ast.OperationNode, resolver: ResolverZod) {
  const pathParam = node.parameters.find((p) => p.in === 'path')
  const queryParam = node.parameters.find((p) => p.in === 'query')
  const headerParam = node.parameters.find((p) => p.in === 'header')

  const responses: Record<number | string, string> = {}
  const errors: Record<number | string, string> = {}

  for (const res of node.responses) {
    const statusNum = Number(res.statusCode)
    if (Number.isNaN(statusNum)) continue

    const name = resolver.resolveResponseStatusName(node, res.statusCode)
    responses[statusNum] = name
    if (statusNum >= 400) errors[statusNum] = name
  }

  responses['default'] = resolver.resolveResponseName(node)

  return {
    request: node.requestBody?.content?.[0]?.schema ? resolver.resolveDataName(node) : null,
    parameters: {
      path: pathParam ? resolver.resolvePathParamsName(node, pathParam) : null,
      query: queryParam ? resolver.resolveQueryParamsName(node, queryParam) : null,
      header: headerParam ? resolver.resolveHeaderParamsName(node, headerParam) : null,
    },
    responses,
    errors,
  }
}

export const pluginZodOperations = definePlugin(() => ({
  name: 'plugin-zod-operations',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addGenerator(
        defineGenerator({
          name: 'zod-operations',
          operations(nodes, gctx) {
            const resolver = gctx.getResolver(pluginZodName)
            const zodOptions = gctx.requirePlugin(pluginZodName).options ?? {}
            const output = zodOptions.output ?? { path: 'zod' }
            const group = zodOptions.group ?? undefined
            const importPath = zodOptions.importPath ?? 'zod'

            const operationsFile = resolver.resolveFile({ name: 'operations', extname: '.ts' }, { root: gctx.root, output, group })
            const transformed = nodes.filter(ast.isHttpOperationNode).map((node) => ({ node, data: buildSchemaNames(node, resolver) }))

            const imports = transformed.flatMap(({ node, data }) => {
              const names = [data.request, ...Object.values(data.responses), ...Object.values(data.parameters)].filter(Boolean) as Array<string>
              const opFile = resolver.resolveFile(
                { name: node.operationId, extname: '.ts', tag: node.tags[0] ?? 'default', path: node.path },
                { root: gctx.root, output, group },
              )

              return ast.factory.createImport({ name: names, path: opFile.path, root: operationsFile.path })
            })

            const operations: Record<string, unknown> = {}
            const paths: Record<string, Record<string, string>> = {}
            for (const { node, data } of transformed) {
              operations[node.operationId] = data
              paths[node.path] = { ...(paths[node.path] ?? {}), [node.method]: `operations[${JSON.stringify(node.operationId)}]` }
            }

            return [
              ast.factory.createFile({
                baseName: operationsFile.baseName,
                path: operationsFile.path,
                imports: [ast.factory.createImport({ name: ['z'], path: importPath, isTypeOnly: true }), ...imports],
                sources: [
                  ast.factory.createSource({
                    name: 'OperationSchema',
                    isExportable: true,
                    isIndexable: true,
                    nodes: [ast.factory.createText(`export type OperationSchema = ${operationSchemaType}`)],
                  }),
                  ast.factory.createSource({
                    name: 'OperationsMap',
                    isExportable: true,
                    isIndexable: true,
                    nodes: [ast.factory.createText('export type OperationsMap = Record<string, OperationSchema>')],
                  }),
                  ast.factory.createSource({
                    name: 'operations',
                    isExportable: true,
                    isIndexable: true,
                    nodes: [ast.factory.createText(`export const operations = ${renderObject(operations, '')} as const`)],
                  }),
                  ast.factory.createSource({
                    name: 'paths',
                    isExportable: true,
                    isIndexable: true,
                    nodes: [ast.factory.createText(`export const paths = ${renderObject(paths, '')} as const`)],
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

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginZodOperations } from './operationsPlugin.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginZod(), pluginZodOperations()],
})
```

:::

The custom plugin runs after `pluginZod`, so the per-operation schemas it imports already exist.

## Renamed: `transformers.name`

[`resolver.resolveSchemaName`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The v4 `transformers.schema` callback maps to [`macros`](/docs/5.x/migration#transformersschema-macros).

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas/). See [Migration: @kubb/adapter-oas](/docs/5.x/migration/adapter-oas).

## New: `regexType`

Pick how an OpenAPI `pattern` is emitted inside `.regex(...)`. The default `'literal'` keeps a regex literal, while `'constructor'` switches to the `RegExp` constructor. Use the constructor form when a regex literal trips up your build pipeline or when you need the pattern as a string.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginZod({ regexType: 'constructor' })],
})
```

```diff [Generated output]
-slug: z.string().regex(/^[a-z]+$/),
+slug: z.string().regex(new RegExp('^[a-z]+$')),
```

## Changed: inferred type names end with `Type`

With `inferred: true`, the `z.infer<typeof schema>` alias now carries a `SchemaType` suffix. `petSchema` exports `PetSchemaType` instead of `PetSchema`.

In v4 the schema value and its inferred type differed only by casing (`petSchema` and `PetSchema`). An all-uppercase name such as `SUV`, `URL`, or `API` produced the same identifier for both, so the barrel re-exported it twice and failed with `TS2300: Duplicate identifier`. The `Type` suffix keeps the value and type apart at any casing.

```diff [zod/petSchema.ts]
export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})

+export type PetSchemaType = z.infer<typeof petSchema>
-export type PetSchema = z.infer<typeof petSchema>
```

Update any imports that referenced the old name:

```diff [Update imports]
+import type { PetSchemaType } from './gen/zod/petSchema.ts'
-import type { PetSchema } from './gen/zod/petSchema.ts'
```

## Generated output

### Chained syntax instead of functional wrappers

v5 prefers the chained Zod 4 syntax. `.optional()` sits at the end of the chain, right before `.describe()`.

```diff [Generated output]
-id: z.optional(z.int()),
-shipDate: z.optional(z.iso.datetime()),
-status: z.optional(z.enum(['placed', 'approved']).describe('Order Status')),
+id: z.int().optional(),
+shipDate: z.iso.datetime().optional(),
+status: z.enum(['placed', 'approved']).optional().describe('Order Status'),
```

The functional form (`z.optional(...)`) is now reserved for `mini: true` output, which lives in its own `output.path`.

### Self-referencing getters only for true cycles

v4 wrapped almost every nested ref in a getter. v5 does so only when the schema is truly circular, meaning it references itself or its parent.

```diff [Diff]
- get category() {
-   return categorySchema.optional()
- },
- get tags() {
-   return z.array(tagSchema).optional()
- },
+ category: categorySchema.optional(),
+ tags: z.array(tagSchema).optional(),
  get parent() {
    return z.array(petSchema).optional()
  },
```
