---
name: gh-pr
description: Use this skill when creating a GitHub pull request. Defines PR body format with Why/What/Notes sections and ensures proper assignment.
---

# GitHub Pull Request Creation

When creating a pull request, use the `gh` CLI with the following format and
conventions.

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
gh pr create --assignee @me --title "<title>" --body "$(cat <<'EOF'
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
4. `## Notes` - Optional. Include only if there are additional notes
5. Omit `## Notes` section entirely if no notes are needed
6. Use imperative mood in title (e.g., "Add feature" not "Added feature")
7. Keep title concise and descriptive

## Example

```bash
gh pr create --assignee @me --title "Add user authentication" --body "$(cat <<'EOF'
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
