---
layout: doc
title: JSX renderer
description: The kubb/jsx surface backed by @kubb/renderer-jsx. jsxRenderer, the built-in components, and the JSX runtime for component-based code generation.
outline: [2, 3]
---

# JSX renderer

`kubb/jsx` is Kubb's JSX-based renderer, an alternative to building files with the `ast.factory` node builders from [`kubb/kit`](/docs/5.x/reference/kit). It provides a JSX runtime and a set of built-in components so a generator can emit files and markdown through JSX instead of composing AST nodes by hand.

## Setup

Point your `tsconfig.json` at the `kubb/jsx` runtime so JSX syntax compiles against its components instead of React's:

```json [tsconfig.json]
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "jsxImportSource": "kubb/jsx"
  }
}
```

With that in place, `.tsx` files in the plugin resolve `jsx-runtime` and `jsx-dev-runtime` from `kubb/jsx` automatically.

## `jsxRenderer()`

`jsxRenderer` creates a renderer instance with three members: `render`, `files`, and `stream`. Call `render` with a JSX element, then read the generated files back off `files`.

```tsx twoslash [render.tsx]
import { jsxRenderer } from 'kubb/jsx'
import { File, Function, Type } from 'kubb/jsx'

const renderer = jsxRenderer()

await renderer.render(
  <File baseName="petStore.ts" path="src/gen/petStore.ts">
    <File.Source>
      <Type name="Pet">{'{ id: number; name: string }'}</Type>
      <Function name="getPet" async>
        {"return fetch('/pets')"}
      </Function>
    </File.Source>
  </File>,
)

const files = renderer.files
```

Use `stream(element)` instead of `render` when you want files as they are produced rather than buffered into one array. `stream` yields each `FileNode` in turn, which suits large trees or a plugin that wants to react to files as they land.

## Built-in components

| Component | Description |
| --- | --- |
| `File` | Declares a generated output file, with its path and optional imports and exports |
| `File.Source` | The source content block nested inside a `File` |
| `Function` | Generates a TypeScript function declaration |
| `Type` | Generates a TypeScript type alias |
| `Const` | Generates a `const` variable declaration |
| `Jsx` | Renders JSX expressions inside the generated output |
| `Callout` | Generates a callout block in markdown output |
| `Frontmatter` | Generates a frontmatter block in markdown output |
| `Heading` | Generates a heading in markdown output |
| `List` | Generates a list in markdown output |
| `Paragraph` | Generates a paragraph in markdown output |

`Callout`, `Frontmatter`, `Heading`, `List`, and `Paragraph` target markdown output. The rest emit TypeScript.

### Markdown output

The markdown components go directly inside a `<File>` instead of a `<File.Source>`, since each one emits its own source block. Render the file with `parserMd` so it is written as markdown.

```tsx twoslash [docs.tsx]
import { jsxRenderer } from 'kubb/jsx'
import { File, Frontmatter, Heading, Paragraph, List, Callout } from 'kubb/jsx'

const renderer = jsxRenderer()

await renderer.render(
  <File baseName="pets.md" path="src/docs/pets.md">
    <Frontmatter data={{ title: 'Pets', layout: 'doc' }} />
    <Heading level={2}>Pets</Heading>
    <Paragraph>{'A pet object with an id and a name.'}</Paragraph>
    <List items={['id: number', 'name: string']} />
    <Callout type="tip">Keep the generator hot with kubb start --watch.</Callout>
  </File>,
)
```

## Types

`KubbReactNode` is the JSX node type this renderer accepts. Use it to type a component's `children` or a helper that returns JSX. Each component's props type follows the `Kubb<Component>Props` convention, for example `KubbFileProps` for `File` and `KubbTypeProps` for `Type`.

## Package

`kubb/jsx` re-exports [`@kubb/renderer-jsx`](https://www.npmjs.com/package/@kubb/renderer-jsx). The underlying package stays directly installable and importable for projects that prefer not to depend on the `kubb` meta-package.

## See also

- [Kit API](/docs/5.x/reference/kit) for `defineGenerator`'s `renderer` field and the `ast.factory` alternative to JSX
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for how a generator wires a renderer into its output
- [Kit API: rendering](/docs/5.x/reference/kit#jsxrenderer-via-kubb-jsx) for how `jsxRenderer` sits next to `createRenderer`
