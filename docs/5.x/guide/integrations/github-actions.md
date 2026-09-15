---
layout: doc
title: GitHub Actions
description: Publish a Kubb snapshot from GitHub Actions with kubb-labs/action, and install the tarball from the pull-request comment.
outline: [2, 3]
---

# GitHub Actions

[`kubb-labs/action`](https://github.com/kubb-labs/action) generates a package from your spec on every pull request and publishes it to [Kubb Studio](./studio). A reviewer installs the tarball from a comment on the pull request and runs the generated client before the branch merges.

The action runs [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) and adds the GitHub parts: the comment, and an init pull request when the repository has no config yet.

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

`pull-requests: write` covers the comment. `contents: write` is only there for the init pull request, so you can drop it once the repository has a `kubb.config.ts`.

## Set the token

`KUBB_TOKEN` is an organization CI API key. Create it in Studio's settings and add it under Settings > Secrets and variables > Actions. It is not the agent token that pairs a developer machine with Studio, and not the registry key that downloads a tarball.

Set `KUBB_STUDIO_URL` on the step for a self-hosted Studio. The default is `https://kubb.studio`.

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

Give the step an `id`, then read an output as `${{ steps.<id>.outputs.tarball-url }}`.

## What a run does

The action runs `kubb` from the repository's own `node_modules/.bin/kubb` when there is one, so a snapshot uses the Kubb version your config and plugins are built against. Without a local install it falls back to `npx`.

It reuses one CI agent per pull request, and edits one comment instead of adding another.

Two runs end early, and neither is a failure. A fork pull request has no secrets to publish with. A repository with no `kubb.config.ts` gets an init pull request titled `chore: initialize Kubb` instead, and the next run after you merge it generates a snapshot.

## Install the snapshot

The comment carries an `npm i` line with the tarball URL. The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitLab CI](./gitlab): the same snapshot from a `.gitlab-ci.yml` job
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
