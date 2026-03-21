---
name: gh-pr
description: >-
  This skill should be used when creating a GitHub pull request via `gh pr
  create`. Defines PR body format with Why/What/Notes sections and ensures
  proper assignment.
---

# GitHub Pull Request Creation

When creating a pull request, use the `gh` CLI with the following format and
conventions.

- Always create draft PRs.
- Keep PR titles, descriptions, and comments concise and clear.
- Include only useful information. Remove redundancy and over-explanation.
- Prefer explicitness and clarity over verbosity.

## PR title format

Write the title as if the whole PR was squashed into a single commit using
conventional commits.

## PR Body Format

```markdown
## Why?

[Explain the motivation for this change. What problem does it solve?]

## What?

[Describe what was changed. List the key modifications.]

## Notes

[Optional. Additional context, testing notes, or follow-up items.]
```

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

1. Always assign PR to `@me` using `--assignee @me`
2. `## Why?` - Required. Explain motivation and problem being solved
3. `## What?` - Required. Describe the changes made
4. `## Notes` - Optional. Omit entirely if no notes are needed
5. Use imperative mood in title (e.g., "Add feature" not "Added feature")
6. Keep title concise and descriptive

## Example

```bash
gh pr create --draft --assignee @me --title "Add user authentication" --body "$(cat <<'EOF'
## Why?

Users need secure access to their accounts. Currently there is no
authentication mechanism in place.

## What?

- Add login/logout endpoints
- Implement JWT token generation
- Add password hashing with bcrypt
- Create auth middleware for protected routes

## Notes

Requires `JWT_SECRET` env variable to be set in production.
EOF
)"
```
