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

Methods run with a `this` context bound to the full, merged resolver, so write them as regular functions rather than arrow functions. `this.default.name(name)` always applies Kubb's core `camelCase` default. The plugin preset's `name` method remains separate.

From a namespaced method, `this.name(name)` calls the active top-level `name` method and follows any user override. Calling `this.name` from the top-level `name` method itself recurses, so call an exported preset resolver when you want to wrap its casing.

## Rename identifiers

`name` replaces the casing rule for every symbol the plugin generates. This override prefixes each TypeScript type with `Api` and calls `resolverTs.name` to keep the plugin's preset `PascalCase`, including for raw multiword and operation-derived names.

```typescript twoslash [prefix.ts]
import { pluginTs, resolverTs } from '@kubb/plugin-ts'

pluginTs({
  resolver: {
    name(name) {
      return `Api${resolverTs.name(name)}`
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
