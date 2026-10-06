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
