---
layout: doc
title: KUBB_BARREL_DUPLICATE_EXPORT
description: The KUBB_BARREL_DUPLICATE_EXPORT diagnostic fires when two files in the same barrel directory export the same name.
outline: [2, 3]
---

# KUBB_BARREL_DUPLICATE_EXPORT: Duplicate barrel export

Code: `KUBB_BARREL_DUPLICATE_EXPORT`
Level: error

Two files in the same barrel directory export the same name. The barrel keeps the first export and drops the rest, so the generated code still parses, but the run is marked failed.

## What happened

The barrel plugin builds an `index.ts` per directory from every file's exports. Two files exporting the same name collide, unless one is a type and the other a value, which TypeScript allows. Kubb reports one diagnostic per collision and keeps only the first export.

## How to fix it

- Rename one of the colliding declarations, or configure the plugin resolver to produce distinct names.
- Split the conflicting files into separate output directories, for example with a plugin's `group` or `output.path` option.

## Common causes

- Two operations or schemas resolve to the same export name in one output directory.
- Multiple plugins write into the same folder without unique export names.
- A custom name resolver assigns the same name to two different OpenAPI entities in one folder.

## Example output

```text [Terminal]
[KUBB_BARREL_DUPLICATE_EXPORT]: "createPetResponse" is exported by both "createPet.ts" and "createPetResponse.ts", so "index.ts" cannot re-export both.
  fix: Rename one of the colliding declarations, or configure the plugin resolver to produce distinct names.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-barrel-duplicate-export
```

## See also

- [Barrel files](/docs/5.x/guide/going-further/barrel-files)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
