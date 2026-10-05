---
layout: doc
title: GitHub Actions
description: Publish Kubb Studio snapshots from GitHub Actions and review generated-file changes.
order: 2
navigation:
  title: GitHub Actions
  icon: i-simple-icons-githubactions
---

# GitHub Actions

Publish an installable Kubb Studio snapshot from GitHub Actions so reviewers can compare generated files against the base branch and previous runs.

## Prerequisites

- A repository with a working `kubb.config.ts`. Follow [Installation](/docs/5.x/installation) if you have not set up Kubb.
- A [Kubb Studio](/docs/5.x/integrations/studio) organization and an organization CI API key.

Store the CI API key as `KUBB_TOKEN` in an Actions repository secret. Snapshot installation uses a separate registry key. Only expose the CI secret to trusted pipelines.

## Configure the workflow

<!--@include: ../../../snippets/integrations/github-actions.md-->

## Review and install the result

Open the snapshot in Studio to review generated changes. Snapshots expire after seven days; schedule a default-branch run if it can go a week without a push.

To consume the generated package, follow [Install the snapshot](/docs/5.x/integrations/ci#install-the-snapshot).

## See also

- [Studio command reference](/docs/5.x/reference/commands/studio)
- [Publish snapshots from other CI providers](/docs/5.x/integrations/ci#other-ci-providers)
- [GitHub Actions inputs and outputs](/docs/5.x/reference/github-actions)
