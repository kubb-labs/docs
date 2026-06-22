---
layout: doc
title: Kubb vs orval, HeyAPI, and openapi-typescript
description: Feature-by-feature comparison of Kubb against orval, HeyAPI, and openapi-typescript.
outline: [2, 3]
---

# Kubb vs orval, HeyAPI, and openapi-typescript

Kubb, [orval](https://orval.dev), [HeyAPI](https://heyapi.dev), and [openapi-typescript](https://openapi-ts.dev) all generate code from OpenAPI specs. The table below maps each Kubb plugin and adapter to the equivalent support in every tool.

We keep this comparison accurate and fair. If you use one of these tools and think a row is wrong, open an issue or pull request in [kubb-labs/kubb](https://github.com/kubb-labs/kubb/issues) with notes or evidence.

## Plugin and feature coverage

**Legend**

- ✅ Built in and ready to use with no extra configuration.
- 🟡 Supported through a third-party or community plugin.
- 🔶 Supported and documented, but needs extra user code.
- 🛑 Not officially supported or documented.

| Feature                                                    |       Kubb        | orval | HeyAPI            |    openapi-ts    |
| ---------------------------------------------------------- | :---------------: | :---: | :---------------- | :--------------: |
| [OpenAPI 2.0, 3.0, 3.1 input](/adapters/adapter-oas)       |        ✅         |  ✅   | ✅                |        ✅        |
| [TypeScript types](/plugins/plugin-ts)                     |        ✅         |  ✅   | ✅                |        ✅        |
| [HTTP client (Axios, Fetch)](/plugins/plugin-axios)        |        ✅         |  ✅   | ✅                | 🔶<sup>2</sup>  |
| [React Query hooks](/plugins/plugin-react-query)           |        ✅         |  ✅   | ✅                |       🛑        |
| [Vue Query composables](/plugins/plugin-vue-query)         |        ✅         |  ✅   | ✅                |       🛑        |
| [SWR hooks](/plugins/plugin-swr)                           |        ✅         |  ✅   | 🛑<sup>3</sup>    | 🟡<sup>4</sup>  |
| [Zod validation schemas](/plugins/plugin-zod)              |        ✅         |  ✅   | ✅<sup>1</sup>    |       🛑        |
| [MSW request handlers](/plugins/plugin-msw)                |        ✅         |  ✅   | 🛑                |       🛑        |
| [Faker.js mock data](/plugins/plugin-faker)                |        ✅         | 🔶<sup>5</sup> | 🛑           |       🛑        |
| [Cypress E2E tests](/plugins/plugin-cypress)               |        ✅         |  🛑   | 🛑                |       🛑        |
| [MCP server](/plugins/plugin-mcp)                          |        ✅         |  🛑   | 🛑                |       🛑        |
| [Redoc API documentation](/plugins/plugin-redoc)           |        ✅         |  🛑   | 🛑                |       🛑        |
| [Barrel index files](/plugins/plugin-barrel)               |        ✅         |  🛑   | 🛑                |       🛑        |

**Notes**

1. HeyAPI also generates Valibot schemas in addition to Zod.
2. openapi-typescript generates types only. Its companion `openapi-fetch` runtime provides the typed client, so a client is not generated per operation. Note that `openapi-fetch` is in [feature-freeze and is largely considered deprecated](https://github.com/openapi-ts/openapi-typescript/discussions/2559).
3. HeyAPI lists SWR as a [roadmap proposal](https://github.com/hey-api/openapi-ts/issues/1479) that has not started yet.
4. openapi-typescript relies on the community [`swr-openapi`](https://github.com/htunnicliff/swr-openapi) package, maintained outside the core project.
5. orval does not emit a standalone Faker output, but it populates its MSW request handlers with `faker`-generated mock data.

## What sets Kubb apart

### Plugin architecture

Every output is a separate [plugin](/docs/5.x/concepts/plugins), so you add only what you need. The plugins run against a shared [AST](/docs/5.x/concepts/ast). The spec is parsed once, and naming stays consistent across every output.

### Custom adapters and parsers

A [custom adapter](/docs/5.x/concepts/adapters) swaps `adapterOas` for another input format such as AsyncAPI, GraphQL, or JSON Schema. A [custom parser](/docs/5.x/concepts/parsers) targets another output language such as Python, Kotlin, or Rust. Neither orval nor HeyAPI supports either one. Combine custom adapters, parsers, and plugins in one pipeline, and Kubb reaches inputs and outputs the others cannot.

### Post-enforced plugins

Plugins with `enforce: 'post'` run after every regular plugin finishes. They handle cross-cutting work like barrel files and manifests without touching each plugin. [`@kubb/plugin-barrel`](/plugins/plugin-barrel) works this way.

### Bundler integration

[`unplugin-kubb`](/docs/5.x/integrations/) runs generation inside Vite, Rollup, Rolldown, Webpack, Rspack, esbuild, Farm, Nuxt, and Astro. HeyAPI ships a Vite-only plugin. orval has no bundler integration.

## When not to use Kubb

- You consume only a few endpoints that rarely change.
- You do not have an OpenAPI spec and do not plan to write one.
- You need codegen for a non-OpenAPI format today and do not want to write a custom adapter.
