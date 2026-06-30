<div align="center">
  <a href="https://kubb.dev" target="_blank" rel="noopener noreferrer">
    <img src="https://kubb.dev/og.png" alt="Kubb banner">
  </a>

[![Stars][stars-src]][stars-href]
[![License][license-src]][license-href]
[![OC Backers][oc-backers-src]][oc-backers-href]

  <h4>
    <a href="https://kubb.dev" target="_blank">Documentation</a>
    <span> · </span>
    <a href="https://github.com/kubb-labs/docs/issues/" target="_blank">Report Bug</a>
    <span> · </span>
    <a href="https://github.com/kubb-labs/docs/issues/" target="_blank">Request Feature</a>
  </h4>
</div>

<br />

# Kubb Docs

**Documentation content for [Kubb](https://kubb.dev), the meta framework for code generation.**

This repository holds the raw markdown documentation files that power [kubb.dev](https://kubb.dev). Content is organized by category: plugins, adapters, parsers, and versioned docs.

Want to improve the docs? See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Features

- Generate [TypeScript types](https://kubb.dev/plugins/plugin-ts), [React Query](https://kubb.dev/plugins/plugin-react-query) and [Vue Query](https://kubb.dev/plugins/plugin-vue-query) hooks, [SWR](https://kubb.dev/plugins/plugin-swr) hooks, [Zod](https://kubb.dev/plugins/plugin-zod) validators, [Faker](https://kubb.dev/plugins/plugin-faker) mocks, and [MSW](https://kubb.dev/plugins/plugin-msw) handlers, each from its own plugin.
- Generate a typed [Axios](https://kubb.dev/plugins/plugin-axios) or [Fetch](https://kubb.dev/plugins/plugin-fetch) client with status-keyed results, auth, validation, file uploads, server-sent events, interceptors, and a swappable transport.
- Read any OpenAPI 2.0, 3.0, or 3.1 spec through the [OpenAPI adapter](https://kubb.dev/adapters/adapter-oas), or add your own adapter.
- Shape the output by grouping files by tag or path, emitting barrel files, and including or excluding operations.
- Generate [Cypress](https://kubb.dev/plugins/plugin-cypress) tests and a [Model Context Protocol server](https://kubb.dev/plugins/plugin-mcp), or write your own plugin.
- Run generation in Vite, Nuxt, and other bundlers with `unplugin-kubb`, or from AI assistants and Claude Code.

## Content

| Directory | Description |
|-----------|-------------|
| [`plugins/`](./plugins/) | Plugin reference pages |
| [`adapters/`](./adapters/) | Adapter reference pages |
| [`parsers/`](./parsers/) | Parser reference pages |
| [`docs/5.x/`](./docs/5.x/) | Versioned documentation for Kubb v5 |

## Contributing

Found a mistake or want to improve the docs? We welcome contributions:

- Found an error? File it in the [issue tracker](https://github.com/kubb-labs/docs/issues).
- Have a suggestion? [Open an issue](https://github.com/kubb-labs/docs/issues/new).
- Need help? Ask the community on [Discord](https://discord.gg/4dQjA6vrWX).

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details on the repo structure and how to submit changes.

## Sponsors

Kubb's development is funded by sponsors. To support the project, [become a sponsor on GitHub](https://github.com/sponsors/stijnvanhulle) or [back us on Open Collective](https://opencollective.com/kubb).

<p align="center">
  <a href="https://github.com/sponsors/stijnvanhulle">
    <img src="https://shieldcn.dev/sponsors/stijnvanhulle.svg?titleAlign=center&mode=dark" alt="stijnvanhulle sponsors" width="100%" />
  </a>
</p>

## License

[MIT](./LICENSE) © [Stijn Van Hulle](https://github.com/stijnvanhulle)

## Star history

<img alt="Star history chart" src="https://shieldcn.dev/chart/github/stars/kubb-labs/docs.svg?theme=orange" width="100%" />

<!-- Badges -->

[stars-src]: https://shieldcn.dev/github/stars/kubb-labs/docs.svg?variant=secondary&size=xs&theme=zinc&mode=dark
[stars-href]: https://github.com/kubb-labs/docs
[license-src]: https://shieldcn.dev/github/license/kubb-labs/docs.svg?variant=secondary&size=xs&theme=zinc
[license-href]: https://github.com/kubb-labs/docs/blob/main/LICENSE
[oc-backers-src]: https://shieldcn.dev/opencollective/backers/kubb.svg?variant=secondary&size=xs&theme=zinc&mode=dark
[oc-backers-href]: https://opencollective.com/kubb
