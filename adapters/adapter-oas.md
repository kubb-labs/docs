---
layout: doc
title: Kubb OpenAPI Adapter
description: Parse and convert OpenAPI 2.0, 3.0, and 3.1 specifications into
  Kubb's universal AST. Handles discriminators, date formats, and server URL
  resolution.
outline: 2
kind: adapter
id: adapter-oas
---

The OpenAPI adapter sits between your spec and every Kubb plugin. It reads the file at `input.path`, validates it, and converts each schema and operation into Kubb's universal AST that downstream plugins consume.

Configure it once on `defineConfig`. Its choices for date representation, integer width, and server URL apply to every plugin in the build.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/adapter-oas@beta
```

```shell [pnpm]
pnpm add -D @kubb/adapter-oas@beta
```

```shell [npm]
npm install --save-dev @kubb/adapter-oas@beta
```

```shell [yarn]
yarn add -D @kubb/adapter-oas@beta
```

:::

## Options

### validate

Validates the OpenAPI spec with `@readme/openapi-parser` before parsing. Set to `false` only when you have a known-invalid spec that you still want to generate from.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `true`    |

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: false }),
  plugins: [],
})
```

:::

### contentType

Preferred media type when extracting request and response schemas. Operations with multiple media types fall back to this one.

Defaults to the first JSON-compatible media type found in the spec (`application/json`, `application/vnd.api+json`, any `*+json`).

|           |                                |
| --------: | :----------------------------- |
|     Type: | `'application/json' \| string` |
| Required: | `false`                        |

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ contentType: 'application/vnd.api+json' }),
  plugins: [],
})
```

### serverIndex

Index into the `servers` array from your OpenAPI spec, used to compute the base URL for plugins that need it (`@kubb/plugin-client`, `@kubb/plugin-msw`, ...).

Most projects pick `0` for the primary server. Use higher indices to point at staging or localhost when your spec defines multiple environments.

|           |          |
| --------: | :------- |
|     Type: | `number` |
| Required: | `false`  |

> [!TIP]
> Plugins read `baseURL` from this server unless they override it explicitly.

::: code-group

```yaml [OpenAPI spec]
openapi: 3.0.3
servers:
  - url: http://petstore.swagger.io/api
  - url: http://localhost:3000
```

```typescript [Use the production server]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ serverIndex: 0 }),
  plugins: [],
})
```

```typescript [Use the localhost server]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ serverIndex: 1 }),
  plugins: [],
})
```

:::

### serverVariables

Values substituted into `{variable}` placeholders in the selected server URL. Only used when `serverIndex` is set. Variables you do not provide use their `default` value from the spec.

|           |                          |
| --------: | :----------------------- |
|     Type: | `Record<string, string>` |
| Required: | `false`                  |

::: code-group

```yaml [OpenAPI spec]
openapi: 3.0.3
servers:
  - url: https://api.{env}.example.com
    variables:
      env:
        default: dev
        enum: [dev, staging, prod]
```

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({
    serverIndex: 0,
    serverVariables: { env: 'prod' },
  }),
  plugins: [],
})
// baseURL becomes: https://api.prod.example.com
```

:::

### discriminator

How `discriminator` fields on `oneOf`/`anyOf` schemas are interpreted.

- `'strict'` (default): child schemas stay exactly as written. The discriminator narrows types at the call site, but child shapes are not modified.
- `'inherit'`: Kubb propagates the discriminator property with the appropriate literal value into each child schema, so each branch's `type` field is precisely typed.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'strict' \| 'inherit'` |
| Required: | `false`                 |
|  Default: | `'strict'`              |

::: code-group

```yaml [OpenAPI spec]
openapi: 3.0.3
components:
  schemas:
    Animal:
      required: [type]
      type: object
      oneOf:
        - $ref: '#/components/schemas/Cat'
        - $ref: '#/components/schemas/Dog'
      discriminator:
        propertyName: type
        mapping:
          cat: '#/components/schemas/Cat'
          dog: '#/components/schemas/Dog'
    Cat:
      type: object
      properties:
        type:
          type: string
        indoor:
          type: boolean
    Dog:
      type: object
      properties:
        type:
          type: string
        name:
          type: string
```

```typescript ['strict' (default)]
export type Cat = {
  type: string
  indoor?: boolean
}

export type Dog = {
  type: string
  name?: string
}

export type Animal = Cat | Dog
```

```typescript ['inherit']
export type Cat = {
  type: 'cat'
  indoor?: boolean
}

export type Dog = {
  type: 'dog'
  name?: string
}

export type Animal = Cat | Dog
```

:::

#### strict

Child schemas are emitted verbatim. The discriminator property has whatever type the OpenAPI spec gave it.

#### inherit

Each child schema gets the discriminator value as a literal (`type: 'cat'`, `type: 'dog'`). Catches more bugs at compile time.

