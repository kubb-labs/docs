---
title: 'Migration: @kubb/plugin-faker'
description: Configuration and generated-output changes for @kubb/plugin-faker when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-faker`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-faker`](/plugins/plugin-faker).

`dateType`, `integerType`, `unknownType`, `emptySchemaType`, and `contentType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas). [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`, and [`macros`](/docs/5.x/migration-guide#transformersschema-macros) replace `transformers.schema`. The `generators` option is [gone](/docs/5.x/migration-guide#generators-removed).

## Removed: `paramsCasing`

```typescript [v4 kubb.config.ts]
pluginFaker({ paramsCasing: 'camelcase' })
```

Properties inside the generated path, query, and header mocks are now always camelCase, so drop the option. This keeps the mocks assignable to the types from `@kubb/plugin-ts`, which also camelCases parameters.

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
