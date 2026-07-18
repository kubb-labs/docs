Toggle the export style and depth to see the generated barrels.

<BarrelTree />

Controls how the generated `index.ts` (barrel) re-exports the output. Accepts `{ type: 'named' }` or `{ type: 'all' }`, optionally with `nested: true` (for example `{ type: 'named', nested: true }`) to write an `index.ts` in every subdirectory, or `false` to skip the barrel entirely. Each generator plugin defaults `output.barrel` to `{ type: 'named' }`; the root `output.barrel` on `defineConfig` defaults to `false`.
