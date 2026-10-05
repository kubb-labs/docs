---
layout: doc
title: Extend and publish a plugin
description: Add options and dependencies to a Kubb plugin, then package it for npm.
outline:
  - 2
  - 3
order: 6
---

# Extend and publish a plugin

Start with an existing plugin factory, such as the one in [Create your first plugin](/docs/5.x/tutorials/creating-plugins). Check the [plugin catalogue](/plugins) before building an output that already exists.

## Add options or dependencies

Use `PluginFactoryOptions` to type user options and their resolved values. Apply defaults in the plugin factory and store resolved options with `ctx.setOptions`. Generators read them from the plugin context. See [Plugin reference](/docs/5.x/reference/kit/plugins).

Declare `dependencies` when another plugin must run first. In the generator, call `ctx.requirePlugin(name)` to require it and `ctx.getResolver(name)` to reuse its names and paths. Missing dependencies fail when requested, not during ordering.

For identifier or file naming, adjust your resolver. Users override its defaults through their plugin configuration. See [Override a resolver](/docs/5.x/how-to/resolvers).

Use a generator’s `schema` handler for reusable schemas or `operations` for a single file covering the whole operation set. See [Generator reference](/docs/5.x/reference/kit/generators) for context properties and return types.

## Check build errors

`build()` throws on errors. Use `safeBuild()` to inspect diagnostics without throwing, then check `Diagnostics.hasError`. See [Engine reference](/docs/5.x/reference/kit/engine) and [Testing helpers](/docs/5.x/reference/kit/testing).

## Publish

Use `kubb-plugin-<name>` for the npm package, `plugin-<name>` for the internal name, and `plugin<Name>` for its factory. Export the factory from `src/index.ts`.

Keep generators and resolvers in separate folders as the plugin grows. Official [plugin source](https://github.com/kubb-labs/plugins) provides examples.

Build TypeScript declarations and JavaScript into `dist`. Configure the package entrypoints and dependencies:

```json [package.json]
{
  "name": "kubb-plugin-example",
  "version": "1.0.0",
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "peerDependencies": { "kubb": "^5.0.0" },
  "devDependencies": { "kubb": "^5.0.0" }
}
```

Before publishing, compile the package, run its tests, and document installation and usage in the README. Then run `npm publish --access public` from the package directory.

## See also

- [Plugin API](/docs/5.x/reference/kit/plugins)
- [Lifecycle hooks](/docs/5.x/reference/kit/hooks)
