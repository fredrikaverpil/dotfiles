---
name: git-commit
description: >-
  This skill should be used BEFORE running any git commit command. Triggers when
  about to run `git commit`. Ensures commit messages follow Conventional Commits
  specification and prompts for Jira ticket number.
---

# Git Commit Messages

Write commit messages following the Conventional Commits specification.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Types

| Type       | Purpose                                                 |
| ---------- | ------------------------------------------------------- |
| `feat`     | New feature                                             |
| `fix`      | Bug fix                                                 |
| `docs`     | Documentation only                                      |
| `style`    | Code style (formatting, no logic change)                |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf`     | Performance improvement                                 |
| `test`     | Adding or correcting tests                              |
| `build`    | Build system or external dependencies                   |
| `ci`       | CI configuration                                        |
| `chore`    | Maintenance tasks                                       |
| `revert`   | Reverts a previous commit                               |

## Rules

1. Use imperative mood in description ("add feature" not "added feature")
2. Do not end description with a period
3. Keep description under 72 characters
4. Separate subject from body with a blank line
5. Use the body to explain intent, nuances, gotchas, or background behind the
   change — not a paraphrase of the diff
6. Always ask the user for the Jira ticket number before committing. If there
   is one, include it as the last line in the commit body (e.g., XY-123).
   If there isn't one, omit it.

## Branch Naming

When creating a new branch, name it `<type>/<jira-ticket>` with the ticket
lowercased, using the same types as commit messages (e.g., `feat/xy-123`,
`fix/xy-456`). If there is no Jira ticket, fall back to
`<type>/<kebab-description>` (e.g., `feat/add-user-auth`).

## Breaking Changes

Add **!** after type/scope or include **BREAKING CHANGE:** in footer:

```
feat(api)!: remove deprecated endpoints

BREAKING CHANGE: The /v1/users endpoint has been removed.
```

## Scope

Optional. Use to specify area of change (e.g., `api`, `ui`, `auth`, `db`).
