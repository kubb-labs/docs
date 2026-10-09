---
layout: doc
title: Publish a plugin
description: Build a Kubb plugin as an npm package, inspect the tarball, and publish it.
outline: [2, 3]
order: 7
navigation:
  title: Publish a plugin
  icon: i-iconoir-upload
---

# Publish a plugin

Package a plugin so other projects can install it from npm. Start from a working plugin with tests, such as the one from [Create and extend a plugin](/docs/5.x/tutorials/creating-plugins).

::steps{level="2"}

## Build the package

Export the factory from a package entrypoint. Use a `.js` extension for the relative import so the compiled ESM works in Node:

```typescript [src/index.ts]
export { pluginExample } from './plugin.js'
```

Create a TypeScript build config:

```json [tsconfig.json]
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "declaration": true,
    "skipLibCheck": true,
    "rootDir": "src",
    "outDir": "dist"
  },
  "include": ["src/index.ts", "src/plugin.ts"]
}
```

Add the following fields to your existing `package.json`, keeping the development dependencies installed earlier. Replace the package name with an available name you own before publishing:

```json [package.json fields]
{
  "name": "kubb-plugin-example",
  "version": "1.0.0",
  "type": "module",
  "files": ["dist"],
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run src/plugin.test.ts",
    "prepack": "npm run build && npm test"
  },
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js"
    }
  },
  "peerDependencies": { "kubb": "^5.0.0" }
}
```

`kubb` remains a development dependency so you can build and test locally. The peer dependency asks consumers to supply a compatible Kubb version.

Build, inspect the files npm would include, and create a local tarball:

```shell [Terminal]
npm run build
npm pack --dry-run
npm pack
```

The dry run should list `dist/index.js`, `dist/index.d.ts`, `dist/plugin.js`, and `dist/plugin.d.ts`, along with `package.json`. The tarball should contain compiled output rather than the fixture, tests, or generated client files. `prepack` runs the build and both tests before packaging.

## Publish

Add a README showing installation and `pluginExample({ prefix: 'API: ' })` in a Kubb config. Choose a license and include its file.

> [!IMPORTANT]
> Review the tarball and confirm the package name and version before publishing to npm.

When you are ready, sign in to your npm account and publish:

```shell [Terminal]
npm login
npm publish --access public
```

Consumers install your package as a development dependency and import its factory from the package name, rather than from `./src/plugin`.

::

## See also

- [Create and extend a plugin](/docs/5.x/tutorials/creating-plugins)
- [Plugin API](/docs/5.x/reference/kit/plugins)
