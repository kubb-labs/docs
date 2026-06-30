---
layout: doc
title: Kubb vs orval, HeyAPI, and openapi-typescript
description: Feature-by-feature comparison of Kubb against orval, HeyAPI, and openapi-typescript.
outline: [2, 3]
---

# Kubb vs orval, HeyAPI, and openapi-typescript

Kubb, [orval](https://orval.dev), [HeyAPI](https://heyapi.dev), and [openapi-typescript](https://openapi-ts.dev) all generate code from OpenAPI specs. The table below maps each Kubb plugin and adapter to the equivalent support in every tool.

We keep this comparison accurate and fair. If you use one of these tools and think a row is wrong, open an issue or pull request in [kubb-labs/kubb](https://github.com/kubb-labs/kubb/issues) with your notes or evidence.

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

## Type safety and response handling

The first table maps which outputs each tool generates. This one looks a level down, at how completely each tool models a single operation and how much of that detail reaches the code you call. It matters most when a response shape changes with the status code, or when a schema points back at itself.

On coverage the three sit closer than the first table suggests. orval and HeyAPI both read the whole response set and keep recursive types. Both also emit Zod v4 schemas you can run on a server. Where they part is ergonomics. Kubb puts the status on the result, so a `switch` narrows the body to that code, and the same call can throw or return its error. orval reaches the first through its `fetch` client only, and has no switch for the second. HeyAPI hands you a status-keyed type map to index, which types the responses but leaves nothing to branch on at runtime, and its TypeScript output keeps only the JSON shape when a response offers two content types.

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

1. orval's `fetch` client emits a response union you narrow on `status`. Its axios and query clients return the success type and take the error type on the side, so the discriminant is not there without that client.
2. HeyAPI builds a status-keyed response map you index by code, such as `GetThingResponses[200]`. The SDK resolves to a `{ data, error }` pair and the Zod output collapses to a flat union, so the runtime value carries no `status` to switch on.
3. Tested on `@hey-api/openapi-ts` v0.99.0, a response that declares both `application/json` and `application/xml` keeps only the JSON shape in the generated types. Kubb and orval each emit one variant per content type.
4. orval expands `4XX` and `5XX` into unions of the concrete status codes. Kubb and HeyAPI keep the range key as written.
5. orval types the error body in its `fetch` client, and elsewhere once you wire it through the mutator `ErrorType` or `override.swr.generateErrorTypes`. The hook error type stays `Error` until then.

openapi-typescript stays out of this table. It models responses at the type level but ships no generated client, so the runtime rows would not apply to it.

## What sets Kubb apart

### Plugin architecture

Every output is a separate [plugin](/docs/5.x/guide/concepts/plugins), so you add only what you need. The plugins run against a shared [AST](/docs/5.x/guide/concepts/ast). Kubb parses the spec once, and naming stays consistent across every output.

### Custom adapters and parsers

A [custom adapter](/docs/5.x/guide/concepts/adapters) swaps `adapterOas` for another input format such as AsyncAPI, GraphQL, or JSON Schema. A [custom parser](/docs/5.x/guide/concepts/parsers) targets another output language such as Python, Kotlin, or Rust. Neither orval nor HeyAPI supports either one. When you combine custom adapters, parsers, and plugins in one pipeline, Kubb reaches inputs and outputs the others cannot.

### Post-enforced plugins

Plugins with `enforce: 'post'` run after every regular plugin finishes. They handle work that spans outputs, such as barrel files and manifests, without touching each plugin. [`@kubb/plugin-barrel`](/plugins/plugin-barrel) works this way.

### Bundler integration

[`unplugin-kubb`](/docs/5.x/guide/integrations/) runs generation inside Vite, Rollup, Rolldown, Webpack, Rspack, esbuild, Farm, Nuxt, and Astro. HeyAPI ships a Vite-only plugin. orval has no bundler integration.

## When not to use Kubb

- You consume only a few endpoints that rarely change.
- You do not have an OpenAPI spec and do not plan to write one.
- You need codegen for a non-OpenAPI format today and do not want to write a custom adapter.
