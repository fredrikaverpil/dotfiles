---
name: git-commit
description: >-
  This skill should be used BEFORE running any git commit command. Triggers when
  about to run `git commit`. Ensures commit messages follow Conventional Commits
  specification.
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

## Breaking Changes

Add **!** after type/scope or include **BREAKING CHANGE:** in footer:

```
feat(api)!: remove deprecated endpoints

BREAKING CHANGE: The /v1/users endpoint has been removed.
```

## Scope

Optional. Use to specify area of change (e.g., `api`, `ui`, `auth`, `db`).

## Identity, Signing and Attribution

Git identity and commit signing are configured by the environment (gitconfig
on developer machines, a SessionStart hook in cloud sandboxes) — never manage
them yourself:

1. Do NOT add AI attribution: no `Co-Authored-By`, no "Generated with" lines,
   no session links or model names in commit messages.
2. Do NOT pass identity flags or overrides (`--author`,
   `-c user.name=...`/`-c user.email=...`).
3. Do NOT pass signing flags (`-S`, `--gpg-sign`, `--no-gpg-sign`) and do NOT
   modify signing-related git config.

