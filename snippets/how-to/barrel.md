Toggle the export style and depth to see the generated barrels.

::barrel-tree
::

Controls how generated `index.ts` files re-export the output.

::field-group

:::field{name="'named'"}
Re-exports each symbol by name. Use `{ type: 'named' }` for explicit imports and tree-shaking.
:::

:::field{name="'all'"}
Re-exports every symbol with `export *`. Use `{ type: 'all' }` for wildcard exports.
:::

:::field{name="false"}
Skips barrel generation for this output.
:::

::

A plugin's `output.barrel` also accepts `nested: true`, for example `{ type: 'named', nested: true }`, so each barrel references its immediate files and subdirectory barrels. The root `output.barrel` has no `nested` option.

Kubb reads the plugin's own `output.barrel` first, falls back to `config.output.barrel` on `defineConfig`, and finally to `false`. Every generator plugin ships a default `output` that sets `barrel: { type: 'named' }`, but passing your own `output` replaces that object wholesale, so repeat `barrel` whenever you set `output` yourself.
