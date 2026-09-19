---
layout: doc
title: Local-first Kubb Studio
description: Understand where Kubb Studio generation runs, what Studio receives, and how agent permissions and CI snapshots work.
outline: [2, 3]
---

# Local-first Kubb Studio

Kubb Studio gives teams a browser interface for Kubb. Your CLI project or self-hosted agent still runs Kubb against the files and environment you control.

## Where generation runs

The `kubb studio` command runs from your project directory. The Docker agent runs the same runtime in your own container. Studio sends a generation request and receives progress, generated file paths, and only the data you allow it to read.

Use the shared sandbox for quick experiments, not for sensitive specifications. Connect a local project or self-hosted agent when the source must stay on your infrastructure.

## Permissions are explicit

A new CLI session starts with read, write, config-edit, input, and command-execution permissions disabled. Kubb asks before granting each permission and remembers the answer for that project.

| Permission | Studio can do |
| --- | --- |
| `--allow-read` | Read generated file source. |
| `--allow-write` | Write generated files to disk. |
| `--allow-config-edit` | Change supported plugin options in `kubb.config.ts`. |
| `--allow-input` | Use an OpenAPI spec Studio sends for that generation. |
| `--allow-exec` | Run the formatter, linter, and `postGenerate`. |

## Pairing and tokens

The CLI or Docker agent requests a short-lived pairing code from Studio. After you approve it in the browser, the agent receives its credential. Studio stores a token hash, not the plaintext token.

Use `kubb studio logout` to remove a local pairing. Teams can run one long-lived Docker agent instead of connecting every developer checkout. Self-hosted Studio instances use `--url`.

## CI snapshots upload the package

`kubb studio snapshot` intentionally uploads the generated package tarball to Studio so reviewers can install it. It uses an organization CI API key, not an agent token. The package download requires a separate registry API key.

This workflow intentionally sends generated output outside the CI runner. Use a self-hosted Studio instance when the package must stay inside your environment.

## See also

- [Kubb Studio](/docs/5.x/guide/integrations/studio): connect a local project, Docker agent, or CI runner
- [GitHub Actions](/docs/5.x/guide/integrations/github-actions): publish a snapshot on pull requests
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every permission and command option
