---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-barrel. Sets the re-export style for the index.ts barrel files Kubb generates.
outline: deep
---

# Options

`pluginBarrel` takes no arguments. You configure it through `output.barrel`, either on `defineConfig` to set the root barrel and the default every plugin inherits, or on a single plugin to override that plugin's barrel.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output.barrel`](#output-barrel) | `{ type: 'all' \| 'named' } \| false` | `{ type: 'named' }` | Re-export style for the barrel files |
| [`type`](#type) | `'all' \| 'named'` | `'named'` | Named exports or a wildcard export |
| [`nested`](#nested) | `boolean` | `false` | Write an `index.ts` in every subdirectory |

### output.barrel

Sets the re-export style for the barrel files. Set it on `defineConfig` to control the root barrel and the default every plugin inherits. Set it on a single plugin to override that plugin's barrel.

The `type` field picks the export style. A plugin's `output.barrel` also accepts `nested`, so the plugin writes an `index.ts` in every subdirectory. The root `output.barrel` has no `nested` field and always stays flat.

Set `barrel: false` on `defineConfig` to disable barrels everywhere: the root barrel is skipped, and every plugin without its own `output.barrel` inherits the `false`. A plugin that sets its own non-false `output.barrel` keeps its barrel. Set `barrel: false` on a single plugin to disable only that plugin's barrel and drop its files from the root barrel.

|          |                                                        |
| -------: | :----------------------------------------------------- |
|    Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Default: | `{ type: 'named' }`                                    |

A plugin with no `output.barrel` of its own inherits `config.output.barrel`, which itself falls back to `{ type: 'named' }`.

### type

Export style for the barrel files. Required whenever `output.barrel` is set to an object.

- `'named'` (default) re-exports each symbol by name from the file's named exports. Best for tree-shaking and explicit imports.
- `'all'` uses `export *`, a smaller barrel that re-exports everything.

|          |                    |
| -------: | :----------------- |
|    Type: | `'all' \| 'named'` |
| Default: | `'named'`          |

::: code-group

```typescript ['named' (default)]
// src/gen/index.ts
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript ['all']
// src/gen/index.ts
export * from './api/user'
export * from './api/post'
export * from './api/types/User'
```

:::

### nested

Changes what each barrel references. A barrel is written for every directory either way. With `nested: false`, the plugin's top barrel reaches through to the leaf files. With `nested: true`, each barrel re-exports only what sits directly inside its directory, including the subdirectory barrels below it, so callers can import from any depth. This field works on a plugin's `output.barrel` only.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |
| Default: | `false`   |

::: code-group

```typescript [nested: false (default) → barrels reference leaf files]
// src/gen/api/index.ts
export * from './user'
export * from './post'
export * from './types/User'

// src/gen/api/types/index.ts
export * from './User'
```

```typescript [nested: true → barrels reference sub-barrels]
// src/gen/api/index.ts re-exports its files and subdirectories
export * from './user'
export * from './post'
export * from './types'

// src/gen/api/types/index.ts re-exports its files
export * from './User'
```

:::
