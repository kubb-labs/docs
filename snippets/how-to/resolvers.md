# Override a resolver

A resolver decides what generated code is called. Adapters turn a spec into the [AST](/docs/5.x/guide/concepts/ast), [generators](/docs/5.x/guide/concepts/plugins) walk the nodes, and a resolver names every symbol a plugin emits and picks the file each one lands in. `@kubb/plugin-ts` names its types, `@kubb/plugin-zod` names its schemas, and `@kubb/plugin-react-query` names its hooks and query keys, each through its own resolver.

Every code-generating plugin exposes that resolver through a `resolver` option, a partial patch over the plugin's built-in resolver. Set the top-level `name` to change identifier casing, `file` to rename or move the generated files, or a single namespaced method to rename one kind of symbol. Anything you leave out keeps the plugin default, so you change one naming rule without forking the plugin.

## Shape

The patch mirrors the plugin's resolver, so you supply only the members you want to replace. `name` casts an identifier, `file.baseName` builds a file's base name, `file.path` owns its full path, and namespaces such as `query`, `schema`, and `response` group the per-operation names.

```typescript [Type definition]
type ResolverPatch = {
  name?: (name: string) => string
  file?: {
    baseName?: (params: { name: string; extname: string }) => string
    path?: (params: { baseName: string; output: Output }) => string
  }
  // plugin-specific namespaces, such as query.keyName or schema.typeName
}
```

Methods run with a `this` context bound to the full resolver, so write them as regular functions rather than arrow functions. `this.default.name(name)` runs the built-in casing your override replaced, so you can wrap it instead of rebuilding it. `this.name(name)` runs the plugin's own casing, which is what a namespaced method calls to stay in step with the top-level names.

## Rename identifiers

`name` sets the casing for every symbol the plugin generates. This override prefixes each TypeScript type with `Api` and reuses the built-in PascalCase through `this.default.name`.

```typescript twoslash [prefix.ts]
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    name(name) {
      return `Api${this.default.name(name)}`
    },
  },
})
```

## Rename and relocate files

`file.baseName` builds a file's name, extension included. Here it renames every Faker file to `<name>.mock.ts` instead of the plugin default.

```typescript twoslash [file-name.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  resolver: {
    file: {
      baseName({ name, extname }) {
        return `${name}.mock${extname}`
      },
    },
  },
})
```

`file.path` returns the file's full path and bypasses the `output.path` and `group` layout, so the resolver owns where the file lands. This override moves every Faker file into a `mocks/` folder. The returned path may not escape the project root.

```typescript twoslash [file-path.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  resolver: {
    file: {
      path({ baseName, output }) {
        return `${output.path}/mocks/${baseName}`
      },
    },
  },
})
```

## Namespaced names

A plugin that emits more than one symbol per operation groups the extra names under namespaces. `@kubb/plugin-react-query` names its query keys through `query.keyName`. It shortens the default `QueryKey` suffix to `Key` here, and `this.name` keeps the operation casing consistent with the rest of the plugin.

```typescript twoslash [query-key.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({
  resolver: {
    query: {
      keyName(node) {
        return `${this.name(node.operationId)}Key`
      },
    },
  },
})
```

`@kubb/plugin-ts` names each response type through `response.status`. This override rewrites the template so a `200` response reads `GetPetById200Response` instead of the default `GetPetByIdStatus200`.

```typescript twoslash [response.ts]
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    response: {
      status(node, statusCode) {
        return this.name(`${node.operationId} ${statusCode} response`)
      },
    },
  },
})
```

## Resolver, printer, or macro

The three options change different stages. A [macro](/docs/5.x/guide/going-further/macros) rewrites the schema node itself before anything prints, so every plugin that reads the node follows. A [printer](/docs/5.x/guide/going-further/printers) changes the code one plugin emits for a node type. A resolver leaves both the node and the printed code alone and changes only the names and file paths around them.

Reach for a resolver when the output is correct but the name or location is not, such as a prefix on every type, a `.mock.ts` suffix on Faker files, or a shorter query-key name. Reach for a printer or a macro when the generated code itself has to change.

> [!TIP]
> The three compose. A macro rewrites the node, the printer prints it, and the resolver names the symbol and file the result is written to.

## Writing your own resolver

Plugin authors create complete resolvers with `createResolver` from `kubb/kit`. Pass at least `{ pluginName }`, set `name` and `file` for the plugin's conventions, and add namespaces for the per-operation names. The built-in machinery stays reachable under `this.default`, so an override can fall back to it.

```typescript twoslash [resolver.ts]
import { createResolver } from 'kubb/kit'
import type { PluginFactoryOptions, Resolver } from 'kubb/kit'

type ResolverDocs = Resolver & {
  schema: {
    name(node: { name: string }): string
  }
}

type PluginDocs = PluginFactoryOptions<'plugin-docs', object, object, ResolverDocs>

export const resolverDocs = createResolver<PluginDocs>({
  pluginName: 'plugin-docs',
  name(name) {
    return `${name.charAt(0).toUpperCase()}${name.slice(1)}`
  },
  schema: {
    name(node) {
      return this.name(node.name)
    },
  },
})
```

Call the resolver to get the names a generator would produce. The namespaced `schema.name` delegates to the top-level `name`, so both stay on the same casing.

```typescript [Result]
resolverDocs.name('pet') // 'Pet'
resolverDocs.schema.name({ name: 'order' }) // 'Order'
```

The `resolver` plugin option layers a user patch over this built-in resolver with `Resolver.merge`, which re-binds every helper and merges each namespace member by member. That is why overriding `query.keyName` keeps the default `query.name`, and why `this.default` still reaches the untouched built-ins inside an override.

See the [Kit API reference](/docs/5.x/reference/kit#createresolver) for the helper and `Resolver.merge`, and [Plugin concepts](/docs/5.x/guide/concepts/plugins) for how a plugin registers its resolver.
