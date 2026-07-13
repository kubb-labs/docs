---
layout: doc
title: Plugins - Build Custom Generators for Any Spec
description: Build Kubb plugins that hook into the lifecycle, register generators, declare resolvers, and emit files. The hook-style definePlugin API mirrors Astro integrations.
outline: deep
---

# Plugins

A plugin teaches Kubb to generate something new. It owns its file naming, its output folder, the lifecycle hooks it listens to, and the [generators](/docs/5.x/reference/kit/generators) that walk the [AST](/docs/5.x/guide/concepts/ast) and emit files. Almost everything you see in a generated `src/gen/` folder traces back to one plugin or another, so understanding how plugins behave explains how Kubb behaves.

This page is about the idea: what a plugin is, how its lifecycle runs, and how plugins work together. For the signatures (`definePlugin`, `defineGenerator`, `createResolver`, and the context tables) see the [Kit API](/docs/5.x/reference/kit). When you want to build one step by step, follow [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins).

<PluginAnatomy />

> [!TIP]
> Need a TanStack Query client, a Zod schema set, or MSW handlers? Check the [Plugins](/plugins) registry first. Build a custom plugin only when no existing one fits.

## What a plugin is

A plugin is a factory. You call it in `kubb.config.ts`, and it returns an object with a `name` and a `hooks` map. The name identifies the plugin to the rest of the system, and the hooks decide which moments of a build the plugin cares about.

Each plugin keeps to its own corner. It registers generators that walk the AST, declares a resolver that names and places its files, and reads only the options it was given. That isolation is what makes a Kubb build predictable: the TypeScript plugin never reaches into the Zod plugin's state, and either one can be added or removed without touching the other.

## How the lifecycle runs

A build moves through phases in a fixed order, and plugins subscribe to the moments that matter to them. The run opens with lifecycle and generation events, then enters the part most plugins live in: setup, the per-node walk, and the closing events.

<LifecycleTimeline />

During setup, every plugin wires itself in once, before any code is generated. That makes setup the place to validate input and fail fast when a required option is missing.

Then Kubb walks the AST, calling each plugin's generator handlers for every schema and operation node. Generators return `FileNode`s during this phase, which is where the bulk of the output is produced.

When a plugin's generators finish, it gets a closing event with a snapshot of the files it produced. After every plugin has finished, a final event fires before anything is written to disk, which is the spot to inject aggregate files. Writing, formatting, and linting follow. The full event list, with the context each one carries, lives in the [Kit API](/docs/5.x/reference/kit).

## How plugins compose

Plugins rarely work alone. A client plugin leans on the types a TypeScript plugin already generated, and a mock plugin reuses the same schemas. Kubb gives them two ways to cooperate without hard-coding paths or guessing at order:

- Dependencies let a plugin name the other plugins it needs. Kubb runs those first and fails the build with a clear error when one is missing, so you never order the `plugins` array by hand.
- Resolvers let a plugin read where another plugin's files live and what they are named. A generator asks for a sibling's resolver by plugin name and gets the same paths the owner would produce, so the two stay in sync even when naming rules change.

## Post-enforced plugins

Most plugins run in a normal pass, but some need to see what everyone else produced first. A barrel generator, for example, can only write its index files once the other plugins have emitted the files it re-exports. Setting `enforce: 'post'` moves a plugin to the end of every event it listens to, after the normal plugins have run.

There is a matching `enforce: 'pre'` for plugins that need to run ahead of the pack. Both are about ordering relative to normal plugins, and neither overrides dependencies: a declared dependency always runs first. [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) is the canonical post-enforced plugin to read when this pattern fits your case.

## Built-in plugins

The Kubb monorepo ships official plugins for the most common cases. Browse them in the [Plugins registry](/plugins).

| Plugin                                                    | Generates                        |
| --------------------------------------------------------- | -------------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts/)                   | TypeScript types from your spec. |
| [`@kubb/plugin-zod`](/plugins/plugin-zod/)                 | Zod schemas.                     |
| [`@kubb/plugin-axios`](/plugins/plugin-axios/)             | Type-safe axios client functions. |
| [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)             | Type-safe Fetch client functions. |
| [`@kubb/plugin-react-query`](/plugins/plugin-react-query/) | React Query (TanStack) hooks.    |
| [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/)     | Vue Query (TanStack) hooks.      |
| [`@kubb/plugin-msw`](/plugins/plugin-msw/)                 | MSW request handlers.            |
| [`@kubb/plugin-faker`](/plugins/plugin-faker/)             | Faker-based mock data.           |
| [`@kubb/plugin-cypress`](/plugins/plugin-cypress/)         | Cypress request helpers.         |
| [`@kubb/plugin-mcp`](/plugins/plugin-mcp/)                 | MCP tool definitions.            |
| [`@kubb/plugin-redoc`](/plugins/plugin-redoc/)             | Redoc API documentation.         |

## Next steps

To build a plugin of your own, work through [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins). For the exact shape of `definePlugin`, `defineGenerator`, `createResolver`, and the context passed to each hook, read the [Kit API](/docs/5.x/reference/kit). To retune the names and file paths a plugin produces without writing one, see [Override a resolver](/docs/5.x/guide/going-further/resolvers).
