---
layout: doc
title: GitHub Actions
description: Publish a Kubb snapshot from GitHub Actions with kubb-labs/action. Covers the workflow, the CI token, inputs and outputs, the pull-request comment, and installing the tarball.
outline: [2, 3]
---

# GitHub Actions

[`kubb-labs/action`](https://github.com/kubb-labs/action) generates a package from your spec on every pull request and publishes it to [Kubb Studio](./studio). A reviewer installs the tarball straight from a comment on the pull request and runs the generated client before the branch merges.

The action runs [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions), the same command any CI can run. What it adds is the GitHub part: one comment per pull request, and an init pull request when the repository has no config yet.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

## Add the workflow

```yaml [.github/workflows/kubb.yml]
name: Kubb snapshot

on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  snapshot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: kubb-labs/action@v1
        with:
          token: ${{ secrets.KUBB_TOKEN }}
```

`pull-requests: write` covers the snapshot comment. `contents: write` is only there for the init pull request, so you can drop it once the repository has a `kubb.config.ts`.

## Set the token

`KUBB_TOKEN` is an organization CI API key. Create it in Studio's settings and add it under Settings > Secrets and variables > Actions. It is neither the agent token that pairs a developer machine with Studio, nor the registry key that downloads a tarball.

For a self-hosted Studio, point the action at it with `KUBB_STUDIO_URL`. The default is `https://kubb.studio`.

```yaml [.github/workflows/kubb.yml]
    steps:
      - uses: actions/checkout@v5
      - uses: kubb-labs/action@v1
        env:
          KUBB_STUDIO_URL: https://studio.internal.example
        with:
          token: ${{ secrets.KUBB_TOKEN }}
```

## Inputs

| Input               | Default               | Description                                                             |
| ------------------- | --------------------- | ----------------------------------------------------------------------- |
| `token`             |                       | Organization CI API key. Required.                                      |
| `github-token`      | `${{ github.token }}` | Token that opens the init pull request and writes the snapshot comment. |
| `working-directory` | `.`                   | Directory holding the Kubb config and the package.                      |
| `config`            | `kubb.config.ts`      | Path to the config file, relative to `working-directory`.               |

Set `working-directory` when the config lives in a workspace package rather than the repository root.

## Outputs

| Output            | Description                                  |
| ----------------- | -------------------------------------------- |
| `snapshot-id`     | ID Studio stored the snapshot under.         |
| `package-name`    | Name of the generated package.               |
| `package-version` | Version of the generated package.            |
| `tarball-url`     | URL of the generated tarball.                |
| `integrity`       | SHA-512 integrity of the tarball.            |
| `agent-url`       | Studio URL of the CI agent that ran the job. |

Give the step an `id` to read them later in the job:

```yaml [.github/workflows/kubb.yml]
    steps:
      - uses: actions/checkout@v5
      - uses: kubb-labs/action@v1
        id: kubb
        with:
          token: ${{ secrets.KUBB_TOKEN }}
      - run: echo "${{ steps.kubb.outputs.tarball-url }}"
```

## What a run does

The action resolves `kubb` from the repository's own `node_modules/.bin/kubb` when there is one, so a snapshot uses the Kubb version your config and plugins are built against. A repository with no local install falls back to `npx --package @kubb/cli --package @kubb/studio kubb`.

It registers the CI agent as `gh:<repository id>:<pull request number>`. Every run on one pull request reuses that agent instead of registering a new one, and every run edits the same comment instead of adding another.

Two cases end the run early, and neither is a failure:

- A pull request from a fork. GitHub withholds repository secrets there, so there is no key to publish with.
- A repository with no `kubb.config.ts`. The action runs `kubb init`, pushes a `kubb/init-<run id>` branch, and opens a pull request titled `chore: initialize Kubb`. Merge it, and the next run generates a snapshot. While that pull request is open, later runs leave it alone.

## Install the snapshot

The comment carries an `npm i` line with the tarball URL. The download needs a `registry` API key rather than the `ci` key that created the snapshot, because the tarball is private to your organization.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

npm sends that token as a bearer token, which is what the download endpoint expects.

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitLab CI](./gitlab): the same snapshot from a `.gitlab-ci.yml` job
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
