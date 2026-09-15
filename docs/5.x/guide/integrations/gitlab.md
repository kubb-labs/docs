---
layout: doc
title: GitLab CI
description: Publish a Kubb snapshot from a GitLab CI job with kubb studio snapshot. Covers the job, the masked CI token, one agent per merge request, and posting the result as a note.
outline: [2, 3]
---

# GitLab CI

There is no GitLab component to install. [`kubb studio snapshot`](/docs/5.x/reference/commands/studio#actions) generates a package, publishes it to [Kubb Studio](./studio), and exits, so a merge request needs nothing more than a job that runs it.

A reviewer then installs that tarball and runs the generated client against the branch, rather than reading a diff of generated files.

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

Install dependencies first. `kubb` ships the Studio runtime, so the job then runs the Kubb version your config and plugins are built against. The `rules` entry keeps the job on merge request pipelines, where a snapshot has a reviewer to reach.

## Set the token

The command reads an organization CI API key from `KUBB_TOKEN`. Create the key in Studio's settings, then add it under Settings > CI/CD > Variables as a masked variable, so GitLab injects it without printing it in the job log. Protect it as well when only protected branches should publish.

It is neither the agent token that pairs a developer machine with Studio, nor the registry key that downloads a tarball.

Point at a self-hosted Studio with `--url`:

```shell [Terminal]
kubb studio snapshot --url https://studio.internal.example
```

## One agent per merge request

`snapshot` reads `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID` and registers the CI agent as `gl:<project id>:<merge request iid>`. Every pipeline on that merge request reuses the agent instead of registering a new one.

On a branch pipeline, where `CI_MERGE_REQUEST_IID` is unset, it falls back to `CI_COMMIT_REF_SLUG`. Pass `--id` when you want to group runs some other way:

```shell [Terminal]
kubb studio snapshot --id "$CI_PROJECT_ID:nightly"
```

## Post the result as a note

`--json` prints one JSON object on stdout and nothing else, so the rest of the job can read it. The object holds `id`, `name`, `version`, `integrity`, `url`, `snapshotIdUrl`, `expiresAt`, and `agentUrl`.

```yaml [.gitlab-ci.yml]
snapshot:
  stage: build
  image: node:22
  script:
    - npm ci
    - npx kubb studio snapshot --json > snapshot.json
    - |
      curl --fail --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
        --data-urlencode "body=Kubb snapshot: $(jq -r '.url' snapshot.json)" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes"
  artifacts:
    paths:
      - snapshot.json
  rules:
    - if: $CI_MERGE_REQUEST_IID
```

Writing a note needs a project access token with the `api` scope, held in a masked variable of its own. `CI_JOB_TOKEN` does not carry that permission.

## Install the snapshot

Downloading the tarball needs a `registry` API key, not the `ci` key that created the snapshot, because the tarball is private to your organization.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

npm sends that token as a bearer token, which is what the download endpoint expects.

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitHub Actions](./github-actions): the same snapshot through `kubb-labs/action`
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
