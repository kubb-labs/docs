#!/usr/bin/env bash
# Fails if any markdown page (other than the migration guide) pins a kubb
# package to a specific version in an install command, e.g.
# `npm install kubb@5.0.0` or `pnpm add -D @kubb/plugin-ts@5.0.0`.
# npm's `latest` tag always resolves to the current major, so install
# commands should stay unpinned. The migration guide is the one place a
# pin is intentional: it documents the exact v4 -> v5 upgrade path.
set -euo pipefail

allowed_file="docs/5.x/migration.md"
pattern='(^|[^A-Za-z0-9._-])(kubb|@kubb/[a-zA-Z0-9-]+)@[0-9]+\.[0-9]+\.[0-9]+'

matches=$(grep -rEn "$pattern" --include='*.md' \
  --exclude-dir=node_modules \
  docs plugins adapters parsers blog \
  | grep -v "^${allowed_file}:" || true)

if [[ -n "$matches" ]]; then
  echo "Found pinned kubb package versions outside ${allowed_file}:"
  echo "$matches"
  echo
  echo "Remove the version pin (e.g. \`kubb@5.0.0\` -> \`kubb\`) unless this is the migration guide."
  exit 1
fi

echo "No stray kubb version pins found."
