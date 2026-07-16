---
layout: doc
title: Lifecycle hooks
description: Every kubb:* hook a build fires, the payload each carries, and the order they fire in. Listen with kubb.hooks.hook(name, handler) or from a plugin's hooks map.
outline: [2, 3]
---

# Lifecycle hooks

Kubb runs on one shared, typed hook emitter, and every phase of a build fires a `kubb:*` hook on it. Plugins subscribe through their [`hooks`](./plugins) map. Outside code subscribes through `kubb.hooks`.

The hook names and their payloads are the `KubbHooks` type. Handlers may be async, and Kubb awaits each one before moving on.

## Listening

Subscribe to `kubb.hooks` before you call `build()` to trace plugin activity or collect metrics. A plugin listens by adding the hook to its [`hooks`](./plugins) map instead. Each hook receives one typed context object.

```typescript twoslash [lifecycle.ts]
import { createKubb } from 'kubb'
import { definePlugin } from 'kubb/kit'
import { adapterOas } from '@kubb/adapter-oas'

const kubb = createKubb({
  input: './petStore.yaml',
  output: { path: './gen' },
  adapter: adapterOas(),
  plugins: [definePlugin(() => ({ name: 'plugin-example', hooks: {} }))()],
})

// kubb:plugin:end receives a single KubbPluginEndContext, not two separate arguments.
kubb.hooks.hook('kubb:plugin:end', ({ plugin, duration, success }) => {
  console.log(`[${plugin.name}] finished in ${duration}ms (ok=${success})`)
})

// kubb:files:processing:update fires once per flush batch with an array of per-file updates.
kubb.hooks.hook('kubb:files:processing:update', ({ files }) => {
  for (const { file, processed, total, percentage } of files) {
    console.log(`[${processed}/${total}] (${percentage.toFixed(0)}%) ${file.path}`)
  }
})

await kubb.build()
```

## What fires which hooks

