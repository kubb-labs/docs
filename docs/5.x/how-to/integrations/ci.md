---
layout: doc
title: Publish snapshots from CI
description: Publish installable Kubb Studio snapshots from GitHub Actions or
  GitLab CI and review generated-file changes.
outline:
  - 2
  - 3
order: 3
---

# Publish snapshots from CI

`kubb studio snapshot` generates a package on a CI runner, publishes it to [Studio](/docs/5.x/how-to/integrations/studio), and exits. Run snapshots on pull or merge requests and the default branch so reviewers can compare their output.

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

Review the pull request comment for generated changes against the base branch and the previous run.

To pass the tarball URL to another step, give the action an `id: snapshot`, then read <code v-pre>${{ steps.snapshot.outputs.tarball-url }}</code>. See the [action reference](/docs/5.x/reference/github-actions) for all inputs, outputs, and runtime behavior.

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

### Post the result as a note

Use `--json` to capture the snapshot result, then post it as a merge request note with this script. It updates the same note on each pipeline and uses only Node:

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


## Other CI providers

For a provider without automatic agent identification, use a stable `--id` on the base branch and pass it as `--base-id` on pull request runs:

```shell [Terminal]
kubb studio snapshot --id jenkins:api:main                              # on main
kubb studio snapshot --id jenkins:api:pr-12 --base-id jenkins:api:main  # on a pull request
```

Use `kubb studio snapshot --json | jq -r '.url'` to pass the tarball URL to another step. See [CI agent identity](/docs/5.x/reference/commands/studio#ci-agent-identity) for automatic provider detection and [Snapshot output](/docs/5.x/reference/commands/studio#snapshot-output) for the result fields.

## Install the snapshot

Configure the registry API key, then run the install command from the snapshot result:

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Studio setup](/docs/5.x/how-to/integrations/studio)
- [Studio command reference](/docs/5.x/reference/commands/studio)
