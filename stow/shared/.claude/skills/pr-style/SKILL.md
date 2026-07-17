---
name: pr-style
description: >-
  This skill should be used when creating or editing a GitHub pull request
  title or description, regardless of tool (gh CLI, GitHub MCP tools, API).
  Defines PR title format and body format with Why/What/Notes sections.
---

# Pull Request Style

Conventions for PR titles and descriptions. These apply no matter how the PR
is created (`gh` CLI, GitHub MCP tools, API).

## General

- Always create draft PRs.
- Assign the PR to me (the author), not to Claude or a bot identity.
- Keep PR titles, descriptions, and comments concise and clear.
- Include only useful information. Remove redundancy and over-explanation.
- Prefer explicitness and clarity over verbosity.
- Express Why/What/Notes content as concise, to-the-point bullet lists. Avoid
  prose paragraphs.
- Include a small, illustrative code snippet whenever it conveys the change
  faster than prose. This is desired for PRs in general, and especially for bug
  fixes: a minimal example of the triggering case (and what went wrong) makes
  the problem concrete for reviewers. Keep it short — just enough to convey the
  point, not a full reproduction.
- Do NOT add AI attribution: no "Generated with Claude Code" lines, no session
  links or model names.

## PR Title Format

Write the title as if the whole PR was squashed into a single commit using
conventional commits. Use imperative mood (e.g., "Add feature" not "Added
feature"). Keep it concise and descriptive.

## PR Body Format

```markdown
## Why?

[Explain the motivation for this change. What problem does it solve?]

## What?

[Describe what was changed. List the key modifications.]

## Notes

[Optional. Additional context, testing notes, or follow-up items.]
```

Rules:

1. `## Why?` - Required. Explain motivation and problem being solved
2. `## What?` - Required. Describe the changes made
3. `## Notes` - Optional. Omit entirely if no notes are needed

## File References

Use `[file:lineno](url)` with SHA-pinned URLs:
`https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<lineno>`

- SHA: `git rev-parse HEAD`
- Owner/repo: from `git remote get-url origin` (or `gh repo view --json
  nameWithOwner -q .nameWithOwner` when `gh` is available)

## Example Body

```markdown
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
```