### dedupe

Collapses structurally identical schemas and enums into one shared definition.

When the same enum or object shape appears in multiple places, Kubb hoists it into a single named schema and replaces each duplicate with a `$ref`. Equality is shape-only: `description` and `example` fields are ignored. Set to `false` to keep every occurrence inline and produce output identical to earlier versions.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `true`    |

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ dedupe: false }),
  plugins: [],
})
```

:::

### dateType

How `format: date-time` schemas are represented downstream.

- `false`: fall through to a plain `string` (no validation).
- `'string'` (default): datetime string (`z.string().datetime()`, ISO 8601).
- `'stringOffset'`: datetime string with timezone offset.
- `'stringLocal'`: local datetime string (no timezone).
- `'date'`: JavaScript `Date` object. Best for client code, though it needs JSON parsing to revive.

|           |                                                                  |
| --------: | :--------------------------------------------------------------- |
|     Type: | `false \| 'string' \| 'stringOffset' \| 'stringLocal' \| 'date'` |
| Required: | `false`                                                          |
|  Default: | `'string'`                                                       |

::: code-group

```typescript [false]
// format: date-time → plain string
type CreatedAt = string
```

```typescript ['string' (default)]
// format: date-time → ISO 8601 datetime string
type CreatedAt = string
```

```typescript ['stringOffset']
// format: date-time → ISO 8601 datetime with offset
type CreatedAt = string
```

```typescript ['stringLocal']
// format: date-time → local ISO 8601 datetime
type CreatedAt = string
```

```typescript ['date']
// format: date-time → JavaScript Date
type CreatedAt = Date
```

:::

### integerType

How `type: integer` (and `format: int64`) maps to TypeScript.

- `'bigint'` (default): exact for 64-bit IDs, but `JSON.stringify`/`JSON.parse` cannot round-trip it. Use it only when you also handle bigint serialization explicitly.
- `'number'`: fits most JSON APIs, and loses precision above `Number.MAX_SAFE_INTEGER`.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'number' \| 'bigint'` |
| Required: | `false`                |
|  Default: | `'bigint'`             |

::: code-group

```typescript ['number']
type Pet = {
  id: number
}
```

```typescript ['bigint' (default)]
type Pet = {
  id: bigint
}
```

:::

### unknownType

AST type used when a schema's type cannot be inferred from the spec (`additionalProperties: true`, missing `type`, etc.).

Pick `'unknown'` to force callers to narrow before using the value. `'any'` is the loosest. `'void'` is rarely useful, but it matches some legacy APIs.

|           |                                |
| --------: | :----------------------------- |
|     Type: | `'any' \| 'unknown' \| 'void'` |
| Required: | `false`                        |
|  Default: | `'any'`                        |

::: code-group

```typescript ['any' (default)]
type Pet = {
  extra: any
}
```

```typescript ['unknown']
type Pet = {
  extra: unknown
}
```

```typescript ['void']
type Pet = {
  extra: void
}
```

:::

### emptySchemaType

AST type used for fully empty schemas (`{}`). Defaults to the value of `unknownType`. Override only when empty schemas should be treated differently from unresolvable ones.

|           |                                |
| --------: | :----------------------------- |
|     Type: | `'any' \| 'unknown' \| 'void'` |
| Required: | `false`                        |
|  Default: | `unknownType \| 'any'`         |

> [!TIP]
> A common pairing sets `unknownType: 'unknown'` for safety and `emptySchemaType: 'any'` so empty 204 response bodies stay easy to use.

::: code-group

```typescript ['any' (default)]
// empty schema {} → any
type EmptyModel = any
```

```typescript ['unknown']
// empty schema {} → unknown
type EmptyModel = unknown
```

:::

### enumSuffix

Suffix appended to derived enum names when Kubb has to invent one (typically for inline enums on object properties).

Inline enums on a `status` property would be named `statusEnum` with the default. Change this to align with your project's naming convention.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'enum'` |

::: code-group

```typescript ['enum' (default)]
// Property `status` with inline enum values
const statusEnum = { available: 'available', pending: 'pending' } as const
type StatusEnum = (typeof statusEnum)[keyof typeof statusEnum]
```

```typescript ['type']
const statusType = { available: 'available', pending: 'pending' } as const
type StatusType = (typeof statusType)[keyof typeof statusType]
```

:::

## Example

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({
    validate: true,
    serverIndex: 0,
    serverVariables: { env: 'prod' },
    discriminator: 'inherit',
    dedupe: true,
    dateType: 'date',
    integerType: 'number',
    unknownType: 'unknown',
    emptySchemaType: 'unknown',
    enumSuffix: 'enum',
  }),
  plugins: [pluginTs()],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/adapter-oas/CHANGELOG.md)
