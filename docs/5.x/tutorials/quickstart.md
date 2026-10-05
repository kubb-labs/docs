---
layout: doc
title: Generate your first client
description: Generate and inspect a typed Axios client from a small OpenAPI specification.
outline:
  - 2
  - 3
order: 1
navigation:
  title: Generate your first client
---

# Generate your first client

Generate TypeScript types and an Axios client for one Petstore operation. You need Node.js 22 or higher and npm. You'll inspect the generated operation and its types.

## 1. Create a project

```shell [Terminal]
mkdir kubb-first-client
cd kubb-first-client
npm init -y
npm pkg set type=module
npm install -D kubb typescript @kubb/plugin-ts @kubb/plugin-axios
npm install axios
```

## 2. Add the specification

Create `petStore.yaml` in the project root:

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

The `getPetById` operation accepts a pet ID and returns a pet with an ID and name.

## 3. Configure generation

Create `kubb.config.ts` beside the specification:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({ output: { path: 'models' } }),
    pluginAxios({ output: { path: 'clients' } }),
  ],
})
```

This configuration writes types to `src/gen/models` and the client to `src/gen/clients`. The generated directory is dedicated to Kubb because `clean: true` removes it before each run.

## 4. Generate the client

```shell [Terminal]
npx kubb generate
```

Kubb reports a successful build. List the generated client files:

```shell [Terminal]
node -e "console.log(require('node:fs').readdirSync('src/gen/clients'))"
```

The output contains `getPetById.ts`. Open that file and notice that `getPetById` accepts typed path parameters and returns a typed result. Its imported types live in `src/gen/models`.

Run `npx kubb generate` again. Kubb recreates the same client from the same specification. You now have a typed client ready to import into your application.

## Continue

- [Call generated operations](/plugins/plugin-axios/guide/calling-operations) and [configure their host](/plugins/plugin-axios/guide/base-url).
- [Configure generation](/docs/5.x/how-to/recipes) for React or Vue hooks, validation, and mocks.
- [Interactive setup](/docs/5.x/reference/commands/init) for an existing project.
- [Configuration reference](/docs/5.x/reference/configuration) for supported specification versions, options, and config formats.
