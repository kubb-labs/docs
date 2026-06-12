---
layout: doc
title: Kubb vs orval, HeyAPI, and openapi-typescript
description: Feature-by-feature comparison of Kubb against orval, HeyAPI, and openapi-typescript.
outline: [2, 3]
---

# Kubb vs orval, HeyAPI, and openapi-typescript

Kubb, [orval](https://orval.dev), [HeyAPI](https://heyapi.dev), and [openapi-typescript](https://openapi-ts.dev) all generate code from OpenAPI specs. The table below maps each Kubb plugin and adapter to the equivalent support in every tool.

This comparison strives to be as accurate and unbiased as possible. If you use any of these tools and believe a row could be improved, open an issue or pull request in [kubb-labs/kubb](https://github.com/kubb-labs/kubb/issues) with notes or evidence.

## Plugin and feature coverage

**Legend**

- ✅ First-class, built-in, and ready to use with no added configuration.
- 🟡 Supported through a third-party or community plugin.
- 🔶 Supported and documented, but requires extra user code.
- 🛑 Not officially supported or documented.

| Feature                                                    |       Kubb        | orval | HeyAPI            |    openapi-ts    |
| ---------------------------------------------------------- | :---------------: | :---: | :---------------- | :--------------: |
| [OpenAPI 2.0, 3.0, 3.1 input](/adapters/adapter-oas)       |        ✅         |  ✅   | ✅                |        ✅        |
| [TypeScript types](/plugins/plugin-ts)                     |        ✅         |  ✅   | ✅                |        ✅        |
| [HTTP client (Axios, Fetch)](/plugins/plugin-client)       |        ✅         |  ✅   | ✅                | 🔶<sup>3</sup>  |
| [React Query hooks](/plugins/plugin-react-query)           |  ✅<sup>1</sup>   |  ✅   | ✅<sup>1</sup>    |       🛑        |
| [Vue Query composables](/plugins/plugin-vue-query)         |  ✅<sup>1</sup>   |  ✅   | ✅<sup>1</sup>    |       🛑        |
| [Zod validation schemas](/plugins/plugin-zod)              |        ✅         |  ✅   | ✅<sup>2</sup>    |       🛑        |
| [MSW request handlers](/plugins/plugin-msw)                |        ✅         |  ✅   | 🛑                |       🛑        |
| [Faker.js mock data](/plugins/plugin-faker)                |        ✅         |  🛑   | 🛑                |       🛑        |
| [Cypress E2E tests](/plugins/plugin-cypress)               |        ✅         |  🛑   | 🛑                |       🛑        |
| [MCP server](/plugins/plugin-mcp)                          |        ✅         |  🛑   | 🛑                |       🛑        |
| [Redoc API documentation](/plugins/plugin-redoc)           |        ✅         |  🛑   | 🛑                |       🛑        |
| [Barrel index files](/plugins/plugin-barrel)               |        ✅         |  🛑   | 🛑                |       🛑        |

**Notes**

1. **React Query and Vue Query parameter handling.** Kubb types the path and query parameters guarded by `enabled` as optional and emits the `enabled` guard, so you can pass a value that is not ready yet (a route parameter or the result of a dependent query) and the query stays disabled until it resolves. HeyAPI keeps those parameters required and does not emit an `enabled` guard, leaving conditional fetching to you.
2. HeyAPI also generates Valibot schemas in addition to Zod.
3. openapi-typescript generates types only. Its companion `openapi-fetch` runtime provides the typed client, so a client is not generated per operation. Note that `openapi-fetch` is in [feature-freeze and is largely considered deprecated](https://github.com/openapi-ts/openapi-typescript/discussions/2559).

## What sets Kubb apart

### Plugin architecture

Every output is a separate [plugin](/docs/5.x/concepts/plugins). You add only what you need. All plugins run against a shared [AST](/docs/5.x/concepts/ast), so the spec is parsed once and naming stays consistent across every output.

### Custom adapters and parsers

[Custom adapters](/docs/5.x/concepts/adapters) let you swap `adapterOas` for any input format: AsyncAPI, GraphQL, or JSON Schema. [Custom parsers](/docs/5.x/concepts/parsers) let you target any output language: Python, Kotlin, Rust, or other. Neither orval nor HeyAPI supports either. Because you can combine custom adapters, parsers, and plugins in one pipeline, Kubb covers a broader range of inputs and outputs.

### Post-enforced plugins

Plugins with `enforce: 'post'` run after all regular plugins finish, handling cross-cutting concerns like barrel files and manifests without modifying each plugin individually. [`@kubb/plugin-barrel`](/plugins/plugin-barrel) uses this mechanism.

### Bundler integration

[`unplugin-kubb`](/docs/5.x/integrations/) integrates generation into Vite, Rollup, Rolldown, Webpack, Rspack, esbuild, Farm, Nuxt, and Astro. HeyAPI ships a Vite-only plugin; orval has no bundler integration.

## When not to use Kubb

- You consume only a few endpoints that rarely change.
- You do not have an OpenAPI spec and do not plan to write one.
- You need codegen for a non-OpenAPI format today and do not want to write a custom adapter.
