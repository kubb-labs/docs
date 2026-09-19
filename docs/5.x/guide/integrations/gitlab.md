---
layout: doc
title: GitLab CI
description: Publish a Kubb snapshot from a GitLab CI job with kubb studio snapshot, and post the tarball on the merge request.
outline: [2, 3]
---

# GitLab CI

[`kubb studio snapshot`](/docs/5.x/reference/commands/studio#subcommands) generates a package, publishes it to [Kubb Studio](./studio), and exits. A later job can run [`kubb studio publish`](./studio#publish-to-npm) with the snapshot ID to release the exact same tarball to npm.

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

`kubb` ships the Studio runtime, so `npm ci` is the only setup. The `rules` entry keeps the job on merge request pipelines.

## Set the token

Create `KUBB_TOKEN`, an organization CI API key, in Studio's settings. Add it under Settings > CI/CD > Variables as a masked variable.

Point at a self-hosted Studio with `--url https://studio.internal.example`.

## One agent per merge request

The CI agent registers as `gl:<project id>:<merge request iid>`, read from `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`. Pass `--id` to group runs your own way.

## Post the result as a note

`--json` prints one JSON object and nothing else, carrying `url`, `name`, `version`, `integrity`, `expiresAt`, and `agentUrl`.

```yaml [.gitlab-ci.yml]
  script:
    - npm ci
    - npx kubb studio snapshot --json > snapshot.json
    - jq -r '.id' snapshot.json
    - |
      curl --fail --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
        --data-urlencode "body=Kubb snapshot: $(jq -r '.url' snapshot.json)" \
        "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID/notes"
```

Writing a note needs a project access token with the `api` scope. `CI_JOB_TOKEN` does not carry it.
Copy the ID printed by `jq -r '.id' snapshot.json` into the project or group variable
`SNAPSHOT_ID` for the later tag pipeline. `SNAPSHOT_ID` is a regular, non-secret variable; the
published tarball remains protected by Studio's organization permissions.

## Install the snapshot

The download needs a `registry` API key, not the `ci` key that created the snapshot.

```ini [.npmrc]
//kubb.studio/:_authToken=${KUBB_REGISTRY_TOKEN}
```

```shell [Terminal]
npm i https://kubb.studio/packages/<agent>/<package>.tgz
```

## Publish from a release job

Pass the snapshot ID from the earlier job and keep the npm token in the release job's environment:

```yaml [.gitlab-ci.yml]
publish:
  stage: release
  image: node:22
  script:
    - npm ci
    - test -n "$SNAPSHOT_ID"
    - NPM_TOKEN="$NPM_TOKEN" npx kubb studio publish --allow-publish --snapshot-id "$SNAPSHOT_ID" --id "gl:$CI_PROJECT_ID:$CI_MERGE_REQUEST_IID"
  rules:
    - if: $CI_COMMIT_TAG
```

## See also

- [Kubb Studio](./studio): connect a project, grant permissions, and self-host
- [GitHub Actions](./github-actions): the same snapshot through `kubb-labs/action`
- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
