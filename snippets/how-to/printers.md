# Customize generated code with printers

Set `printer.nodes` on TypeScript, Zod, or Faker plugins to change how schema types are emitted. Override only the handlers you need.

For callback signatures and context properties, see the [AST reference](/docs/5.x/reference/kit/ast#printers).

## TypeScript types

`@kubb/plugin-ts` builds TypeScript AST nodes, so a handler returns a `ts.TypeNode` created with the compiler's factory. This override prints `date` schemas as the JavaScript `Date` object instead of `string`.

```typescript [date.ts]
import ts from 'typescript'
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  printer: {
    nodes: {
      date() {
        return ts.factory.createTypeReferenceNode('Date', [])
      },
    },
  },
})
```

## Zod schemas

Write regular methods when you use `this.base`, `this.transform`, or `this.options`; arrow functions do not receive the printer context.

`@kubb/plugin-zod` prints expression strings, so a handler returns the Zod code as a string. With `mini: true` the same overrides target the Zod Mini printer instead.

```typescript twoslash [date.ts]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      date() {
        return 'z.iso.date()'
      },
    },
  },
})
```

Use `this.base` to keep the default output and decorate it. This override appends `.openapi(...)` to every object schema, and nested nodes still print through the regular handlers.

```typescript twoslash [openapi.ts]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      object(node) {
        return `${this.base(node)}.openapi(${JSON.stringify({ description: node.description })})`
      },
    },
  },
})
```

A Zod handler can also read `this.options.direction`, which is `'decode'` while printing response schemas and `'encode'` while printing request bodies and parameters. Return a different expression per direction and the plugin treats the node as a two-way conversion, emitting an `${name}InputSchema` variant that request bodies resolve to. See [Encode a custom type on requests](/plugins/plugin-zod/guide/customization#encode-custom-types).

## Faker mocks

`@kubb/plugin-faker` also prints strings, one Faker expression per schema node. This override generates floats where the spec declares integers.

```typescript twoslash [integer.ts]
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

## Choose a customization

Use a printer for output-specific code such as `Date` or `.openapi(...)`. Use a [macro](/docs/5.x/how-to/macros) to change schema nodes before printing, or a [resolver](/docs/5.x/how-to/resolvers) to change names and paths. Macros run before printer handlers.
