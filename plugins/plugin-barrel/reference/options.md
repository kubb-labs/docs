---
layout: doc
title: Options
description: All configuration options for @kubb/plugin-barrel.
outline: deep
---

# Options

### output.barrel

Sets the re-export style for barrel files. `pluginBarrel` takes no arguments. You configure it through `output.barrel` instead. Set it on `defineConfig` to control the root barrel and the default every plugin inherits. Set it on a single plugin to override that plugin's barrel.

The `type` field picks the export style. `{ type: 'named' }` writes `export { Foo, Bar } from '...'` from each file's named exports. `{ type: 'all' }` writes `export * from '...'` for every file. `false` turns off barrel generation.

A plugin's `output.barrel` also accepts `nested`. With `nested: true` the plugin writes an `index.ts` in every subdirectory, each re-exporting only what sits directly inside it. The root `output.barrel` has no `nested` field, so it always stays flat.

Set `barrel: false` on `defineConfig` to disable only the root barrel. Each plugin still emits its own. Set `barrel: false` on a plugin to disable that plugin's barrel and drop its files from the root barrel.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'all' \| 'named', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

> [!NOTE]
> `nested` is plugin-level only and defaults to `false`. The config-level value drops it, so the root barrel type is `{ type: 'all' \| 'named' } \| false`.

#### type

Export style for the barrel files.

|           |                    |
| --------: | :----------------- |
|     Type: | `'all' \| 'named'` |
| Required: | `true`             |
|  Default: | `'named'`          |

::: code-group

```typescript ['named' (default) → src/gen/index.ts]
export { getUser, User } from './api/user'
export { getPost, Post } from './api/post'
export { User } from './api/types/User'
```

```typescript ['all' → src/gen/index.ts]
export * from './api/user'
export * from './api/post'
export * from './api/types/User'
```

:::

#### nested

Writes an `index.ts` in every subdirectory instead of one flat root barrel. Each one re-exports only what sits directly inside it. This field works on a plugin's `output.barrel` only.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

