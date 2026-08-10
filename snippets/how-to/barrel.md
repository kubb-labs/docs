Toggle the export style and depth to see the generated barrels.

<BarrelTree />

Controls how the generated `index.ts` (barrel) re-exports the output. Accepts `{ type: 'named' }` or `{ type: 'all' }`, optionally with `nested: true` (for example `{ type: 'named', nested: true }`) to write an `index.ts` in every subdirectory, or `false` to skip the barrel entirely. Kubb reads the plugin's own `output.barrel` first, falls back to `config.output.barrel` on `defineConfig`, and finally to `false`. Every generator plugin ships a default `output` that sets `barrel: { type: 'named' }`, but passing your own `output` replaces that object wholesale, so repeat `barrel` whenever you set `output` yourself.
