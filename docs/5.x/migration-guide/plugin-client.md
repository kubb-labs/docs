---
title: 'Migration: @kubb/plugin-client'
description: Configuration changes for @kubb/plugin-client when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-client`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-client`](/plugins/plugin-client).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `wrapper` option is renamed to `sdk`.

Class clients (`clientType: 'class'`, `clientType: 'staticClass'`, and `sdk`) now name each tag class with a `Client` suffix. A `pet` tag generates `class PetClient` instead of `class Pet`. The old name collided with the schema model of the same name, so the barrel re-exported both and `tsc` failed with `TS2300: Duplicate identifier`. The suffix keeps the class and model apart.

```ts
// Before
export class Pet { /* ... */ }

// After
export class PetClient { /* ... */ }
```

To keep the previous names, override `resolveGroupName` on the `resolver` option. `this` is bound to the full resolver, so `this.resolveClassName` restores the old behavior.

```ts
pluginClient({
  clientType: 'class',
  resolver: {
    resolveGroupName(name) {
      return this.resolveClassName(name)
    },
  },
})
```

All other options are unchanged.

## Generated output

Operation type names, the client return type, and the bundled runtime export changed. See [Generated output changes: @kubb/plugin-client](/docs/5.x/migration-guide#kubb-plugin-client).
