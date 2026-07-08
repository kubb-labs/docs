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

| Feature                                               | Kubb | orval | HeyAPI         |   openapi-ts   |
| ----------------------------------------------------- | :--: | :---: | :------------- | :------------: |
| [OpenAPI 2.0, 3.0, 3.1 input](/adapters/adapter-oas/)  |  ✅  |  ✅   | ✅             | 🔶<sup>1</sup> |
| [TypeScript types](/plugins/plugin-ts/)               |  ✅  |  ✅   | ✅             |       ✅       |
| [HTTP client (Axios, Fetch)](/plugins/plugin-axios/)  |  ✅  |  ✅   | ✅             | 🔶<sup>2</sup> |
| [React Query hooks](/plugins/plugin-react-query/)     |  ✅  |  ✅   | ✅             | 🟡<sup>3</sup> |
| [Vue Query composables](/plugins/plugin-vue-query/)   |  ✅  |  ✅   | ✅             |       🛑       |
| [SWR hooks](/plugins/plugin-swr/)                     |  ✅  |  ✅   | ✅             | 🟡<sup>4</sup> |
| [Zod validation schemas](/plugins/plugin-zod/)        |  ✅  |  ✅   | ✅<sup>5</sup> |       🛑       |
| [MSW request handlers](/plugins/plugin-msw/)          |  ✅  |  ✅   | ✅             |       🛑       |
| [Faker.js mock data](/plugins/plugin-faker/)          |  ✅  |  ✅   | ✅             |       🛑       |
| [Cypress E2E tests](/plugins/plugin-cypress/)         |  ✅  |  🛑   | 🛑             |       🛑       |
| [MCP server](/plugins/plugin-mcp/)                    |  ✅  |  ✅   | 🛑             |       🛑       |
| [Redoc API documentation](/plugins/plugin-redoc/)     |  ✅  |  🛑   | 🛑             |       🛑       |
| [Barrel index files](/plugins/plugin-barrel/)         |  ✅  |  ✅   | ✅             |       🛑       |

**Notes**

