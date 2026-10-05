---
layout: doc
title: Introduction
description: Generate types, API clients, query hooks, validators, and mocks
  from API specifications with Kubb.
outline:
  - 2
  - 3
order: 0
navigation:
  title: Introduction
  icon: i-iconoir-info-circle
---

# Introduction

Kubb generates types, API clients, query hooks, validators, and mocks from an API specification. Choose [plugins](/plugins) for the outputs you need and configure them in one file.

The default [OpenAPI adapter](/adapters/adapter-oas/) supports OpenAPI 2.0, 3.0, and 3.1. Custom adapters read other input formats. Custom plugins add outputs.

## Start here

| You want to | Read |
| --- | --- |
| Generate your first client | [Quickstart](/docs/5.x/tutorials/quickstart) |
| Configure a stack or workflow | [Configure generation](/docs/5.x/how-to/recipes) |
| Rename files or customize generated code | [Resolvers](/docs/5.x/how-to/resolvers), [macros](/docs/5.x/how-to/macros), and [printers](/docs/5.x/how-to/printers) |
| Run generation during a build or in CI | [Bundlers](/docs/5.x/how-to/integrations/build-tools) and [CI](/docs/5.x/how-to/integrations/ci) |
| Generate from a browser or AI editor | [Studio](/docs/5.x/how-to/integrations/studio) and [MCP setup](/docs/5.x/how-to/integrations/ai/mcp) |
| Build a plugin | [Plugin tutorial](/docs/5.x/tutorials/creating-plugins) |
| Look up an option or API | [Configuration](/docs/5.x/reference/configuration), [commands](/docs/5.x/reference/commands/), and [Kit API](/docs/5.x/reference/kit) |
| Understand the pipeline | [Architecture](/docs/5.x/explanation/architecture) |
| Upgrade from v4 | [Migration guide](/docs/5.x/how-to/migration) |

## Available outputs

[TypeScript](/plugins/plugin-ts/) types, [Axios](/plugins/plugin-axios/) and [Fetch](/plugins/plugin-fetch/) clients, [React Query](/plugins/plugin-react-query/), [Vue Query](/plugins/plugin-vue-query/), [SWR](/plugins/plugin-swr/), [Zod](/plugins/plugin-zod/), [Faker](/plugins/plugin-faker/), [MSW](/plugins/plugin-msw/), [Cypress](/plugins/plugin-cypress/), and [MCP servers](/plugins/plugin-mcp/) each have a plugin.

Generated files belong to your project. Regenerate them when the specification changes, then import them in your application.

## Community

Kubb is free and open source under the MIT license. Get help on [Discord](https://discord.gg/shfBFeczrm), report an issue on [GitHub](https://github.com/kubb-labs/kubb/issues), or read [Contributing](/docs/5.x/community/contributing).
