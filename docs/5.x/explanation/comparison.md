---
layout: doc
title: Kubb vs orval, HeyAPI, and openapi-typescript
description: Feature-by-feature comparison of Kubb against orval, HeyAPI, and
  openapi-typescript.
outline:
  - 2
  - 3
order: 3
navigation:
  title: Comparison
---

# Kubb vs orval, HeyAPI, and openapi-typescript

Kubb, [orval](https://orval.dev), [HeyAPI](https://heyapi.dev), and [openapi-typescript](https://openapi-ts.dev) all generate code from OpenAPI specs. The tables compare generated outputs, response handling, and runtime behavior.

## Plugin and feature coverage

Legend:

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

Notes:

1. openapi-typescript reads OpenAPI 3.0 and 3.1 only, so a Swagger 2.0 document has to be up-converted first. Kubb, orval, and HeyAPI accept 2.0 and up-convert it for you.
2. openapi-typescript generates types only. The typed client comes from its `openapi-fetch` runtime, not per-operation code, and `openapi-fetch` is now in [maintenance mode](https://github.com/openapi-ts/openapi-typescript/discussions/2559).
3. openapi-typescript generates no hooks. React Query support comes from the first-party [`openapi-react-query`](https://www.npmjs.com/package/openapi-react-query) runtime, also in maintenance mode.
4. openapi-typescript relies on the community [`swr-openapi`](https://github.com/htunnicliff/swr-openapi) package.
5. HeyAPI also generates Valibot schemas alongside Zod.

## Type safety and response handling

Kubb exposes a status-discriminated result that narrows response bodies at runtime. The table compares operation typing and error handling.

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

Kubb serializes OpenAPI parameter styles and supports codecs per media type. See [serialization](/plugins/plugin-fetch/guide/serialization) for the runtime contract.

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

## Extension model

Kubb parses the specification once and shares its AST across plugins. Adapters customize input formats, parsers customize source syntax, and plugins add outputs. Post-enforced plugins handle cross-output work such as barrels. See [Architecture](/docs/5.x/explanation/architecture) and [Extension model](/docs/5.x/explanation/extensions).

[Bundler integrations](/docs/5.x/how-to/bundlers) run generation during builds. The [generator MCP server](/docs/5.x/how-to/ai/mcp) exposes Kubb to AI editors; [plugin-mcp](/plugins/plugin-mcp/) instead generates a server for your API.

## When not to use Kubb

- You use only a few endpoints that rarely change.
- You have no OpenAPI spec and won't write one.
- You need a non-OpenAPI format now and won't write a custom adapter.
