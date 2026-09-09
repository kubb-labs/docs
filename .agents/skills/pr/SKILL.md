---
name: pr
description: Open or update a pull request in this content repo. Covers what to check on a markdown change, frontmatter and include rules, Conventional Commit titles, how to fill the PR template, and what to do once CI runs. Use when asked to open a PR, push a branch for review, fix a red PR, or judge whether a branch is ready to merge.
---

# PR skill

Take a branch from "the page is written" to "a reviewer can merge this". Work the steps in
order. When you cannot finish a step, say so in the PR body rather than skipping it quietly.

This repo holds content only. There is no install, no build, and no test suite, so the checks
below are the whole safety net.

## When to use

- Opening a pull request, or pushing a branch you expect to become one.
- Updating a pull request after a review comment or a failing CI run.
- Answering whether a branch is ready to merge.

## 1. Confirm the branch

Never commit to `main`. Check where you are, and branch from an up-to-date `main` if you are
still on it:

```bash
git status
git branch --show-current
git fetch origin main
git switch -c docs/<short-slug> origin/main
```

## 2. Check the content before you push

Read the diff as a reader would, then check the mechanics:

- Frontmatter on a `{plugins,adapters,parsers}/<id>/index.md` page carries the registry metadata.
  `id` matches the folder name, `kind` is `plugin`, `adapter`, or `parser`, and `id`, `name`,
  `description`, `category`, `type`, `npmPackage`, `repo`, and `docsPath` are all required. The
  fetch pipeline validates it against `apps/kubb.dev/public/schemas/extension.json` in
  kubb-labs/platform, and a page that fails validation breaks the build there, not here.
- A new guide or recipe page needs its entry in the `guides` or `recipes` array of the same
  `index.md`, or the sidebar never shows it.
- Every `<!--@include: ../snippets/... -->` path resolves from the including page.
- Every relative link resolves, and every code sample runs.
- `docs/5.x/changelog.md` is generated. Never edit it by hand.

## 3. Match the source of truth

An option documented here has to exist in the plugin's `src/types.ts` `Options` type and be
honored in `src/plugin.ts` in [kubb-labs/plugins](https://github.com/kubb-labs/plugins), and a
documented default has to match the destructuring default there. When you document a change that
has not shipped yet, say which upstream PR carries it in the PR body.

## 4. Run the writing skills

Run the `humanizer` skill over every page you wrote or edited and fix the tells it surfaces, in
that same pass. Use the `documentation` skill for voice and structure: active voice, present
tense, short paragraphs, explain before showing code. Use USA English.

## 5. Commit

One Conventional Commit per logical change, in the imperative, with no trailing period:

```
docs(plugin-react-query): document the mutation key option
```

Check `git diff --cached` before every commit. Never commit a secret or a token.

## 6. Write the title and body

### Title

One Conventional Commit line, imperative, under 72 characters, no trailing period.

### Body

Fill `.github/pull_request_template.md`. Keep its headings and their order, replace each HTML
comment with real content, and delete no section.

Under **Changes**, write two to five sentences. Lead with what changed, then why. Name the page a
reviewer should open first. Add `Closes #123` when the PR closes an issue.

Under **Checklist**, tick a box only for something you actually did on this branch. An unticked
box with a one-line reason under it is honest and useful. A ticked box you did not verify costs
a reviewer their trust, so it is the one thing never to do here.

Keep the body in plain language: short sentences, active voice, exact paths, no restating the
request back at the reader.

## 7. Push and open the PR

```bash
git push -u origin <branch>
```

Open the PR against `main`, ready for review rather than draft. One topic per PR.

## 8. After CI runs

A red PR is work now, whatever its review state. Read the failing job, fix the cause, and push
again.

Answer every review comment. Push the fix for a small, local ask. For a larger ask, reply with
what you propose and let the author decide.

## Guardrails

- Keep the diff to what was asked.
- Never force-push a branch someone else may have checked out.
- Never edit a generated page.

## Related skills

| Skill | Use for |
| --- | --- |
| [documentation](../documentation/SKILL.md) | Voice, structure, and SEO for a page |
| [humanizer](../humanizer/SKILL.md) | Stripping AI tells from the prose in the diff |
