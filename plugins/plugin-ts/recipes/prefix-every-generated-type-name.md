---
layout: doc
title: Prefix every generated type name
description: Override resolver.name so every type plugin-ts emits carries a shared prefix, useful for avoiding collisions with hand-written types.
outline: deep
---

# Prefix every generated type name

Set [`resolver.name`](/plugins/plugin-ts/reference/options#resolver) to patch the casing rule plugin-ts uses for every symbol. This override prefixes each generated type with `Api`, so generated names never collide with hand-written types of the same domain concept.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs, resolverTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      resolver: {
        name(name) {
          return `Api${resolverTs.name(name)}`
        },
      },
    }),
  ],
})
```

## Output example

```typescript [src/gen/types/Pet.ts]
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

```typescript [usage.ts]
import type { ApiPet } from './src/gen/types/Pet'

function describe(pet: ApiPet) {
  return pet.name
}
```

> [!TIP]
> `resolverTs.name(name)` applies the plugin's preset `PascalCase` before adding the prefix. `this.default.name(name)` would apply Kubb's core `camelCase` default instead. Concatenating the raw name can also leave multiword or operation-derived names uncased.
