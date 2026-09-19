---
layout: doc
title: Local-first Kubb Studio
description: Understand where Kubb Studio generation runs, what Studio receives, and how agent permissions and CI snapshots work.
outline: [2, 3]
---

# Local-first Kubb Studio

Kubb Studio gives teams a browser interface for Kubb. It does not move your generator into the hosted app: your CLI project or self-hosted agent runs Kubb against the files and environment you control.

## Where generation runs

`kubb studio` runs from your project directory. The Docker agent runs the same runtime in your own container. Studio sends a generation request and receives progress, generated file paths, and only the data you explicitly allow it to read.

The shared sandbox is for quick experiments. Do not use it for sensitive specifications. Connect your local project or a self-hosted agent when the source must stay on your infrastructure.

## Permissions stay explicit

A new CLI session starts without read, write, config-edit, input, or command-execution permissions. Kubb asks before it grants each permission and saves the answer for that project.

| Permission | Studio can do |
| --- | --- |
| `--allow-read` | Read generated file source. |
| `--allow-write` | Write generated files to disk. |
| `--allow-config-edit` | Change supported plugin options in `kubb.config.ts`. |
| `--allow-input` | Use an OpenAPI spec Studio sends for that generation. |
| `--allow-exec` | Run the formatter, linter, and `postGenerate`. |

## Pairing and tokens

The CLI or Docker agent asks Studio for a short-lived pairing code. A user approves it in the browser, then the agent receives its credential. Studio stores a token hash, not the plaintext token.

Use `kubb studio logout` to remove a local pairing. Teams can run a long-lived Docker agent instead of connecting each developer checkout separately. Self-hosted Studio instances work through `--url`.

## CI snapshots are different

`kubb studio snapshot` intentionally uploads the generated package tarball to Studio so reviewers can install it. It uses an organization CI API key, not an agent token. The package download requires a separate registry API key.

This is the one workflow where generated output leaves the CI runner by design. Use a self-hosted Studio instance when that package must remain inside your environment.

## See also

- [Kubb Studio](/docs/5.x/guide/integrations/studio): connect a local project, Docker agent, or CI runner
- [GitHub Actions](/docs/5.x/guide/integrations/github-actions): publish a snapshot on pull requests
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every permission and command option
