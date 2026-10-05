# Write a macro

Use a macro to transform schema or operation nodes before generation. Macros can rename symbols, change field types, or remove metadata across output targets.

Import the macro engine through `ast` from `kubb/kit`; built-in presets are named exports of `kubb/kit`.

## Shape

A macro carries the per-kind callbacks of a [visitor](/docs/5.x/reference/kit/ast#visitors), plus a `name`, an optional `enforce` order, and an optional `match` predicate.

```typescript [Type definition]
type Macro = {
  name: string
  enforce?: 'pre' | 'post'
  match?: (node: Node) => boolean
  schema?(node: SchemaNode, context): SchemaNode | null | undefined
  operation?(node: OperationNode, context): OperationNode | null | undefined
  // input, output, property, parameter, response
}
```

Each callback returns a replacement node, or `undefined` or `null` to leave the node untouched. A macro that changes nothing returns the original reference, so an unchanged tree is reused, not rebuilt.

## Writing a macro

Define the node transformation:

```typescript twoslash [macro.ts]
import { ast } from 'kubb/kit'

const macroIntegerToString = ast.defineMacro({
  name: 'integer-to-string',
  schema(node) {
    return node.type === 'integer' ? { ...node, type: 'string' } : undefined
  },
})
```

The `match` predicate skips a macro for nodes it does not care about, and `enforce` places a macro before or after the unmarked ones.

```typescript twoslash [enforce.ts]
import { ast } from 'kubb/kit'

const macroUntagged = ast.defineMacro({
  name: 'untagged',
  enforce: 'post',
  match: (node) => node.kind === 'Operation',
  operation(node) {
    return node.tags?.length ? undefined : { ...node, tags: ['untagged'] }
  },
})
```

## Composing macros

A plugin runs a list of macros. They apply in order, so a later macro sees the output of an earlier one. `composeMacros` folds a list into a single visitor, and `applyMacros` runs the list over a tree.

```typescript twoslash [compose.ts]
import { ast } from 'kubb/kit'

const macroDto = ast.defineMacro({
  name: 'dto',
  schema(node) {
    return node.type === 'object' ? { ...node, name: node.name ? `${node.name}Dto` : node.name } : undefined
  },
})

const macroFetchPrefix = ast.defineMacro({
  name: 'fetch-prefix',
  operation(node) {
    return { ...node, operationId: node.operationId.replace(/^get/, 'fetch') }
  },
})

const root = ast.factory.createInput({ schemas: [], operations: [] })
const next = ast.applyMacros(root, [macroDto, macroFetchPrefix])
```

## Using macros in a plugin

Pass macros through a plugin's `macros` option, or register them from `kubb:plugin:setup` with `addMacro` and `setMacros`. Macros run per plugin, so one plugin's macros never change the nodes another plugin sees.

```typescript twoslash [plugin.ts]
import { ast, definePlugin } from 'kubb/kit'

const macroDropDescriptions = ast.defineMacro({
  name: 'drop-descriptions',
  schema(node) {
    return 'description' in node && node.description ? { ...node, description: undefined } : undefined
  },
})

export const pluginRename = definePlugin(() => ({
  name: 'plugin-rename',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addMacro(macroDropDescriptions)
    },
  },
}))
```

Macros run before resolver options are computed, so a renamed `operationId` or `SchemaNode.name` flows into `resolveOptions`, `resolvePath`, and `resolveFile`.

> [!TIP]
> Keep macros pure. Build a new node and return it rather than mutating the input, since the AST is shared by reference.

> [!WARNING]
> Do not rename a schema by changing only the declaration's `name`. Every `$ref` to it still resolves to the old name, so imports and printed references point at a file the plugin no longer emits. Use [`macroRenameSchema`](#built-in-macros), which renames the declaration and retargets the refs in one pass.

## Built-in macros

Import built-in presets for common transformations:

- `macroSimplifyUnion` drops union members that a broader member already covers, such as a multi-value string enum next to a plain `string`. Single-value enums stay, since they narrow the type.
- `macroDiscriminatorEnum` rewrites a discriminator property into a string enum of its allowed values. It reads options, so you call it to build a macro.
- `macroEnumName` names an inline enum from the schema and property it belongs to. It reads options, so you call it to build a macro.
- `macroRenameSchema` renames a schema consistently: it changes the declaration's `name` and stamps `targetName` on every ref that points at the old name, so [`resolveRefName`](/docs/5.x/reference/kit/ast#refs-and-naming-helpers) and [`resolver.imports`](/docs/5.x/reference/kit/resolvers#imports) emit the new name everywhere.

```typescript twoslash [presets.ts]
import { ast, macroSimplifyUnion, macroDiscriminatorEnum, macroRenameSchema } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })
const next = ast.applyMacros(root, [
  macroSimplifyUnion,
  macroDiscriminatorEnum({ propertyName: 'kind', values: ['cat', 'dog'] }),
  macroRenameSchema({ from: 'Order', to: 'StoreOrder' }),
])
```

Plugins that import another plugin's output compute names from the nodes they see, so register a rename on every plugin that touches the schema, for example by passing one shared `macros` array to each plugin's options.

Export macros from a shared module to reuse them across plugins and projects.
