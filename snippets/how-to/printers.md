# Override a printer

A printer is the last step of Kubb's pipeline. Adapters turn a spec into the [AST](/docs/5.x/guide/concepts/ast), [macros](/docs/5.x/guide/going-further/macros) rewrite the nodes, and a printer turns each schema node into code for one output target. `@kubb/plugin-ts` prints TypeScript type nodes, `@kubb/plugin-zod` prints Zod expressions, and `@kubb/plugin-faker` prints Faker expressions.

These three plugins expose their printer through a `printer.nodes` option, a partial map of schema types to handlers. A handler replaces the built-in output for one schema type, so you can print a `date` schema as the JavaScript `Date` object or append `.openapi(...)` metadata to every Zod object without forking the plugin.

## Shape

The map is keyed by the schema `type` discriminant, such as `'string'`, `'integer'`, `'date'`, `'enum'`, or `'object'`. Supply only the handlers you want to replace and the built-in ones fill in the rest.

```typescript [Type definition]
type PrinterNodes = Partial<{
  [K in SchemaType]: (this: Context, node: SchemaNodeByType[K]) => Output | null
}>
```

Handlers run with a `this` context, so write them as regular functions rather than arrow functions. `this.transform(node)` recurses into a nested schema node through the full handler map, overrides included. `this.base(node)` runs the built-in handler your override replaced, so you can wrap its output instead of rebuilding it. `this.options` reads the resolved printer options, such as `arrayType` on `@kubb/plugin-ts`.

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

## Printer override or macro

A macro rewrites the node itself, before anything prints. Retype `integer` schemas to `string` with a macro and `plugin-ts`, `plugin-zod`, and `plugin-faker` all follow, because they print the rewritten node. A printer override changes what one plugin emits for a node type. The node stays as it is, and so does the output of every other plugin.

Reach for a printer override when the output cannot be described as another schema node. No schema node prints as `Date`, and none carries an `.openapi(...)` call, so a macro cannot produce either. When the printed code is fine and only its name or file location needs to change, reach for a [resolver](/docs/5.x/guide/going-further/resolvers) instead.

> [!TIP]
> The two compose. The `macros` option on the same plugin rewrites nodes first, then the printer prints the result, overrides included.
