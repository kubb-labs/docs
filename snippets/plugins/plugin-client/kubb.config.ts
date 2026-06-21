import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      output: {
        path: './clients/axios',
        barrel: { type: 'named' },
        banner: '/* eslint-disable */',
      },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Service`,
      },
      resolver: {
        resolveName(name) {
          return `${this.default(name)}Client`
        },
      },
      operations: true,
      parser: false,
      exclude: [{ type: 'tag', pattern: 'store' }],
      client: 'axios',
    }),
  ],
})
