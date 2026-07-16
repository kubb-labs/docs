---
layout: doc
title: Plugins - Build Custom Generators for Any Spec
description: Build Kubb plugins that hook into the lifecycle, register generators, declare resolvers, and emit files. The hook-style definePlugin API mirrors Astro integrations.
outline: deep
---

# Plugins

A plugin teaches Kubb to generate something new. It owns:

- its file naming and output folder
- the lifecycle hooks it listens to
- the [generators](/docs/5.x/reference/kit/generators) that walk the [AST](/docs/5.x/guide/concepts/ast) and emit files

Almost everything in a generated `src/gen/` folder traces back to one plugin, so how plugins behave is how Kubb behaves.

This page covers the idea: what a plugin is, how its lifecycle runs, and how plugins compose. For the signatures see the [Kit API](/docs/5.x/reference/kit), and to build one step by step follow [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins).

<PluginAnatomy />

> [!TIP]
> Need a TanStack Query client, a Zod schema set, or MSW handlers? Check the [Plugins](/plugins) registry first. Build a custom plugin only when no existing one fits.

## What a plugin is

A plugin is a factory. You call it in `kubb.config.ts`, and it returns an object with a `name` and a `hooks` map. The name identifies it, and the hooks decide which moments of a build it cares about.

Each plugin keeps to its own corner:

- registers generators that walk the AST
- declares a resolver that names and places its files
- reads only the options it was given

That isolation is what makes a build predictable. The TypeScript plugin never touches the Zod plugin's state, and either one drops in or out without disturbing the other.

## How the lifecycle runs

A build moves through phases in a fixed order, and each plugin subscribes only to the moments it cares about.

<LifecycleTimeline />

- Setup runs first, once per plugin, before any code exists. Validate options here and fail fast on a missing one.
- Kubb walks the AST and calls your generator handlers for every schema and operation node. Most `FileNode`s come from here.
- A closing event hands each plugin a snapshot of what it produced.
- One last event fires before anything hits disk, the spot to add aggregate files like a barrel.
- Writing, formatting, and linting follow.

The [lifecycle hooks reference](/docs/5.x/reference/kit/hooks) lists every hook, its payload, and when it fires.

## How plugins compose

Plugins rarely work alone. A client plugin leans on the types a TypeScript plugin already generated, and a mock plugin reuses the same schemas. Kubb gives them two ways to cooperate without hard-coding paths or guessing at order:

- Dependencies let a plugin name the other plugins it needs. Kubb runs those first and fails the build with a clear error when one is missing, so you never order the `plugins` array by hand.
- [Resolvers](/docs/5.x/guide/concepts/resolvers) let a plugin read another plugin's file names and paths by plugin name, so imports stay correct even when naming rules change.

## Post-enforced plugins

Most plugins run in one normal pass, but some need to see what everyone else produced first. A barrel generator can only write its index files once the other plugins have emitted what it re-exports. `enforce: 'post'` moves a plugin to the end of every event it listens to, and `enforce: 'pre'` moves it to the front. Neither overrides dependencies: a declared dependency always runs first. [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) is the one to read when this fits your case.

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
