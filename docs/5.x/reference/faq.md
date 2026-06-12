---
layout: doc
title: FAQ
description: Frequently asked questions about Kubb, covering compatibility, generated code, customization, and plugins.
outline: [2, 3]
---

# FAQ

If your question isn't listed here, ask in [Discord](https://discord.gg/shfBFeczrm) or open a [GitHub issue](https://github.com/kubb-labs/kubb/issues).

## General

### Who should use Kubb?

Kubb is a good fit when you need more than just types from a spec: clients, hooks, validators, and mocks in one run. It works well in monorepos and any project where keeping generated code in sync manually is a burden.

### Is Kubb production-ready?

Yes. The generated code is plain TypeScript with no runtime dependency on Kubb. No decorators, no magic base classes, no framework lock-in.

### Is Kubb free and open source?

Yes. [MIT license](https://github.com/kubb-labs/kubb/blob/main/LICENSE), developed in the open on [GitHub](https://github.com/kubb-labs/kubb).

## Compatibility

### Does Kubb work with JavaScript projects?

Yes. Kubb generates TypeScript, but you can use it in JavaScript projects directly or transpile the output as part of your build.

### Can I use Kubb with GraphQL?

Not out of the box. The default [adapter](/docs/5.x/concepts/adapters) targets OpenAPI/Swagger. For GraphQL, consider [GraphQL Code Generator](https://the-guild.dev/graphql/codegen). You can write a custom adapter for any format, but that requires significant effort.

### What Node.js version is required?

**Node.js 22 or higher.** The CLI and config file are ESM-native.

### Does Kubb support Bun or Deno?

The CLI and generated code run on **Bun** without extra configuration. Deno is not officially tested.

## Using Kubb

### How do I update generated code when my API changes?

Re-run `kubb generate`. Use the [`clean`](/docs/5.x/reference/configuration#output-clean) option to remove stale files before each run.

```sh
npx kubb generate
```

### Do I commit generated files to Git?

Both approaches work. Many teams commit generated code so CI skips re-generation. Others add the output directory to `.gitignore` and generate during CI.

### Can I customize the generated code?

Yes. Each plugin exposes a `resolver` option to rename operations and types, and a `transformer` option to modify AST nodes before they are written to disk. For deeper control, write a [custom plugin](/docs/5.x/guides/creating-plugins).

### Can I run multiple configs in one command?

Yes. Pass an array to `defineConfig`. Each entry has its own `input`, `output`, and `plugins`.

```ts [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig([
  { input: { path: './specs/users.yaml' }, output: { path: './src/gen/users' }, plugins: [] },
  { input: { path: './specs/orders.yaml' }, output: { path: './src/gen/orders' }, plugins: [] },
])
```

### Does Kubb work inside a bundler (Vite, webpack, etc.)?

Yes. [`unplugin-kubb`](/docs/5.x/integrations/) integrates Kubb into Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt, and Astro.

### Can I run Kubb in CI?

Yes. `kubb generate` is a standard Node.js command. Set `DO_NOT_TRACK=1` to silence telemetry.

### How do I disable telemetry?

Set `DO_NOT_TRACK=1` or `KUBB_DISABLE_TELEMETRY=1`. See [Telemetry](/docs/5.x/reference/telemetry) for details.

## Plugins

### Do I need to install every plugin?

No. Each plugin is an independent npm package. Install only what you need.

### Can I write a custom plugin?

Yes. Use `definePlugin` from `@kubb/core`. The [Creating Your First Plugin](/docs/5.x/guides/creating-plugins) guide walks through a complete example.

### Where can I find all available plugins?

The [Plugins registry](/plugins) lists all official and community plugins.
