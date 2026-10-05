---
layout: doc
title: GitHub Actions
description: Inputs, outputs, runtime selection, and snapshot comments for kubb-labs/action.
outline: [2, 3]
order: 7
---

# GitHub Actions

The `kubb-labs/action@v1` action generates and publishes a Studio snapshot. See [Publish snapshots from CI](/docs/5.x/how-to/integrations/ci#github-actions) for a workflow.

## Inputs

| Input               | Default               | Description                                                             |
| ------------------- | --------------------- | ----------------------------------------------------------------------- |
| `token`             |                       | Organization CI API key. Required.                                      |
| `github-token`      | <code v-pre>${{ github.token }}</code> | Token that opens the init pull request and writes the snapshot comment. |
| `working-directory` | `.`                   | Directory holding the Kubb config and the package.                      |
| `config`            | `kubb.config.ts`      | Path to the config file, relative to `working-directory`.               |

## Outputs

| Output            | Description                                  |
| ----------------- | -------------------------------------------- |
| `snapshot-id`     | ID Studio stored the snapshot under.         |
| `package-name`    | Name of the generated package.               |
| `package-version` | Version of the generated package.            |
| `tarball-url`     | URL of the generated tarball.                |
| `integrity`       | SHA-512 integrity of the tarball.            |
| `agent-url`       | Studio URL of the CI agent that ran the job. |
| `files-added`, `files-changed`, `files-removed` | Generated files added, changed, and removed since the previous snapshot on the pull request. |

## What a run does

`kubb` runs from the repository's own `node_modules/.bin/kubb` when there is one, so the snapshot matches the version your config and plugins are built against. Otherwise it falls back to `npx`. One CI agent and one comment are reused per pull request, and one per branch.

## What the comment shows

Below the install command, the comment lists which generated files changed:

| Section | Compared with |
| --- | --- |
| Changes against `main` | The latest snapshot of the base branch, from the `push` trigger |
| Changes since `abc1234` | The previous snapshot on the same pull request |

A failed snapshot shows its error in the comment.
