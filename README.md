# kubb-docs

Hand-written content for [kubb.dev](https://kubb.dev). The [platform](https://github.com/kubb-labs/platform) fetches and renders these pages with VitePress.

## Repository layout

```
docs/
├── docs/5.x/              # Guides, concepts, API reference, integrations
│   ├── getting-started/   # Installation, introduction, basic usage
│   ├── guides/            # How-to guides and worked examples
│   ├── concepts/          # Architecture and concepts
│   ├── reference/         # Configuration reference and diagnostics
│   ├── integrations/      # Bundler integrations (Vite, Nuxt, webpack, ...)
│   ├── api/               # Core API reference
│   ├── ai/                # AI integrations (Claude, MCP, llms.txt)
│   └── resources/         # Ecosystem and external resources
├── plugins/               # Plugin docs (plugin-ts, plugin-client, ...)
├── adapters/              # Adapter docs (adapter-oas)
├── parsers/               # Parser docs (parser-ts, parser-md)
├── blog/                  # Blog posts (v3.md, v4.md, v5.md, ...)
└── snippets/              # Code snippets included via <<< @/snippets/...
```

## Authoring reference

### Frontmatter keys

| Key | Values | Description |
| --- | --- | --- |
| `layout` | `doc` | Page layout — always `doc` for content pages |
| `title` | string | Page title (shown in `<title>` and nav) |
| `description` | string | Meta description for SEO |
| `outline` | `2`, `[2, 3]`, `deep` | Which heading levels appear in the right nav |
| `kind` | `plugin`, `adapter`, `parser` | Extension type — drives sidebar icons and badges |
| `id` | string | Unique extension identifier (e.g. `plugin-ts`) |

### Admonitions

Use VitePress [custom containers](https://vitepress.dev/guide/markdown#custom-containers):

```md
> [!NOTE]
> Use for supplementary information that is helpful but not critical.

> [!TIP]
> Use for suggestions and recommended practices.

> [!WARNING]
> Use for content that may cause issues if ignored.

> [!IMPORTANT]
> Use for content that is required for correct behavior.
```

### Multi-tab code blocks

````md
::: code-group

```shell [pnpm]
pnpm add -D @kubb/plugin-ts
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts
```

:::
````

### Snippet includes

Reusable snippets live under `snippets/` and are included with the VitePress `<<<` syntax:

```md
<<< @/snippets/plugins/plugin-client/basic.ts
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full contributing guide.

## The Kubb ecosystem

- [kubb-labs/kubb](https://github.com/kubb-labs/kubb) — core engine, CLI, OpenAPI adapter, AST layer
- [kubb-labs/plugins](https://github.com/kubb-labs/plugins) — official plugins (TypeScript, client, React Query, Zod, Faker, MSW, ...)
- [kubb-labs/platform](https://github.com/kubb-labs/platform) — documentation site, Kubb Studio

## License

[MIT](./LICENSE)
