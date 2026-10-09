---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-faker.
outline: deep
---

# Options

Configure `@kubb/plugin-faker` by passing these options to `pluginFaker()`, all of them optional.

::field-group

:::field{name="output" type="Output"}
Where the generated files are written and exported. [See details](#output).

Default: `{ path: 'mocks', barrel: { type: 'named' } }`.
:::

:::field{name="group" type="Group"}
Split output into per-tag or per-path folders. [See details](#group).

No default.
:::

:::field{name="typeMode" type="'inferred' | 'schema'"}
Type object and intersection factories from generated values or the declared model. [See details](#typemode).

Default: `'inferred'`.
:::

:::field{name="dateParser" type="'faker' | 'dayjs' | 'moment' | string"}
Library that formats string date and time fields. [See details](#dateparser).

Default: `'faker'`.
:::

:::field{name="regexGenerator" type="'faker' | 'randexp'"}
Library that turns a regex `pattern` into a string. [See details](#regexgenerator).

Default: `'faker'`.
:::

:::field{name="locale" type="string"}
Faker locale code for the generated values. [See details](#locale).

Default: `'en'`.
:::

:::field{name="seed" type="number | number[]"}
Value passed to `faker.seed(...)` for deterministic output. [See details](#seed).

No default.
:::

:::field{name="include" type="Array<Include>"}
Keep only operations that match. [See details](#include).

No default.
:::

:::field{name="exclude" type="Array<Exclude>"}
Skip operations that match. [See details](#exclude).

Default: `[]`.
:::

:::field{name="override" type="Array<Override>"}
Apply different options per pattern. [See details](#override).

Default: `[]`.
:::

:::field{name="resolver" type="ResolverPatch<ResolverFaker>"}
Customize generated names and file paths. [See details](#resolver).

No default.
:::

:::field{name="macros" type="Array<Macro>"}
Rewrite AST nodes before printing. [See details](#macros).

No default.
:::

:::field{name="printer" type="{ nodes?: PrinterFakerNodes }"}
Replace the handler for a schema type. [See details](#printer).

No default.
:::

::

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`, and defaulting to `'mocks'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mocks.ts'`.

#### output.mode

How the plugin consolidates generated code. `'file'` writes everything into a single file, where `output.path` must include the extension such as `'mocks.ts'`. `'directory'` writes one file per operation or schema under `output.path`. Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` requires directory output. Kubb infers the mode from `output.path`. Set `mode: 'directory'` to override that inference. Combining `group` with `mode: 'file'` stops generation with `KUBB_INVALID_PLUGIN_OPTIONS`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into the subdirectory name and the suffix for aggregate files. It defaults to `camelCase(group)` for tag groups, and for `type: 'path'` groups uses the path segment as-is.

### typeMode

Controls the input and return types of object and intersection factories. The default `'inferred'` mode derives the return type from generated values and supplied overrides. Generated optional or nullable fields keep their concrete value types, and overrides preserve literal types.

```typescript [Inferred mode (default)]
pluginFaker({ typeMode: 'inferred' })

// Generated signature:
// export function createOrder<TData extends Partial<Order> = object>(data?: TData)
const order = createOrder({ quantity: 2, complete: true })
const complete: true = order.complete

// TypeScript error: false is not assignable to true.
order.complete = false
```

Use `'schema'` for object and intersection fixtures you modify after creation. Their factories accept `Partial<Model>` and return the declared model type, including its optional and nullable fields.

```typescript [Schema mode]
pluginFaker({ typeMode: 'schema' })

// Generated signature:
// export function createOrder(data?: Partial<Order>): Order
const order = createOrder({ quantity: 2, complete: true })
order.complete = false
order.complete = true

// TypeScript error: foo does not exist in Partial<Order>.
createOrder({ quantity: 2, foo: '' })
```

Object and intersection factories generate the same values in both modes and apply overrides with a shallow merge.

Use [`override`](#override) to select a mode for matching schemas or operations. String patterns are regular expressions, so `^Order$` matches only the `Order` schema. For example, generate mutable `Order` fixtures while keeping the default inferred mode for other schemas:

```typescript [Per-schema mode]
pluginFaker({
  override: [
    {
      type: 'schemaName',
      pattern: '^Order$',
      options: { typeMode: 'schema' },
    },
  ],
})
```

### dateParser

Library used to format `date` and `time` fields represented as strings. Pick a value other than `'faker'` when your project already uses a date library. Any library exporting a default function works, and Kubb adds the import for you.

A string `date` field renders differently per parser:

::code-group

```typescript ['faker' (default)]
faker.date.anytime().toISOString().substring(0, 10)
```

```typescript ['dayjs']
dayjs(faker.date.anytime()).format('YYYY-MM-DD')
```

```typescript ['moment']
moment(faker.date.anytime()).format('YYYY-MM-DD')
```

::

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ dateParser: 'dayjs' })
```

Install `dayjs` in the consuming app. Generated `date` and `time` strings use `YYYY-MM-DD` and `HH:mm:ss`. `date-time` values keep the ISO string.

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` keyword in the spec. The default `'faker'` emits `faker.helpers.fromRegExp(pattern)` and needs no extra dependency. `'randexp'` emits `new RandExp(pattern).gen()`, which supports a wider regex grammar but adds the `randexp` runtime dependency.

### locale

Faker locale code. It switches the named import to `fakerXX` from `@faker-js/faker`, so generated values reflect the target region. The default `'en'` imports `fakerEN`, `'de'` imports `fakerDE`, and `'de_AT'` imports `fakerDE_AT`. See [Faker.js localization](https://fakerjs.dev/api/localization.html) for all locale codes.

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ locale: 'de' })
```

### seed

Value passed to `faker.seed(...)` and emitted at the top of each generated factory, giving deterministic output across runs for snapshot tests and reproducible local data. Pass a single number or an array of numbers.

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ seed: [100] })
```

Factories still accept overrides, such as `createPet({ name: 'Rex' })`.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverFakerPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
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

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->

### printer

Replaces the Faker node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/how-to/printers) covers how overrides compose with macros.

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
