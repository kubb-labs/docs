---
layout: doc
title: Prefix every generated type name
description: Override resolver.name so every type plugin-ts emits carries a shared prefix, useful for avoiding collisions with hand-written types.
outline: deep
---

# Prefix every generated type name

Set [`resolver.name`](/plugins/plugin-ts/reference/options#resolver) to patch the casing rule plugin-ts uses for every symbol. This override prefixes each generated type with `Api`, so generated names never collide with hand-written types of the same domain concept.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      resolver: {
        name(name) {
          return `Api${name}`
        },
      },
    }),
  ],
})
```

## Output example

```typescript twoslash [src/gen/types/Pet.ts]
import type { ApiCat } from './Cat'
import type { ApiCategory } from './Category'
import type { ApiDog } from './Dog'
import type { ApiTag } from './Tag'

export type ApiPet = (((ApiDog & {
    readonly type: "dog";
}) | (ApiCat & {
    readonly type: "cat";
})) & {
    id?: bigint;
    name: string;
    category?: ApiCategory;
});
```

```typescript twoslash [usage.ts]
import type { ApiPet } from './src/gen/types/Pet'

function describe(pet: ApiPet) {
  return pet.name
}
```

> [!TIP]
> The `name` callback receives the type name already cased, so returning `` `Api${name}` `` is enough. The general [resolver guide](/docs/5.x/guide/going-further/resolvers) shows this same pattern wrapped in `this.default.name(name)`, reusing the built-in casing, but that call re-lowercases the first letter instead (`ApiCat` becomes `Apicat`), so this recipe skips it and prefixes the incoming name directly.