The hooks split into two groups by where they come from. Build pipeline hooks fire whenever the pipeline runs, including a direct [`.build()` or `.safeBuild()`](./engine#createkubb): `kubb:build:*`, `kubb:plugin:*`, `kubb:plugins:end`, `kubb:generate:*`, and `kubb:files:processing:*`. Generation-run hooks wrap the pipeline with setup and the output passes, so they fire only during a full generation run, which the CLI, the bundler plugin, and the MCP tool drive: `kubb:generation:*`, `kubb:setup:*`, `kubb:format:*`, `kubb:lint:*`, and `kubb:hooks:*` / `kubb:hook:*`. `kubb:lifecycle:*` wraps the whole run and comes from the bundler plugin.

The messaging hooks (`kubb:info`, `kubb:success`, `kubb:warn`, `kubb:error`, `kubb:diagnostic`) can fire at any point.

## Firing order

<LifecycleTimeline />

For a full generation run the hooks fire in this order:

1. `kubb:lifecycle:start` (bundler plugin only)
2. `kubb:generation:start`
3. `kubb:setup:start` → setup, one `kubb:plugin:setup` per plugin → `kubb:setup:end`
4. `kubb:build:start`
5. per plugin: `kubb:plugin:start` → generator hooks (`kubb:generate:schema` / `kubb:generate:operation` / `kubb:generate:operations`) → `kubb:plugin:end`
6. `kubb:plugins:end`
7. `kubb:files:processing:start` → `kubb:files:processing:update` → `kubb:files:processing:end`
8. `kubb:build:end`
9. output passes: `kubb:format:start` / `:end`, `kubb:lint:start` / `:end`, then `kubb:hooks:start` → `kubb:hook:start` / `:line` / `:end` → `kubb:hooks:end`
10. `kubb:generation:end`
11. `kubb:lifecycle:end` (bundler plugin only)

## Generation run

These wrap a full run. A direct `.build()` or `.safeBuild()` does not fire them.

| Hook                     | Payload                                                        | When it fires                                          |
| ------------------------ | ------------------------------------------------------------- | ------------------------------------------------------ |
| `kubb:lifecycle:start`   | `{ version }`                                                 | The bundler plugin starts, before anything else        |
| `kubb:generation:start`  | `{ config }`                                                  | A run begins, before setup                             |
| `kubb:setup:start`       | none                                                          | Before the driver and storage are initialized          |
| `kubb:setup:end`         | none                                                          | After setup, before the build pipeline                 |
| `kubb:generation:end`    | `{ config, storage, status, diagnostics, filesCreated, hrStart }` | The run finishes, after the output passes         |
| `kubb:lifecycle:end`     | none                                                          | The bundler plugin is done                             |

## Build pipeline

These come from the pipeline itself, so a direct `.build()` or `.safeBuild()` fires them too.

| Hook                     | Payload                                                        | When it fires                                          |
| ------------------------ | ------------------------------------------------------------- | ------------------------------------------------------ |
| `kubb:plugin:setup`      | `KubbPluginSetupContext`                                      | Once per plugin during setup, to register generators, resolvers, macros, and options |
| `kubb:build:start`       | `{ config, adapter, meta, getPlugin, files, upsertFile }`     | The AST is ready, before plugins run. Skipped when no adapter parsed input |
| `kubb:plugin:start`      | `{ plugin }`                                                  | Before a plugin's generators run                       |
| `kubb:generate:schema`   | `(node, ctx)`                                                 | For each schema node the adapter produced              |
| `kubb:generate:operation`| `(node, ctx)`                                                 | For each operation node                                |
| `kubb:generate:operations`| `(nodes, ctx)`                                               | Once with every operation node                         |
| `kubb:plugin:end`        | `{ plugin, duration, success, error, config, files, upsertFile }` | After a plugin finishes, with its timing and a file snapshot |
| `kubb:plugins:end`       | `{ config, files, upsertFile }`                              | After every plugin has generated, before files hit disk. The spot to add aggregate files like a barrel |
| `kubb:files:processing:start` | `{ files }`                                             | Before the batch of generated files is written         |
| `kubb:files:processing:update`| `{ files }`                                             | As files are written                                   |
| `kubb:files:processing:end` | `{ files }`                                               | After the batch is written                             |
| `kubb:build:end`         | `{ files, config, outputDir }`                               | After every file is written                            |

## Output passes

These run after a successful build, only during a full generation run.

| Hook                 | Payload                              | When it fires                                    |
| -------------------- | ------------------------------------ | ------------------------------------------------ |
| `kubb:format:start`  | none                                 | Before the formatter runs                        |
| `kubb:format:end`    | none                                 | After formatting                                 |
| `kubb:lint:start`    | none                                 | Before the linter runs                           |
| `kubb:lint:end`      | none                                 | After linting                                    |
| `kubb:hooks:start`   | none                                 | Before the `postGenerate` commands run           |
| `kubb:hook:start`    | `{ id, command, name, args }`        | Before one `postGenerate` command runs           |
| `kubb:hook:line`     | `KubbHookLineContext`                | For each output line a `postGenerate` command emits |
| `kubb:hook:end`      | `KubbHookEndContext`                 | After one `postGenerate` command finishes        |
| `kubb:hooks:end`     | none                                 | After every `postGenerate` command               |

## Messaging

These carry log messages and diagnostics, and can fire at any point in a run.

| Hook              | Payload                     | When it fires                                        |
| ----------------- | --------------------------- | ---------------------------------------------------- |
| `kubb:info`       | `{ message, info }`         | An informational message                             |
| `kubb:success`    | `{ message, info }`         | A step completed successfully                        |
| `kubb:warn`       | `{ message, info }`         | A non-fatal problem                                  |
| `kubb:error`      | `{ error, meta }`           | An unstructured error, so its stack survives         |
| `kubb:diagnostic` | `{ diagnostic }`            | A structured [diagnostic](../diagnostics) (warning, info, or an update notice) |

## Related

- [Plugins](./plugins) for the plugin `hooks` map and `KubbPluginSetupContext`
- [Engine and configuration](./engine) for `createKubb`, `.build()`, and `.safeBuild()`
- [Plugin concepts](/docs/5.x/guide/concepts/plugins#how-the-lifecycle-runs) for the lifecycle as prose
- [Diagnostics](../diagnostics) for the shape of `kubb:diagnostic` payloads
