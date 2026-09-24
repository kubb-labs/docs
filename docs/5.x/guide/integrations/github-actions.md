---
layout: doc
title: GitHub Actions
description: Publish a Kubb snapshot from GitHub Actions with kubb-labs/action, and install the tarball from the pull-request comment.
outline: [2, 3]
---

# GitHub Actions

[`kubb-labs/action`](https://github.com/kubb-labs/action) runs [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) on every pull request and publishes the package to [Kubb Studio](./studio). A reviewer installs the tarball from the comment it posts, and sees which generated files the pull request changes.

<StudioCTA source="github-actions-guide" />

## Add the workflow

```yaml [.github/workflows/kubb.yml]
name: Kubb snapshot

on:
  pull_request:
  # A snapshot of main is what pull requests compare with.
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

# Runs of the same pull request or branch share one Studio agent, so run them one at a time.
concurrency:
  group: kubb-snapshot-${{ github.ref }}
  cancel-in-progress: true

jobs:
  snapshot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: kubb-labs/action@v1
        with:
          token: ${{ secrets.KUBB_TOKEN }}
```

`pull-requests: write` covers the comment. `contents: write` is only needed for the init pull request below. The `push` trigger gives `main` its own snapshot, which pull requests into `main` compare with.

## Set the token

Create `KUBB_TOKEN`, an organization CI API key, in Studio's settings. Add it under Settings > Secrets and variables > Actions.

## Inputs

| Input               | Default               | Description                                                             |
| ------------------- | --------------------- | ----------------------------------------------------------------------- |
| `token`             |                       | Organization CI API key. Required.                                      |
| `github-token`      | <code v-pre>${{ github.token }}</code> | Token that opens the init pull request and writes the snapshot comment. |
| `working-directory` | `.`                   | Directory holding the Kubb config and the package.                      |
| `config`            | `kubb.config.ts`      | Path to the config file, relative to `working-directory`.               |
| `compare-committed` | `false`               | Also compare with the generated files checked out with the repository. Passes `--allow-read`. |

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
| `branch-files-added`, `branch-files-changed`, `branch-files-removed` | Generated files the pull request adds, changes, and removes against the latest snapshot of its base branch. |

Give the step an `id`, then read an output as <code v-pre>${{ steps.snapshot.outputs.tarball-url }}</code> (using `snapshot` as the step ID).

## What a run does

`kubb` runs from the repository's own `node_modules/.bin/kubb` when there is one, so the snapshot matches the version your config and plugins are built against. Otherwise it falls back to `npx`. One CI agent and one comment are reused per pull request, and one CI agent per branch.

## What the comment shows

Below the install command, the comment lists what changed in the generated files, each behind a collapsed file list:

| Section | Compared with | Needs |
| --- | --- | --- |
| Changes against `main` | The latest snapshot of the pull request's base branch | The workflow running on pushes to that branch |
| Changes since `abc1234` | The previous snapshot on the same pull request | A second push; the first reports a first snapshot |
| Differs from the committed generated files | The generated files checked out with the repository | `compare-committed: true` |

Snapshots expire after seven days. A base branch that goes a week without a push has nothing to compare with until its next run, so add a `schedule` trigger to keep one around. The comment links the pull request's head commit.

When a snapshot fails, the comment is replaced with the end of the CLI output and a link to the run, and the step fails.

Two runs end early, and neither is a failure. A fork pull request has no secrets. A repository with no `kubb.config.ts` gets an init pull request titled `chore: initialize Kubb`, and the next run after you merge it generates a snapshot.

## Install the snapshot

The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

## See also

- [Kubb Studio](./studio): connect a project and grant permissions
- [GitLab CI](./gitlab): the same snapshot from a `.gitlab-ci.yml` job
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
