---
layout: doc
title: KUBB_BARREL_DUPLICATE_EXPORT
description: The KUBB_BARREL_DUPLICATE_EXPORT diagnostic fires when two files in the same barrel directory export the same name, preventing the barrel from re-exporting both.
outline: [2, 3]
---

# KUBB_BARREL_DUPLICATE_EXPORT: Duplicate barrel export

Code: KUBB_BARREL_DUPLICATE_EXPORT
Level: error

Two files in the same barrel directory export the same name. Re-exporting both creates duplicate export bindings in the generated index.ts, which causes a TypeScript or JavaScript parse error when imported.

## What happened

When @kubb/plugin-barrel builds an index.ts barrel file for a directory, it collects the export declarations from every file in that directory. If two files export an identifier with the same name (and both are values or both are types), the barrel cannot re-export both without creating a syntax collision.

Kubb reports this diagnostic and drops the duplicate export from the barrel index so the generated code continues to parse. Value exports and type exports sharing a name in the same directory do not trigger this error, as TypeScript allows type and value bindings to share an identifier.

## Common causes

- Two separate operations or schemas generate files into the same directory with identical export names (for example, createPetResponse exported in both createPet.ts and createPetResponse.ts).
- Multiple plugins configured to write into the same output folder without unique export names.
- A custom resolver names two distinct OpenAPI entities identically within the same target folder.

## How to fix it

- Rename one of the colliding operations or schemas in your OpenAPI document.
- Configure custom name resolvers or transformers in your plugin options to disambiguate names.
- Separate files into different folders using group or distinct plugin output.path settings.

## Example output

`	ext [Terminal]
[KUBB_BARREL_DUPLICATE_EXPORT]: createPetResponse is exported by both /workspace/src/gen/createPet.ts and /workspace/src/gen/createPetResponse.ts, so /workspace/src/gen/index.ts cannot re-export both.
  fix: Rename one of the colliding declarations, or resolve the collision through the plugin resolver that names them.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-barrel-duplicate-export
`

## See also

- [Barrel plugin](/plugins/plugin-barrel)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
