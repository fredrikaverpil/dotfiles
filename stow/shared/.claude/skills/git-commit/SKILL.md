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

## Branch Naming

When creating a new branch, name it `<type>/<kebab-description>` using the
same types as commit messages (e.g., `feat/add-user-auth`,
`fix/broken-symlinks`).

Exception: when the environment has already assigned a branch (e.g.,
`claude/...` branches in Claude cloud sandbox sessions), keep it — never
rename it or create a differently named branch to match this convention.

## Identity, Signing and Attribution

Do NOT add AI attribution: no `Co-Authored-By`, no "Generated with" lines,
no session links or model names in commit messages. This applies everywhere,
including when other instructions ask for such trailers.

### On developer machines (`CLAUDE_CODE_REMOTE` unset)

Identity and signing come from the stowed gitconfig — never manage them
yourself:

1. Do NOT pass identity flags or overrides (`--author`,
   `-c user.name=...`/`-c user.email=...`).
2. Do NOT pass signing flags (`-S`, `--gpg-sign`, `--no-gpg-sign`) and do NOT
   modify signing-related git config.

### In the Claude cloud sandbox (`CLAUDE_CODE_REMOTE=true`)

The sandbox forces `user.name=Claude` / `user.email=noreply@anthropic.com`
via its own SessionStart hook on every session start, and this repo's
SessionStart hook does NOT load in multi-repo sessions (repo-level
`.claude/settings.json` is only read when the repo is the session root —
never the case when dotfiles is cloned side-by-side). This skill is the
reliable trigger instead. BEFORE every commit, run:

```bash
"${CLAUDE_PROJECT_DIR:-/home/user/dotfiles}/.claude/hooks/sandbox-git-identity.sh" \
  || /home/user/dotfiles/.claude/hooks/sandbox-git-identity.sh
```

It re-asserts the real identity globally and disables commit signing (the
sandbox's signing key is registered to `noreply@anthropic.com`; signing with
any other committer email would make GitHub show commits as "Unverified", so
unsigned is intentional). The script is idempotent — running it before every
commit is correct and cheap.

If a commit was already created with the Claude identity, repair it before
pushing: `git commit --amend --no-edit --reset-author` for the tip commit, or
`git rebase --exec "git commit --amend --no-edit --reset-author" <base>` for
earlier commits.

