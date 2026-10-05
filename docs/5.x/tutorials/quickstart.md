---
layout: doc
title: Quickstart
description: Install Kubb and generate TypeScript types, an HTTP client, and
  React Query hooks from an OpenAPI specification.
outline:
  - 2
  - 3
order: 1
---

# Quickstart

Generate TypeScript types, an Axios client, and React Query hooks for a small Petstore API. The React example assumes a React application.

## Prerequisites

Use Node.js 22 or higher and an OpenAPI 2.0, 3.0, or 3.1 specification. TypeScript 5.0 or higher is required for TypeScript configuration and generated types.

## 1. Install Kubb

For interactive setup, run `npx kubb init`, then skip to [Generate](#_3-generate). The wizard installs your selected plugins and writes `kubb.config.ts`.

For manual setup, install Kubb and the plugins used below:

::code-group

```shell [bun]
bun add -d kubb @kubb/plugin-ts @kubb/plugin-axios @kubb/plugin-react-query
```

```shell [pnpm]
pnpm add -D kubb @kubb/plugin-ts @kubb/plugin-axios @kubb/plugin-react-query
```

```shell [npm]
npm install -D kubb @kubb/plugin-ts @kubb/plugin-axios @kubb/plugin-react-query
```

```shell [yarn]
yarn add -D kubb @kubb/plugin-ts @kubb/plugin-axios @kubb/plugin-react-query
```

::

Install the generated client's runtime dependencies. React projects also need the query runtime:

```shell [Terminal]
npm install axios @tanstack/react-query react react-dom
```

## 2. Configure generation

Create this specification in your project root:

```yaml [petStore.yaml]
openapi: 3.0.3
info:
  title: Petstore
  version: 1.0.0
servers:
  - url: https://petstore.swagger.io/v2
paths:
  /pet/{petId}:
    get:
      operationId: getPetById
      parameters:
        - name: petId
          in: path
          required: true
          schema:
            type: integer
      responses:
        '200':
          description: A pet
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Pet'
components:
  schemas:
    Pet:
      type: object
      required: [id, name]
      properties:
        id:
          type: integer
        name:
          type: string
```

Create the config beside it:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({ output: { path: 'models' } }),
    pluginAxios({ output: { path: 'clients' }, baseURL: 'https://petstore.swagger.io/v2' }),
    pluginReactQuery({ output: { path: 'hooks' }, hooks: true }),
  ],
})
```

`defineConfig` supplies the OpenAPI adapter and TypeScript, TSX, and Markdown parsers. Install only the [plugins](/plugins) for the outputs you need. Axios and React Query require the TypeScript plugin. React Query also needs an Axios or Fetch client plugin. Set `hooks: true` to generate `use*` hooks.

> [!WARNING]
> Use `clean: true` only with a dedicated generated-code directory. It removes that directory before generation.

## 3. Generate

Add a script:

```json [package.json]
{
  "scripts": {
    "generate": "kubb generate"
  }
}
```

Run it:

```shell [Terminal]
npm run generate
```

Kubb writes the files to `src/gen`, grouped into `models`, `clients`, and `hooks` as configured above.

## 4. Use the output

The specification generates a `getPetById` operation and its hook. Import either in your application. Wrap React components in a [QueryClientProvider](https://tanstack.com/query/latest/docs/framework/react/quick-start) before using the hook:

::code-group

```typescript [src/app.ts]
import { getPetById } from './gen/clients/getPetById'

const { data: pet } = await getPetById({ path: { petId: 1 } })
```

```tsx [src/Pet.tsx]
import { useGetPetById } from './gen/hooks/useGetPetById'

export function Pet({ id }: { id: number }) {
  const { data, isLoading } = useGetPetById({ path: { petId: id } })
  if (isLoading) return null
  return <span>{data?.name}</span>
}
```

::

## 5. Regenerate when the specification changes

Run `npm run generate` again, or watch for changes:

```shell [Terminal]
npx kubb generate --watch
```

## Next steps

- [Recipes](/docs/5.x/how-to/recipes) for Vue Query, validation, and mocks.
- [Configuration](/docs/5.x/reference/configuration) for all options and config formats.
- [Bundler integration](/docs/5.x/how-to/bundlers) to generate during a build.
