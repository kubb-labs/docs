---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-faker.
outline: deep
---

# Options

Pass these options to `pluginFaker()`, all of them optional. Shared options link to [Shared plugin options](/docs/5.x/reference/plugin-options), which documents their behavior once.

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`output`](/docs/5.x/reference/plugin-options#output) | Where the generated files are written and exported. | `{ path: 'mocks', barrel: { type: 'named' } }` |
| ↳ [`output.path`](/docs/5.x/reference/plugin-options#output-path) | Choose the output folder or file. | `'mocks'` |
| ↳ [`output.mode`](/docs/5.x/reference/plugin-options#output-mode) | Write a single file or a directory of files. | Inferred from `output.path` |
| ↳ [`output.barrel`](/docs/5.x/reference/plugin-options#output-barrel) | Configure barrel exports. | `{ type: 'named' }` |
| ↳ [`output.banner`](/docs/5.x/reference/plugin-options#output-banner) | Add content before generated code. | None |
| ↳ [`output.footer`](/docs/5.x/reference/plugin-options#output-footer) | Add content after generated code. | None |
| [`group`](/docs/5.x/reference/plugin-options#group) | Split output into per-tag or per-path folders. | None |
| ↳ [`group.type`](/docs/5.x/reference/plugin-options#group-type) | Group operations by tag or URL path. | Required with `group` |
| ↳ [`group.name`](/docs/5.x/reference/plugin-options#group-name) | Customize output group names. | camelCased tag or raw path segment |
| [`typeMode`](#typemode) | Type object and intersection factories from generated values or the declared model. | `'inferred'` |
| [`dateParser`](#dateparser) | Library that formats string date and time fields. | `'faker'` |
| [`regexGenerator`](#regexgenerator) | Library that turns a regex `pattern` into a string. | `'faker'` |
| [`locale`](#locale) | Faker locale code for the generated values. | `'en'` |
| [`seed`](#seed) | Value passed to `faker.seed(...)` for deterministic output. | None |
| [`include`](/docs/5.x/reference/plugin-options#include) | Keep only operations and schemas that match. | None |
| [`exclude`](/docs/5.x/reference/plugin-options#exclude) | Skip operations and schemas that match. | `[]` |
| [`override`](/docs/5.x/reference/plugin-options#override) | Apply different options per pattern. | `[]` |
| [`resolver`](#resolver) | Customize generated names and file paths. | `resolverFaker` |
| [`macros`](/docs/5.x/reference/plugin-options#macros) | Rewrite AST nodes before printing. | `[]` |
| [`printer`](#printer) | Replace the handler for a schema type. | None |
| ↳ [`printer.nodes`](#printer) | Customize handlers for schema node types. | None |

## Option details

### typeMode

Controls the input and return types of object and intersection factories. Both modes generate the same values and apply overrides with a shallow merge.

| | |
| --- | --- |
| Type | `'inferred' \| 'schema'` |
| Required | `false` |
| Default | `'inferred'` |

::field-group

:::field{name="'inferred'"}
Default value. Derives return types from generated values and supplied overrides. Optional and nullable fields retain their concrete value types, and overrides preserve literal types.
:::

:::field{name="'schema'"}
Accepts `Partial<Model>` and returns the declared model type, including optional and nullable fields. Use it for fixtures you modify after creation.
:::

::

::code-group

```typescript ['inferred' (default)]
// export function createOrder<TData extends Partial<Order> = object>(data?: TData)
const order = createOrder({ quantity: 2, complete: true })
const complete: true = order.complete

// TypeScript error: false is not assignable to true.
order.complete = false
```

```typescript ['schema']
// export function createOrder(data?: Partial<Order>): Order
const order = createOrder({ quantity: 2, complete: true })
order.complete = false

// TypeScript error: foo does not exist in Partial<Order>.
createOrder({ quantity: 2, foo: '' })
```

::

Use [`override`](/docs/5.x/reference/plugin-options#override) to select a mode for matching schemas. String patterns are regular expressions, so `'^Order$'` matches only the `Order` schema:

```typescript [kubb.config.ts]
pluginFaker({
  override: [{ type: 'schemaName', pattern: '^Order$', options: { typeMode: 'schema' } }],
})
```

### dateParser

Library used to format `date` and `time` fields represented as strings. Pick a value other than `'faker'` when your project already uses a date library, and install that library in the consuming app. Generated `date` and `time` strings use `YYYY-MM-DD` and `HH:mm:ss`, and `date-time` values keep the ISO string.

| | |
| --- | --- |
| Type | `'faker' \| 'dayjs' \| 'moment' \| string` |
| Required | `false` |
| Default | `'faker'` |

::field-group

:::field{name="'faker'"}
Default value. Renders a `date` field as `faker.date.anytime().toISOString().substring(0, 10)`.
:::

:::field{name="'dayjs'"}
Renders it as `dayjs(faker.date.anytime()).format('YYYY-MM-DD')`.
:::

:::field{name="'moment'"}
Renders it as `moment(faker.date.anytime()).format('YYYY-MM-DD')`.
:::

:::field{name="Custom module"}
Pass a module name that exports a default formatting function. Kubb adds the import to generated files.
:::

::

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` in the spec.

| | |
| --- | --- |
| Type | `'faker' \| 'randexp'` |
| Required | `false` |
| Default | `'faker'` |

::field-group

:::field{name="'faker'"}
Default value. Generates `faker.helpers.fromRegExp(pattern)` without an extra dependency.
:::

:::field{name="'randexp'"}
Generates `new RandExp(pattern).gen()`. Supports a wider regex grammar and requires the `randexp` runtime dependency.
:::

::

### locale

Faker locale code. It switches the named import to `fakerXX` from `@faker-js/faker`, so generated values reflect the target region. The default `'en'` imports `fakerEN`, `'de'` imports `fakerDE`, and `'de_AT'` imports `fakerDE_AT`. See [Faker.js localization](https://fakerjs.dev/api/localization.html) for all locale codes.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `'en'` |

### seed

Value passed to `faker.seed(...)` and emitted at the top of each generated factory, giving deterministic output across runs for snapshot tests and reproducible local data. Pass a single number or an array of numbers. Factories still accept overrides, such as `createPet({ name: 'Rex' })`.

| | |
| --- | --- |
| Type | `number \| number[]` |
| Required | `false` |

### resolver

Overrides generated file and symbol names. Omitted members keep `resolverFaker`. The shared members (`name`, `file`, `imports`) and the `this` context are described under [`resolver`](/docs/5.x/reference/plugin-options#resolver).

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverFaker>` |
| Required | `false` |

::code-collapse{name="ResolverFaker patch members"}

```typescript [Partial override]
type ResolverFakerPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  imports?(options: ResolveImportsOptions): Array<ImportNode>
  param?: {
    name?(node: OperationNode, param: ParameterNode): string    // → 'showPetByIdPathPetId'
    path?(node: OperationNode, param: ParameterNode): string     // → 'createShowPetByIdPath'
    query?(node: OperationNode, param: ParameterNode): string    // → 'createListPetsQuery'
    headers?(node: OperationNode, param: ParameterNode): string  // → 'createDeletePetHeaders'
  }
  response?: {
    status?(node: OperationNode, statusCode: StatusCode): string // → 'listPetsStatus200'
    body?(node: OperationNode): string                           // → 'createPetsBody'
    response?(node: OperationNode): string                       // → 'listPetsResponse'
    responses?(node: OperationNode): string                      // → 'listPetsResponses'
  }
}
```

::

### printer

Replaces the Faker node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/how-to/printers) covers how overrides compose with macros.

| | |
| --- | --- |
| Type | `{ nodes?: PrinterFakerNodes }` |
| Required | `false` |

```typescript twoslash [Map integer schemas to a float]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  printer: {
    nodes: {
      integer() {
        return 'faker.number.float()'
      },
    },
  },
})
```
