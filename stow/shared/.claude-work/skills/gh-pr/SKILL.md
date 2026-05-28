---
name: gh-pr
description: >-
  This skill should be used when creating a GitHub pull request via `gh pr
  create`. Defines PR body format with Why/What/Notes sections, ensures proper
  assignment, and prompts for Jira ticket number.
---

# GitHub Pull Request Creation

When creating a pull request, use the `gh` CLI with the following format and
conventions.

- Always create draft PRs.
- Keep PR titles, descriptions, and comments concise and clear.
- Include only useful information. Remove redundancy and over-explanation.
- Prefer explicitness and clarity over verbosity.
- Express Why/What/Notes content as concise, to-the-point bullet lists. Avoid
  prose paragraphs.

## PR title format

Write the title as if the whole PR was squashed into a single commit using
conventional commits.

## PR Body Format

```markdown
# XY-123

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
2. `# XY-123` - Always ask the user for the Jira ticket number before creating
   the PR. If there is one, include it as an H1 header at the top of the body.
   If there isn't one, omit it.
3. `## Why?` - Required. Explain motivation and problem being solved
4. `## What?` - Required. Describe the changes made
5. `## Notes` - Optional. Omit entirely if no notes are needed
6. Use imperative mood in title (e.g., "Add feature" not "Added feature")
7. Keep title concise and descriptive

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
