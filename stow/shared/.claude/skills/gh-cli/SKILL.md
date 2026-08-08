---
name: gh-cli
description: GitHub CLI (gh) conventions and the inline PR review recipe. Use when working with GitHub repositories, PRs, issues, actions, `gh api`, or any GitHub operations from the command line.
---

# gh CLI

`gh --help` and https://cli.github.com/manual cover the command surface. This
skill covers only what they don't.

## Conventions

- Pass `--limit N` on every list command (`pr list`, `issue list`, `run list`).
  The defaults dump far more than a terminal needs.
- `--json FIELDS` when the output feeds a script; pipe to `jq` from there.

## Reviewing a PR with line-level comments

`gh pr review` only submits an overall body. Inline comments need `gh api`,
which posts the comments and the summary in one call. Read the diff first
(`gh pr diff NUMBER`), then:

```bash
gh api repos/{owner}/{repo}/pulls/NUMBER/reviews --input - <<'EOF'
{
  "commit_id": "LATEST_COMMIT_SHA",
  "event": "COMMENT",
  "body": "Overall: solid changes with a few suggestions.",
  "comments": [
    {
      "path": "src/example.go",
      "line": 42,
      "side": "RIGHT",
      "body": "This variable is unused."
    }
  ]
}
EOF
```

`side` is `RIGHT` for additions, `LEFT` for deletions; multi-line comments add
`start_line` and `start_side`. A `body` may contain a GitHub suggestion block
(```` ```suggestion ````) to propose replacement code.

`event` is `COMMENT`, `APPROVE`, or `REQUEST_CHANGES` — ask me which one before
submitting, and default to `COMMENT`.
