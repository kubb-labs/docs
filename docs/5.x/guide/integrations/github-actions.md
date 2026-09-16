---
layout: doc
title: GitHub Actions
description: Publish a Kubb snapshot from GitHub Actions with kubb-labs/action, and install the tarball from the pull-request comment.
outline: [2, 3]
---

# GitHub Actions

[`kubb-labs/action`](https://github.com/kubb-labs/action) runs [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) on every pull request and publishes the package to [Kubb Studio](./studio). A reviewer installs the tarball from the comment it posts.

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

`pull-requests: write` covers the comment. `contents: write` is only needed for the init pull request below.

## Set the token

Create `KUBB_TOKEN`, an organization CI API key, in Studio's settings. Add it under Settings > Secrets and variables > Actions.

Set `KUBB_STUDIO_URL` on the step for a self-hosted Studio. The default is `https://kubb.studio`.

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

Give the step an `id`, then read an output as <code v-pre>${{ steps.snapshot.outputs.tarball-url }}</code> (using `snapshot` as the step ID).

## What a run does

`kubb` runs from the repository's own `node_modules/.bin/kubb` when there is one, so the snapshot matches the version your config and plugins are built against. Otherwise it falls back to `npx`. One CI agent and one comment are reused per pull request.

Two runs end early, and neither is a failure. A fork pull request has no secrets. A repository with no `kubb.config.ts` gets an init pull request titled `chore: initialize Kubb`, and the next run after you merge it generates a snapshot.

## Install the snapshot

The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitLab CI](./gitlab): the same snapshot from a `.gitlab-ci.yml` job
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
