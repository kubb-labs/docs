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
  script:
    - npm ci
    - npx kubb studio snapshot
  rules:
    - if: $CI_MERGE_REQUEST_IID
```

`kubb` ships the Studio runtime, so `npm ci` is the only setup. The `rules` entry keeps the job on merge request pipelines.

## Set the token

Create `KUBB_TOKEN`, an organization CI API key, in Studio's settings. Add it under Settings > CI/CD > Variables as a masked variable.

## One agent per merge request

The CI agent registers as `gl:<project id>:<merge request iid>`, read from `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`. Pass `--id` to group runs your own way.

## Post the result as a note

`--json` prints one JSON object and nothing else, carrying `url`, `name`, `version`, `integrity`, `expiresAt`, and `agentUrl`.

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

Writing a note needs a project access token with the `api` scope. `CI_JOB_TOKEN` does not carry it.

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