1. openapi-typescript reads OpenAPI 3.0 and 3.1 only, so a Swagger 2.0 document has to be up-converted first. Kubb, orval, and HeyAPI accept 2.0 and up-convert it for you.
2. openapi-typescript generates types only. The typed client comes from its `openapi-fetch` runtime, not per-operation code, and `openapi-fetch` is now in [maintenance mode](https://github.com/openapi-ts/openapi-typescript/discussions/2559).
3. openapi-typescript generates no hooks. React Query support comes from the first-party [`openapi-react-query`](https://www.npmjs.com/package/openapi-react-query) runtime, also in maintenance mode.
4. openapi-typescript relies on the community [`swr-openapi`](https://github.com/htunnicliff/swr-openapi) package.
5. HeyAPI also generates Valibot schemas alongside Zod.

## Type safety and response handling

The first table is about which outputs exist. This one is about how well each tool models a single operation and how much of that reaches your code.

On coverage the three are close. The gap is ergonomics. Kubb puts the status on the result, so one `switch` narrows the body and the same call can throw or return its error. orval does this in its `fetch` client only. HeyAPI gives a status-keyed type map to index, not a value you branch on at runtime.

The legend matches the table above.

| Feature                                                                              | Kubb  |     orval      | HeyAPI         |
| ------------------------------------------------------------------------------------ | :---: | :------------: | :------------- |
| [Status-discriminated response result](/plugins/plugin-fetch/guide/error-handling)   |  ✅   | 🔶<sup>1</sup> | 🔶<sup>2</sup> |
| Multiple success (2xx) responses                                                     |  ✅   |       ✅       | ✅             |
| Multiple content types per response                                                  |  ✅   |       ✅       | 🛑<sup>3</sup> |
| `default` and wildcard (`4XX`, `5XX`) responses                                      |  ✅   | ✅<sup>4</sup> | ✅             |
| [Typed error responses](/plugins/plugin-fetch/guide/error-handling)                  |  ✅   | 🔶<sup>5</sup> | ✅             |
| [Throw or return the error per call](/plugins/plugin-fetch/guide/error-handling)     |  ✅   |       🛑       | ✅             |
| [Zod v4 schemas tied to the types](/plugins/plugin-zod/)                             |  ✅   |       ✅       | ✅             |
| Recursive schemas                                                                    |  ✅   |       ✅       | ✅             |
| Server-side schema validation                                                        |  ✅   |       ✅       | ✅             |

**Notes**

1. Only orval's `fetch` client emits a status-narrowable union. Its axios and query clients return the success type and take the error type on the side.
2. HeyAPI builds a status-keyed type map you index (`Responses[200]`), but the SDK returns a flat `{ data, error }` pair with no `status` to switch on.
3. On `@hey-api/openapi-ts` v0.99.0, a response with both `application/json` and `application/xml` keeps only the JSON shape. Kubb and orval emit a variant per content type.
4. orval expands `4XX` and `5XX` into unions of concrete codes. Kubb and HeyAPI keep the range key.
5. orval types the error body in its `fetch` client, or once you wire `ErrorType` or `override.swr.generateErrorTypes`. Otherwise it stays `Error`.

openapi-typescript is omitted here. It ships no generated client, so the runtime rows do not apply.

## Client runtime

The generated client does more than wrap `fetch`. It encodes parameters and bodies from the spec, decodes responses by content type, and can validate both ends. See [serialization](/plugins/plugin-fetch/guide/serialization) for the full picture.

Two things set Kubb's client apart. It reads each parameter's OpenAPI `style` and `explode` from the spec, so query, path, header, and cookie all encode with no config. And [`codecs`](/plugins/plugin-fetch/guide/serialization#request-bodies) register a `serialize` and `deserialize` per media type, so XML or YAML round-trips without replacing the client.

The legend matches the tables above.

| Feature                                                                                                   | Kubb  | orval          | HeyAPI         |
| --------------------------------------------------------------------------------------------------------- | :---: | :------------- | :------------- |
| [Parameter styles from the spec](/plugins/plugin-fetch/guide/serialization#parameter-styles)              |  ✅   | 🔶<sup>1</sup> | 🔶<sup>2</sup> |
| Request body serializers (JSON, form-data, urlencoded)                                                    | ✅<sup>3</sup> | ✅    | ✅             |
| [Pluggable codecs per media type](/plugins/plugin-fetch/guide/serialization#request-bodies) (XML, YAML)   |  ✅   | 🛑<sup>4</sup> | 🛑<sup>4</sup> |
| [Runtime body validation](/plugins/plugin-fetch/guide/error-handling#validation-failures)                 | ✅<sup>5</sup> | 🔶<sup>5</sup> | ✅<sup>5</sup> |
| [Server-sent events and streaming](/plugins/plugin-fetch/guide/server-sent-events)                        |  ✅   | 🔶<sup>6</sup> | ✅             |

**Notes**

1. Only orval's `fetch` client reads `style` and `explode` from the spec. Its axios and query clients interpolate path parameters directly and leave query encoding to axios or a `qs` config.
2. HeyAPI serializes path parameters per parameter but runs one global query serializer, and does not style header or cookie parameters.
3. All three encode JSON, `multipart/form-data`, and `application/x-www-form-urlencoded`. Kubb also honors the OpenAPI `encoding` object, so a form part can set its own content type and style.
4. orval and HeyAPI expose a single body serializer and one response transformer, so a new media type means replacing them, not registering one.
5. Off by default. Kubb validates request and response bodies through any Standard Schema validator (Zod, valibot, arktype). HeyAPI validates both with Zod or Valibot. orval validates responses only, with Zod.
6. orval streams NDJSON on its `fetch` client but has no server-sent events (`text/event-stream`) support. Kubb and HeyAPI consume SSE.

## The Kubb toolkit

Every job in Kubb is one of three pieces: an [adapter](/docs/5.x/guide/concepts/adapters) reads the input, a [parser](/docs/5.x/guide/concepts/parsers) renders the output language, and a [plugin](/docs/5.x/guide/concepts/plugins) emits each artifact on the shared [AST](/docs/5.x/guide/concepts/ast). When a built-in falls short you write your own, the extension point orval and HeyAPI do not have.

**Adapters (input)**

- [`@kubb/adapter-oas`](/adapters/adapter-oas/) reads OpenAPI 2.0, 3.0, and 3.1.

**Parsers (output)**

- [`@kubb/parser-ts`](/parsers/parser-ts/) renders TypeScript and TSX.
- [`@kubb/parser-md`](/parsers/parser-md/) renders Markdown.

**Plugins (artifacts)**

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) types, interfaces, and enums.
- [`@kubb/plugin-zod`](/plugins/plugin-zod/) Zod v4 schemas.
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and [`@kubb/plugin-axios`](/plugins/plugin-axios/) HTTP clients.
- [`@kubb/plugin-react-query`](/plugins/plugin-react-query/), [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query/), and [`@kubb/plugin-swr`](/plugins/plugin-swr/) data-fetching hooks.
- [`@kubb/plugin-faker`](/plugins/plugin-faker/) mock data and [`@kubb/plugin-msw`](/plugins/plugin-msw/) request handlers.
- [`@kubb/plugin-cypress`](/plugins/plugin-cypress/) end-to-end tests.
- [`@kubb/plugin-redoc`](/plugins/plugin-redoc/) API documentation.
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp/) an MCP server for your API.
- [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) barrel index files.

## What sets Kubb apart

### Plugin architecture

Every output is a separate [plugin](/docs/5.x/guide/concepts/plugins) on a shared [AST](/docs/5.x/guide/concepts/ast). Kubb parses the spec once, so names stay consistent across outputs and you add only what you need.

### Custom adapters and parsers

A [custom adapter](/docs/5.x/guide/concepts/adapters) swaps `adapterOas` for another input such as AsyncAPI or GraphQL. A [custom parser](/docs/5.x/guide/concepts/parsers) targets another output language such as Python or Rust. orval and HeyAPI have no such extension point: input is OpenAPI and the generators are first-party, so a new format waits on the maintainers, not an adapter or parser you write.

### Advanced client

One client backs both [`fetch`](/plugins/plugin-fetch/) and [`axios`](/plugins/plugin-axios/). It reads `style` and `explode` for query, path, header, and cookie, picks a body encoder from the content type, and decodes the response by media type. [`codecs`](/plugins/plugin-fetch/guide/serialization#request-bodies) add a `serialize` and `deserialize` per media type, so XML or YAML round-trips without swapping the client. A call returns a status-discriminated result you narrow with one `switch`, and [`throwOnError`](/plugins/plugin-fetch/guide/error-handling) picks throw or return per call. The codecs and the full parameter-style coverage are what orval and HeyAPI do not match.

### Post-enforced plugins

Plugins with `enforce: 'post'` run after the rest and handle cross-output work like barrel files without touching each plugin. [`@kubb/plugin-barrel`](/plugins/plugin-barrel/) works this way.

### Bundler integration

[`unplugin-kubb`](/docs/5.x/guide/integrations/) runs generation inside Vite, Rollup, Webpack, esbuild, Nuxt, and Astro. HeyAPI ships a Vite plugin and a Nuxt module. orval has no bundler integration.

### MCP and AI agents

[`@kubb/plugin-mcp`](/plugins/plugin-mcp/) turns your spec into an MCP server, so an assistant calls your API as typed tools. orval matches this with `@orval/mcp`. HeyAPI has none. Kubb also ships a built-in MCP server for the generator itself, so Claude, Cursor, or any MCP client runs Kubb from a prompt.

## When not to use Kubb

- You use only a few endpoints that rarely change.
- You have no OpenAPI spec and won't write one.
- You need a non-OpenAPI format now and won't write a custom adapter.
