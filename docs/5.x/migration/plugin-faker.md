---
title: 'Migration: @kubb/plugin-faker'
description: Configuration and generated-output changes for @kubb/plugin-faker when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-faker`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). See the full option reference in [`@kubb/plugin-faker`](/plugins/plugin-faker/).

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas/). See [Migration: @kubb/adapter-oas](/docs/5.x/migration/adapter-oas). [`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name` (see [Override a resolver](/docs/5.x/guide/going-further/resolvers)), and [`macros`](/docs/5.x/migration#transformersschema-macros) replace `transformers.schema`. The `generators` option is [gone](/docs/5.x/migration#generators-removed).

## Removed: `paramsCasing`

Parameter property names in the generated path, query, and header mocks come straight from the OpenAPI document, through the shared `buildParams` helper in `@kubb/plugin-ts`. They match the plugin-ts `*Path`, `*Query`, and `*Headers` types exactly, so `paramsCasing` had nothing left to configure.

```typescript [v4 kubb.config.ts]
pluginFaker({ paramsCasing: 'camelcase' })
```

## Removed: `mapper`

The `mapper` option mapped a property name to a raw Faker expression. v5 removes it, matching the removal on `plugin-ts` and `plugin-zod`. Rewrite the property's schema with a [macro](/docs/5.x/guide/going-further/macros) instead. The default printer turns an enum into `faker.helpers.arrayElement([...])`, so an enum macro reproduces the common case, and a [`printer`](/plugins/plugin-faker/reference/options#printer) override changes how a schema type renders.

The generated mock is typed against the `@kubb/plugin-ts` output, so pick values the property's type allows. The v4 `mapper` bypassed that check with a raw expression.

```diff [kubb.config.ts]
import { ast } from 'kubb/kit'

pluginFaker({
-  mapper: {
-    status: `faker.helpers.arrayElement<any>(['available', 'pending'])`,
-  },
+  macros: [
+    {
+      name: 'pet-status-values',
+      schema(node) {
+        if (node.name === 'Pet' && 'properties' in node) {
+          return {
+            ...node,
+            properties: node.properties.map((property) =>
+              property.name === 'status'
+                ? { ...property, schema: ast.factory.createSchema({ type: 'enum', primitive: 'string', enumValues: ['available', 'pending'] }) }
+                : property,
+            ),
+          }
+        }
+        return node
+      },
+    },
+  ],
})
```

## Generated output

### Generic return type and intermediate variable

The `create` prefix stays, so `createPet` is still `createPet`. The signature and internal structure change. The factory now takes a generic `TData` and lifts the fake values into a `defaultFakeData` variable before the spread.

```diff [Diff]
- export function createPet(data?: Partial<Pet>): Pet {
-   return {
-     ...{
-       id: faker.number.int(),
-       ...
-     },
-     ...(data || {}),
-   }
- }
+ export function createPet<TData extends Partial<Pet> = object>(data?: TData) {
+   const defaultFakeData = {
+     id: faker.number.int(),
+     ...
+   }
+   return {
+     ...defaultFakeData,
+     ...(data || {}),
+   } as Omit<typeof defaultFakeData, keyof TData> & TData
+ }
```

The inferred return type keeps the fields you pass in `data` exactly as typed and fills the rest from `defaultFakeData`, so an override like `createPet({ id: 1 })` reads back `id` as the literal you set rather than the wider schema type.
