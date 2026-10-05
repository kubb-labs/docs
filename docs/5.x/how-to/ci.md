---
layout: doc
title: Publish snapshots from CI
description: Publish installable Kubb Studio snapshots from GitHub Actions or
  GitLab CI and review generated-file changes.
outline:
  - 2
  - 3
order: 7
---

# Publish snapshots from CI

`kubb studio snapshot` generates a package on a CI runner, publishes it to [Studio](/docs/5.x/how-to/studio), and exits. Run snapshots on pull or merge requests and the default branch so reviewers can compare their output.

## Set the token

Create an organization CI API key in Studio and store it as `KUBB_TOKEN`. On GitHub, use an Actions secret. On GitLab, use a masked CI/CD variable. Snapshot installation uses a separate `registry` API key.

Snapshots expire after seven days. Schedule a default-branch run if it can go a week without a push.


## GitHub Actions

Add this workflow:

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

# Runs of one pull request or branch share a Studio agent, so run them one at a time.
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

`pull-requests: write` allows snapshot comments. `contents: write` lets the action open an initialization pull request when the repository has no Kubb config.

### Inputs

| Input               | Default               | Description                                                             |
| ------------------- | --------------------- | ----------------------------------------------------------------------- |
| `token`             |                       | Organization CI API key. Required.                                      |
| `github-token`      | <code v-pre>${{ github.token }}</code> | Token that opens the init pull request and writes the snapshot comment. |
| `working-directory` | `.`                   | Directory holding the Kubb config and the package.                      |
| `config`            | `kubb.config.ts`      | Path to the config file, relative to `working-directory`.               |

### Outputs

| Output            | Description                                  |
| ----------------- | -------------------------------------------- |
| `snapshot-id`     | ID Studio stored the snapshot under.         |
| `package-name`    | Name of the generated package.               |
| `package-version` | Version of the generated package.            |
| `tarball-url`     | URL of the generated tarball.                |
| `integrity`       | SHA-512 integrity of the tarball.            |
| `agent-url`       | Studio URL of the CI agent that ran the job. |
| `files-added`, `files-changed`, `files-removed` | Generated files added, changed, and removed since the previous snapshot on the pull request. |

Give the step an `id`, then read an output as <code v-pre>${{ steps.snapshot.outputs.tarball-url }}</code> (using `snapshot` as the step ID).

### What a run does

`kubb` runs from the repository's own `node_modules/.bin/kubb` when there is one, so the snapshot matches the version your config and plugins are built against. Otherwise it falls back to `npx`. One CI agent and one comment are reused per pull request, and one per branch.

### What the comment shows

Below the install command, the comment lists which generated files changed:

| Section | Compared with |
| --- | --- |
| Changes against `main` | The latest snapshot of the base branch, from the `push` trigger |
| Changes since `abc1234` | The previous snapshot on the same pull request |

A failed snapshot shows its error in the comment.


## GitLab CI

Add this job:

```yaml [.gitlab-ci.yml]
snapshot:
  stage: build
  image: node:22
  resource_group: kubb-snapshot-$CI_COMMIT_REF_SLUG
  script:
    - npm ci
    - npx kubb studio snapshot
  rules:
    - if: $CI_MERGE_REQUEST_IID
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

`kubb` ships the Studio runtime, so `npm ci` is the only setup. The `rules` run the job on merge request pipelines and on the default branch, so a merge request has a snapshot of its target branch to compare with.

`resource_group` keeps two pipelines on the same branch or merge request from running the job at once. Registering the agent again ends the other run's session.

### One agent per merge request

The CI agent registers as `gl:<project id>:<merge request iid>`, read from `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`, so the default branch has one agent too. Pass `--id` to group runs your own way.

A merge request pipeline also names its target branch's agent, from `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`. The snapshot reports which generated files changed against that branch's latest snapshot in `branchChanges`, and against the merge request's previous pipeline in `changes`. The commit it records is the source branch's head, `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`, when GitLab sets it.

### Post the result as a note

`--json` prints one JSON object and nothing else. It includes `id`, `name`, `version`, `integrity`, `url`, `snapshotIdUrl`, `expiresAt`, and `agentUrl`, plus `changes` and `branchChanges` when available. This script turns it into one note on the merge request and updates that note on every pipeline. It needs nothing beyond Node:

```js [scripts/kubb-note.mjs]
import { readFileSync } from 'node:fs'

const snapshot = JSON.parse(readFileSync('snapshot.json', 'utf8'))
const marker = '<!-- kubb-snapshot -->'
const counts = (c) => `${c.added.length} added · ${c.changed.length} changed · ${c.removed.length} removed`
const lines = [marker, `Kubb snapshot: \`npm i ${snapshot.url}\``]

const { branchChanges: branch, changes } = snapshot
if (branch) {
  if (branch.base) lines.push(`Changes against \`${branch.branch}\`: ${counts(branch)}`)
  else if (branch.baseFound) lines.push(`No snapshot of \`${branch.branch}\` for this package yet`)
  else lines.push(`No snapshot of \`${branch.branch}\` to compare with`)
}
if (changes?.base) lines.push(`Changes since ${changes.base.commit?.slice(0, 7) ?? changes.base.createdAt}: ${counts(changes)}`)

const { CI_API_V4_URL, CI_PROJECT_ID, CI_MERGE_REQUEST_IID, GITLAB_API_TOKEN } = process.env
const notes = `${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes`
const headers = { 'PRIVATE-TOKEN': GITLAB_API_TOKEN, 'Content-Type': 'application/json' }
const existing = (await (await fetch(`${notes}?per_page=100`, { headers })).json()).find((note) => note.body.startsWith(marker))
const response = await fetch(existing ? `${notes}/${existing.id}` : notes, {
  method: existing ? 'PUT' : 'POST',
  headers,
  body: JSON.stringify({ body: lines.join('\n\n') }),
})
if (!response.ok) throw new Error(`GitLab answered ${response.status}`)
```

```yaml [.gitlab-ci.yml]
  script:
    - npm ci
    - npx kubb studio snapshot --json > snapshot.json
    - '[ -z "$CI_MERGE_REQUEST_IID" ] || node scripts/kubb-note.mjs'
```

Writing a note needs a project access token with the `api` scope, stored as `GITLAB_API_TOKEN`. `CI_JOB_TOKEN` does not carry it.


## Install the snapshot

Configure the registry API key, then run the install command from the snapshot result:

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Studio setup](/docs/5.x/how-to/studio)
- [Studio command reference](/docs/5.x/reference/commands/studio)
