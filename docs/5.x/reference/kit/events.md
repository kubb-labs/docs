---
layout: doc
title: Lifecycle events
description: Every kubb:* event a build emits, the payload each carries, and the order they fire in. Listen with kubb.hooks.hook(name, handler) or from a plugin's hooks map.
outline: [2, 3]
---

# Lifecycle events

Kubb runs on one shared, typed event emitter, and every phase of a build emits a `kubb:*` event on it. Plugins subscribe through their [`hooks`](./plugins) map. Outside code subscribes through `kubb.hooks`.

The event names and their payloads are the `KubbHooks` type. Handlers may be async, and Kubb awaits each one before moving on.

## Listening

Attach a listener with `kubb.hooks.hook(name, handler)` before you run the build. A plugin listens by adding the event to its `hooks` map instead.

```ts
import { createKubb } from 'kubb'

const kubb = createKubb({
  input: './petStore.yaml',
  output: { path: './gen' },
})

kubb.hooks.hook('kubb:plugin:end', ({ plugin, duration }) => {
  console.log(`${plugin.name} finished in ${duration}ms`)
})

kubb.hooks.hook('kubb:build:end', ({ files }) => {
  console.log(`Generated ${files.length} files`)
})

await kubb.build()
```

## What emits which events

The events split into two groups by where they come from. Build pipeline events fire whenever the pipeline runs, including a direct [`.build()` or `.safeBuild()`](./engine#createkubb): `kubb:build:*`, `kubb:plugin:*`, `kubb:plugins:end`, `kubb:generate:*`, and `kubb:files:processing:*`. Generation-run events wrap the pipeline with setup and the output passes, so they fire only during a full generation run, which the CLI, the bundler plugin, and the MCP tool drive: `kubb:generation:*`, `kubb:setup:*`, `kubb:format:*`, `kubb:lint:*`, and `kubb:hooks:*` / `kubb:hook:*`. `kubb:lifecycle:*` wraps the whole run and comes from the bundler plugin.

The messaging events (`kubb:info`, `kubb:success`, `kubb:warn`, `kubb:error`, `kubb:diagnostic`) can fire at any point.

## Firing order

For a full generation run the events fire in this order:

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

See the [lifecycle timeline](/docs/5.x/guide/concepts/plugins#how-the-lifecycle-runs) for the same sequence as prose.

## Generation run

These wrap a full run. A direct `.build()` or `.safeBuild()` does not fire them.

| Event                    | Payload                                                        | When it fires                                          |
| ------------------------ | ------------------------------------------------------------- | ------------------------------------------------------ |
| `kubb:lifecycle:start`   | `{ version }`                                                 | The bundler plugin starts, before anything else        |
| `kubb:generation:start`  | `{ config }`                                                  | A run begins, before setup                             |
| `kubb:setup:start`       | none                                                          | Before the driver and storage are initialized          |
| `kubb:setup:end`         | none                                                          | After setup, before the build pipeline                 |
| `kubb:generation:end`    | `{ config, storage, status, diagnostics, filesCreated, hrStart }` | The run finishes, after the output passes         |
| `kubb:lifecycle:end`     | none                                                          | The bundler plugin is done                             |

## Build pipeline

These come from the pipeline itself, so a direct `.build()` or `.safeBuild()` fires them too.

| Event                    | Payload                                                        | When it fires                                          |
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

| Event                | Payload                              | When it fires                                    |
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

| Event             | Payload                     | When it fires                                        |
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
