---
name: gh-pr
description: >-
  This skill should be used when creating a GitHub pull request via `gh pr
  create`. Covers the gh CLI mechanics; PR title and body conventions come
  from the pr-style skill.
---

# GitHub Pull Request Creation with gh

When creating a pull request with the `gh` CLI, use the command template below.
For the title and body content, follow the "pr-style" skill (conventional
commit title, Why/What/Notes body, draft PRs).

## Command Template

```bash
gh pr create --draft --assignee @me --title "<title>" --body "$(cat <<'EOF'
## Why?

<motivation>

## What?

<changes>

## Notes

<optional notes>
EOF
)"
```

## Rules

1. Always create draft PRs (`--draft`)
2. Always assign the PR to me (`--assignee @me`)
