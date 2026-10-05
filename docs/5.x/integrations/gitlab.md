---
layout: doc
title: GitLab CI
description: Publish Kubb Studio snapshots from GitLab CI and review generated-file changes.
order: 3
navigation:
  title: GitLab CI
  icon: i-simple-icons-gitlab
---

# GitLab CI

Publish an installable Kubb Studio snapshot from GitLab CI so reviewers can compare generated files against the base branch and previous runs.

## Prerequisites

- A repository with a working `kubb.config.ts`. Follow [Installation](/docs/5.x/installation) if you have not set up Kubb.
- A [Kubb Studio](/docs/5.x/integrations/studio) organization and an organization CI API key.
- Commit your npm lockfile and add `kubb` to the project’s development dependencies so `npm ci` installs the CLI.

Store the CI API key as `KUBB_TOKEN` in a masked CI/CD variable. Snapshot installation uses a separate registry key. Only expose the CI secret to trusted pipelines.

## Configure the workflow

<!--@include: ../../../snippets/integrations/gitlab.md-->

## Review and install the result

Open the snapshot in Studio to review generated changes. Snapshots expire after seven days; schedule a default-branch run if it can go a week without a push.

To consume the generated package, follow [Install the snapshot](/docs/5.x/integrations/ci#install-the-snapshot).

## See also

- [Studio command reference](/docs/5.x/reference/commands/studio)
- [Publish snapshots from other CI providers](/docs/5.x/integrations/ci#other-ci-providers)
