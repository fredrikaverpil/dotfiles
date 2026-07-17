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
via its own SessionStart hook on every session start. The dotfiles sandbox
bootstrap (`.claude/sandbox/bootstrap.sh`) counters this with a user-scope
PreToolUse hook that re-asserts the real identity before every Bash call.

BEFORE committing, verify the countermeasure is active — this must NOT
print `noreply@anthropic.com`:

```bash
git config --global user.email
```

If it shows the Claude identity, the bootstrap has not run in this session.
Run it (hooks reload dynamically, so it takes effect immediately):

```bash
SANDBOX_BOOTSTRAP=1 "${CLAUDE_PROJECT_DIR:-/home/user/dotfiles}/.claude/sandbox/bootstrap.sh" \
  || SANDBOX_BOOTSTRAP=1 /home/user/dotfiles/.claude/sandbox/bootstrap.sh
```

Commit signing stays disabled on purpose: the sandbox's signing key is
registered to `noreply@anthropic.com`, so signing with any other committer
email would make GitHub show commits as "Unverified".

If a commit was already created with the Claude identity, repair it before
pushing: `git commit --amend --no-edit --reset-author` for the tip commit, or
`git rebase --exec "git commit --amend --no-edit --reset-author" <base>` for
earlier commits.

