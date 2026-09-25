---
layout: doc
title: GitLab CI
description: Publish a Kubb snapshot from a GitLab CI job with kubb studio snapshot, and post the tarball on the merge request.
outline: [2, 3]
---

# GitLab CI

[`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) generates a package, publishes it to [Kubb Studio](./studio), and exits. A merge request needs nothing more than a job that runs it, so there is no GitLab component to install.

## Add the job

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

`kubb` ships the Studio runtime, so `npm ci` is the only setup. The `rules` run the job on merge request pipelines and on the default branch, so a merge request has a snapshot of its target branch to compare with. Snapshots expire after seven days, so add a [pipeline schedule](https://docs.gitlab.com/ci/pipelines/schedules/) on the default branch if it can go a week without a push.

`resource_group` keeps two pipelines on the same branch or merge request from running the job at once. Registering the agent again ends the other run's session.

## Set the token

Create `KUBB_TOKEN`, an organization CI API key, in Studio's settings. Add it under Settings > CI/CD > Variables as a masked variable.

## One agent per merge request

The CI agent registers as `gl:<project id>:<merge request iid>`, read from `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`, so the default branch has one agent too. Pass `--id` to group runs your own way.

A merge request pipeline also names its target branch's agent, from `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`. The snapshot reports which generated files changed against that branch's latest snapshot in `branchChanges`, and against the merge request's previous pipeline in `changes`. The commit it records is the source branch's head, `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`, when GitLab sets it.

## Post the result as a note

`--json` prints one JSON object and nothing else, carrying `url`, `name`, `version`, `integrity`, `expiresAt`, `agentUrl`, `changes`, and `branchChanges`. This script turns it into one note on the merge request and updates that note on every pipeline. It needs nothing beyond Node:

```js [scripts/kubb-note.mjs]
import { readFileSync } from 'node:fs'

const snapshot = JSON.parse(readFileSync('snapshot.json', 'utf8'))
const marker = '<!-- kubb-snapshot -->'
const counts = (c) => `${c.added.length} added · ${c.changed.length} changed · ${c.removed.length} removed`
const lines = [marker, `Kubb snapshot: \`npm i ${snapshot.url}\``]

const { branchChanges: branch, changes } = snapshot
if (branch) lines.push(branch.base ? `Changes against \`${branch.branch}\`: ${counts(branch)}` : `No snapshot of \`${branch.branch}\` to compare with yet`)
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

The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Kubb Studio](./studio): connect a project and grant permissions
- [GitHub Actions](./github-actions): the same snapshot through `kubb-labs/action`
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
