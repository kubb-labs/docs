---
title: 'Migration: @kubb/parser-ts'
description: What @kubb/parser-ts means when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/parser-ts`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/parser-ts`](/parsers/parser-ts).

`@kubb/parser-ts` is new in v5. It is the TypeScript and TSX printer that converts AST nodes into `.ts` and `.tsx` files, and it is wired up automatically when you import from `kubb`, so most projects need no changes. To learn how parsers fit into the layered architecture, see [Parsers](/docs/5.x/concepts/parsers).

Configure parsers through the top-level `parsers` key only when you need a custom printer. See [Core configuration](/docs/5.x/migration-guide#core-configuration) for the default layout.
