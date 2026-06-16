---
layout: doc
title: Introduction
description: Kubb is the meta framework for code generation. A plugin-based system that turns any API specification into TypeScript types, API clients, hooks, validators, and mocks.
outline: [2, 3]
---

# Introduction

Kubb is the meta framework for code generation. Where Nuxt adds structure on top of Vue, Kubb adds a plugin-based generation pipeline on top of any API specification. An [adapter](/adapters) reads your spec, [parsers](/parsers) turn the [AST](/docs/5.x/concepts/ast) into source files, and [plugins](/plugins) generate the output. The pipeline takes care of writing, formatting, and linting, and the whole thing runs from a single config file.

The default adapter reads [OpenAPI](https://www.openapis.org/) 2.0, 3.0, and 3.1. For [GraphQL](https://graphql.org/), [JSON Schema](https://json-schema.org/), [gRPC](https://grpc.io/), or anything else, you can write your own adapter. From there Kubb generates TypeScript types, React Query hooks, Zod validators, MSW mocks, or a custom output of your own, so you stop hand-maintaining generated code. The output is also deterministic in a way AI or LLM-generated code is not: the same spec always produces the same result.

## Features

| Feature                                             | Description                                                                                                                        |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [TypeScript types](/plugins/plugin-ts)              | Type-safe interfaces and types from your schemas                                                                                   |
| [API clients](/plugins/plugin-client)               | Type-safe HTTP clients for [Axios](https://axios-http.com/) or [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) |
| [React Query hooks](/plugins/plugin-react-query)    | `useQuery` and `useMutation` hooks for [React Query](https://tanstack.com/query)                                                   |
| [Vue Query composables](/plugins/plugin-vue-query)  | The same hooks, for [Vue Query](https://tanstack.com/query)                                                                        |
| [Zod schemas](/plugins/plugin-zod)                  | Runtime validation schemas via [Zod](https://zod.dev/)                                                                             |
| [MSW handlers](/plugins/plugin-msw)                 | [Mock Service Worker](https://mswjs.io/) handlers for frontend development and testing                                             |
| [Faker mocks](/plugins/plugin-faker)                | Realistic mock data using [Faker.js](https://fakerjs.dev/)                                                                         |
| [Cypress tests](/plugins/plugin-cypress)            | End-to-end API tests with [Cypress](https://www.cypress.io/)                                                                       |
| [MCP servers](/plugins/plugin-mcp)                  | [Model Context Protocol](https://modelcontextprotocol.io/) servers so AI assistants can interact with your API                     |
| [Custom plugins](/docs/5.x/guides/creating-plugins) | Write your own using the same APIs the official plugins use                                                                        |

Start with [Installation](./installation) or [Basic Usage](./basic-usage). For deeper reference see [Configuration](../reference/configuration), [Recipes](../recipes), and [Integrations](../integrations/).

## Community

Join the [Discord server](https://discord.gg/shfBFeczrm), file an issue on [GitHub](https://github.com/kubb-labs/kubb/issues), or [sponsor the project](https://github.com/sponsors/stijnvanhulle).
