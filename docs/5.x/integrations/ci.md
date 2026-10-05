---
layout: doc
title: Publish snapshots from CI
description: Publish installable Kubb Studio snapshots from GitHub Actions or
  GitLab CI and review generated-file changes.
outline:
  - 2
  - 3
---

# Publish snapshots from CI

`kubb studio snapshot` generates a package on a CI runner, publishes it to [Studio](/docs/5.x/integrations/studio), and exits. Run snapshots on pull or merge requests and the default branch so reviewers can compare their output.

## Set the token

Create an organization CI API key in Studio and store it as `KUBB_TOKEN`. On GitHub, use an Actions secret. On GitLab, use a masked CI/CD variable. Snapshot installation uses a separate `registry` API key.

Snapshots expire after seven days. Schedule a default-branch run if it can go a week without a push.

## GitHub Actions

Follow [Publish snapshots with GitHub Actions](/docs/5.x/integrations/github-actions) for a workflow that publishes snapshots and comments on pull requests. The [action reference](/docs/5.x/reference/github-actions) lists its inputs and outputs.

## GitLab CI

Follow [Publish snapshots with GitLab CI](/docs/5.x/integrations/gitlab) for the job and an optional script that posts a merge request note.

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

- [Studio setup](/docs/5.x/integrations/studio)
- [Studio command reference](/docs/5.x/reference/commands/studio)
