---
layout: doc
title: FAQ
description: Frequently asked questions about Kubb, covering compatibility, generated code, customization, and plugins.
outline: [2, 3]
---

# FAQ

If your question isn't here, ask in [Discord](https://discord.gg/shfBFeczrm) or open a [GitHub issue](https://github.com/kubb-labs/kubb/issues).

## General

### Who should use Kubb?

Use Kubb when you need more than types from a spec. It generates clients, hooks, validators, and mocks in one run. It fits monorepos and any project where keeping generated code in sync by hand has become a chore.

### Is Kubb production-ready?

Yes. The generated code is plain TypeScript. It has no runtime dependency on Kubb, no decorators, and no framework lock-in.

### Is Kubb free and open source?

Yes. [MIT license](https://github.com/kubb-labs/kubb/blob/main/LICENSE), developed in the open on [GitHub](https://github.com/kubb-labs/kubb).

## Compatibility

### Does Kubb work with JavaScript projects?

Yes. Kubb generates TypeScript. You can consume the output directly in a JavaScript project or transpile it as part of your build.

### Can I use Kubb with GraphQL?

Not out of the box. The default [adapter](/docs/5.x/guide/concepts/adapters) targets OpenAPI/Swagger. For GraphQL, use [GraphQL Code Generator](https://the-guild.dev/graphql/codegen). A custom adapter can handle any format, but writing one takes real work.

### What Node.js version is required?

Node.js 22 or higher. The CLI and config file are ESM-native.

### Does Kubb support Bun or Deno?

The CLI and generated code run on Bun with no extra configuration. Deno isn't officially tested.

## Using Kubb

### How do I update generated code when my API changes?

Re-run `kubb generate`. Use the [`clean`](/docs/5.x/reference/configuration#output-clean) option to remove stale files before each run.

```shell [Terminal]
npx kubb@beta generate
```

### Do I commit generated files to Git?

Either way works. Many teams commit the generated code so CI can skip regeneration. Others add the output directory to `.gitignore` and generate during CI.

### Can I customize the generated code?

Yes. Each plugin exposes a `resolver` option to rename operations and types, and a `macros` option to rewrite AST nodes before they are written to disk. For deeper control, write a [custom plugin](/docs/5.x/guide/going-further/creating-plugins).

### Can I run multiple configs in one command?

Yes. Pass an array to `defineConfig`. Each entry has its own `input`, `output`, and `plugins`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig([
  { input: { path: './specs/users.yaml' }, output: { path: './src/gen/users' }, plugins: [] },
  { input: { path: './specs/orders.yaml' }, output: { path: './src/gen/orders' }, plugins: [] },
])
```

### Does Kubb work inside a bundler (Vite, webpack, etc.)?

Yes. [`unplugin-kubb`](/docs/5.x/guide/integrations/) integrates Kubb into Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt, and Astro.

### Can I run Kubb in CI?

Yes. `kubb generate` is a standard Node.js command. Set `DO_NOT_TRACK=1` to silence telemetry.

### How do I disable telemetry?

Set `DO_NOT_TRACK=1` or `KUBB_DISABLE_TELEMETRY=1`. See [Telemetry](/docs/5.x/reference/telemetry) for details.

## Plugins

### Do I need to install every plugin?

No. Each plugin is an independent npm package. Install only what you need.

### Can I write a custom plugin?

Yes. Use `definePlugin` from `@kubb/core`. The [Creating Your First Plugin](/docs/5.x/guide/going-further/creating-plugins) guide walks through a full example.

### Where can I find all available plugins?

The [Plugins registry](/plugins) lists every official and community plugin.
