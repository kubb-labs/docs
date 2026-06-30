---
layout: doc
title: Kubb vs orval, HeyAPI, and openapi-typescript
description: Feature-by-feature comparison of Kubb against orval, HeyAPI, and openapi-typescript.
outline: [2, 3]
---

# Kubb vs orval, HeyAPI, and openapi-typescript

Kubb, [orval](https://orval.dev), [HeyAPI](https://heyapi.dev), and [openapi-typescript](https://openapi-ts.dev) all generate code from OpenAPI specs. The tables below compare their support, feature by feature. Think a row is wrong? Open an issue or PR on [kubb-labs/kubb](https://github.com/kubb-labs/kubb/issues) with the evidence.

## Plugin and feature coverage

**Legend**

- ✅ Built in, no extra config.
- 🟡 Through a third-party or community plugin.
- 🔶 Supported, but needs extra user code.
- 🛑 Not officially supported.

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

1. HeyAPI also generates Valibot schemas alongside Zod.
2. openapi-typescript generates types only. The typed client comes from its `openapi-fetch` runtime, not per-operation code, and `openapi-fetch` is now in [feature freeze](https://github.com/openapi-ts/openapi-typescript/discussions/2559).
3. HeyAPI lists SWR as a [roadmap proposal](https://github.com/hey-api/openapi-ts/issues/1479) that has not started.
4. openapi-typescript relies on the community [`swr-openapi`](https://github.com/htunnicliff/swr-openapi) package.
5. orval has no standalone Faker output. It fills its MSW handlers with `faker` data instead.

## Type safety and response handling

The first table is about which outputs exist. This one is about how well each tool models a single operation, and how much of that reaches your code.

On coverage the three are close. The gap is ergonomics. Kubb puts the status on the result, so one `switch` narrows the body and the same call can throw or return its error. orval does this in its `fetch` client only. HeyAPI gives a status-keyed type map to index, not a value you branch on at runtime.

The legend matches the table above.

| Feature                                                                              | Kubb  |     orval      | HeyAPI         |
| ------------------------------------------------------------------------------------ | :---: | :------------: | :------------- |
| [Status-discriminated response result](/docs/5.x/guide/going-further/error-handling) |  ✅   | 🔶<sup>1</sup> | 🔶<sup>2</sup> |
| Multiple success (2xx) responses                                                     |  ✅   |       ✅       | ✅             |
| Multiple content types per response                                                  |  ✅   |       ✅       | 🛑<sup>3</sup> |
| `default` and wildcard (`4XX`, `5XX`) responses                                      |  ✅   | ✅<sup>4</sup> | ✅             |
| [Typed error responses](/docs/5.x/guide/going-further/error-handling)                |  ✅   | 🔶<sup>5</sup> | ✅             |
| [Throw or return the error per call](/docs/5.x/guide/going-further/error-handling)   |  ✅   |       🛑       | ✅             |
| [Zod v4 schemas tied to the types](/plugins/plugin-zod)                              |  ✅   |       ✅       | ✅             |
| Recursive schemas                                                                    |  ✅   |       ✅       | ✅             |
| Server-side schema validation                                                        |  ✅   |       ✅       | ✅             |

**Notes**

1. Only orval's `fetch` client emits a status-narrowable union. Its axios and query clients return the success type and take the error type on the side.
2. HeyAPI builds a status-keyed type map you index (`Responses[200]`), but the SDK returns a flat `{ data, error }` pair with no `status` to switch on.
3. On `@hey-api/openapi-ts` v0.99.0, a response with both `application/json` and `application/xml` keeps only the JSON shape. Kubb and orval emit a variant per content type.
4. orval expands `4XX` and `5XX` into unions of concrete codes. Kubb and HeyAPI keep the range key.
5. orval types the error body in its `fetch` client, or once you wire `ErrorType` or `override.swr.generateErrorTypes`. Otherwise it stays `Error`.

openapi-typescript is omitted here. It ships no generated client, so the runtime rows do not apply.

## What sets Kubb apart

### Plugin architecture

Every output is a separate [plugin](/docs/5.x/guide/concepts/plugins) on a shared [AST](/docs/5.x/guide/concepts/ast). Kubb parses the spec once, so names stay consistent across outputs and you add only what you need.

### Custom adapters and parsers

A [custom adapter](/docs/5.x/guide/concepts/adapters) swaps `adapterOas` for another input such as AsyncAPI or GraphQL. A [custom parser](/docs/5.x/guide/concepts/parsers) targets another output language such as Python or Rust. orval and HeyAPI do neither, so Kubb reaches inputs and outputs they cannot.

### Post-enforced plugins

Plugins with `enforce: 'post'` run after the rest, handling cross-output work like barrel files without touching each plugin. [`@kubb/plugin-barrel`](/plugins/plugin-barrel) works this way.

### Bundler integration

[`unplugin-kubb`](/docs/5.x/guide/integrations/) runs generation inside Vite, Rollup, Webpack, esbuild, Nuxt, and Astro. HeyAPI is Vite-only. orval has no bundler integration.

## When not to use Kubb

- You use only a few endpoints that rarely change.
- You have no OpenAPI spec and won't write one.
- You need a non-OpenAPI format now and won't write a custom adapter.
