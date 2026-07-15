---
name: documentation
description: Use when writing blog posts or documentation markdown files - provides writing style guide (active voice, present tense), content structure patterns, and SEO optimization.
---

# Documentation Skill

This skill provides comprehensive guidelines for AI coding assistants working on documentation.

## When to Use

- Adding a new plugin, feature, or option
- Changing plugin behavior or API signatures
- Fixing bugs that affect code generation
- Writing or updating functionalities/component/composable documentation
- Optimizing documentation for search engines

## What It Does

- Create clear, concise, practical documentation optimized for developer experience
- Optimize content for search engines and developer intent
- Structure content for maximum scannability and engagement

## Writing Standard

Documentation must be:

- Grammatically correct
- Clear and unambiguous
- Properly punctuated
- Complete sentences (not fragments)

Brevity is still valued, but never at the cost of clarity or correctness.

## Naming Conventions

- **Use kebab-case**: `how-to-do-thing.md`
- **Be descriptive**: `multipart-form-data.md` not `form.md`
- **Match URL structure**: File name becomes the URL path

### Writing Patterns

| Pattern       | Example                                                 |
| ------------- |---------------------------------------------------------|
| Subject-first | "The `useApp` composable handles Fabric related logic." |
| Imperative    | "Add the following to `config.ts`."                |
| Contextual    | "When relying on TypeScript, configure..."              |

### Modal Verbs

| Verb     | Meaning     |
| -------- | ----------- |
| `can`    | Optional    |
| `should` | Recommended |
| `must`   | Required    |

### Component Patterns (WHEN to use)

| Need              | Component                           |
| ----------------- |-------------------------------------|
| Info aside        | `> [!NOTE]`                         |
| Suggestion        | `> [!TIP]`                          |
| Caution           | `> [!WARNING]`                      |
| Required          | `> [!IMPORTANT]`                    |
| Multi-source code | `::: code-group` and ends with `:::` |

## Headings

- **H1 (`#`)**: No backticks
- **H2-H4**: Backticks work fine

## Links and Cross-References

- **Internal links**: Use relative paths: `/plugins/plugin-ts/`
- **Anchor links**: Link to specific sections: `/plugins/plugin-ts/#output-path`
- **External links**: Use full URLs with descriptive text
- **Placement**: Add links section at the very end of the document

## Checklist

- [ ] Active voice (85%+)
- [ ] Present tense
- [ ] 2-3 sentences per paragraph
- [ ] Explanation before code
- [ ] Validate frontmatter syntax
