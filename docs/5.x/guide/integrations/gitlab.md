---
layout: doc
title: GitLab CI
description: Publish a Kubb snapshot from a GitLab CI job with kubb studio snapshot, and post the tarball on the merge request.
outline: [2, 3]
---

# GitLab CI

There is no GitLab component to install. [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) generates a package, publishes it to [Kubb Studio](./studio), and exits, so a merge request needs nothing more than a job that runs it.

A reviewer installs that tarball and runs the generated client against the branch, instead of reading a diff of generated files.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

## Add the job

```yaml [.gitlab-ci.yml]
snapshot:
  stage: build
  image: node:22
  script:
    - npm ci
    - npx kubb studio snapshot
  rules:
    - if: $CI_MERGE_REQUEST_IID
```

`kubb` ships the Studio runtime, so `npm ci` is the only setup the job needs. The `rules` entry keeps it on merge request pipelines, where a snapshot has a reviewer to reach.

## Set the token

The command reads an organization CI API key from `KUBB_TOKEN`. Create it in Studio's settings, then add it under Settings > CI/CD > Variables as a masked variable so GitLab keeps it out of the job log.

It is not the agent token that pairs a developer machine with Studio, and not the registry key that downloads a tarball.

Point at a self-hosted Studio with `--url https://studio.internal.example`.

## One agent per merge request

`snapshot` reads `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID` and registers the CI agent as `gl:<project id>:<merge request iid>`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`. Pass `--id` to group runs your own way.

## Post the result as a note

`--json` prints one JSON object on stdout and nothing else, carrying `url`, `name`, `version`, `integrity`, `expiresAt`, and `agentUrl`.

```yaml [.gitlab-ci.yml]
  script:
    - npm ci
    - npx kubb studio snapshot --json > snapshot.json
    - |
      curl --fail --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
        --data-urlencode "body=Kubb snapshot: $(jq -r '.url' snapshot.json)" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes"
```

Writing a note needs a project access token with the `api` scope, held in a masked variable of its own. `CI_JOB_TOKEN` does not carry that permission.

## Install the snapshot

The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitHub Actions](./github-actions): the same snapshot through `kubb-labs/action`
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
