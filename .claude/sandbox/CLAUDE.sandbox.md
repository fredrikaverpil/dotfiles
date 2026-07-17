# Claude cloud sandbox

This file is installed to `~/.claude/CLAUDE.md` by
`dotfiles/.claude/sandbox/bootstrap.sh` and exists only in the Claude cloud
sandbox — never on developer machines. Instructions here are therefore
sandbox-only.

## Git identity and attribution

- A user-scope PreToolUse hook asserts Fredrik's git identity and disables
  commit signing before every Bash call. Commits must be authored by
  `Fredrik Averpil <fredrik.averpil@proton.me>` — never by
  `Claude <noreply@anthropic.com>`.
- If a commit was created with the Claude identity anyway, repair it before
  pushing: `git commit --amend --no-edit --reset-author` for the tip commit,
  or `git rebase --exec "git commit --amend --no-edit --reset-author" <base>`
  for earlier commits.
- Never add AI attribution: no `Co-Authored-By`, no "Generated with" lines,
  no session links or model names in commit messages or PR bodies.
- Commit signing stays disabled on purpose: the sandbox signing key belongs
  to `noreply@anthropic.com`, and signing with any other committer email
  would show commits as "Unverified" on GitHub.

## Adding sandbox customizations

Sandbox-only behavior (config, hooks, instructions) belongs in
`dotfiles/.claude/sandbox/` — extend `bootstrap.sh` and this file rather
than adding per-repo or per-session configuration.
