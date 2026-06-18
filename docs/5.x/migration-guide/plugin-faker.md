---
title: 'Migration: @kubb/plugin-faker'
description: Configuration and generated-output changes for @kubb/plugin-faker when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-faker`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-faker`](/plugins/plugin-faker).

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas). [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`. Every other option stays the same.

## Generated output

### Stricter return type and intermediate variable

The `create` prefix stays (`createPet` is still `createPet`), matching the naming `plugin-msw` uses. The return type and internal structure change.

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
+ export function createPet(data?: Partial<Pet>): Required<Pet> {
+   const defaultFakeData = {
+     id: faker.number.int(),
+     ...
+   }
+   return {
+     ...defaultFakeData,
+     ...(data || {}),
+   } as Required<Pet>
+ }
```

`Required<Pet>` guarantees callers see populated fields even when the schema marks them optional.
