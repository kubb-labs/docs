Toggle the export style and depth to see the generated barrels.

<BarrelTree />

Controls how the generated `index.ts` (barrel) re-exports the output. Defaults to `false` (no barrel), and also accepts `{ type: 'named' }` or `{ type: 'all' }`, optionally with `nested: true` (for example `{ type: 'named', nested: true }`) to write an `index.ts` in every subdirectory.
