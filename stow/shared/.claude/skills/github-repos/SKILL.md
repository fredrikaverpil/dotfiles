---
name: github-repos
description:
  Find GitHub repos owned by a user or a team, via team permissions, repo
  ownership or CODEOWNERS entries
---

# GitHub repos

Ask for the owner if not given: a team (`<org>/<team>`) or a user (`<user>`,
optionally scoped to an `<org>`).

## Team

Non-archived repos in `<org>` where `<team>` is admin, or where a CODEOWNERS
file lists `@<org>/<team>`:

```sh
{
  gh api --paginate orgs/<org>/teams/<team>/repos \
    --jq '.[] | select(.role_name == "admin" and (.archived | not)) | .full_name'
  gh search code '@<org>/<team>' --owner <org> \
    --filename CODEOWNERS --limit 1000 --json repository,path \
    --jq '.[] | select(.path | IN("CODEOWNERS", ".github/CODEOWNERS", "docs/CODEOWNERS")) | .repository.nameWithOwner'
} | sort -u
```

- `<team>` is the team slug, as in its URL.
- `role_name` is one of `admin`, `maintain`, `push`, `triage`, `pull`; widen
  the filter if the user asks for more than admin.

## User

Non-archived repos owned by `<user>`, or where a CODEOWNERS file in `<org>`
lists `@<user>`:

```sh
{
  gh repo list <user> --no-archived --limit 1000 \
    --json nameWithOwner --jq '.[].nameWithOwner'
  gh search code '@<user>' --owner <org> \
    --filename CODEOWNERS --limit 1000 --json repository,path \
    --jq '.[] | select(.path | IN("CODEOWNERS", ".github/CODEOWNERS", "docs/CODEOWNERS")) | .repository.nameWithOwner'
} | sort -u
```

- Drop the code search when no `<org>` is given; `--owner <user>` covers only
  repos the user owns, which the first command already lists.
- Add `--source` to `gh repo list` to leave out forks.

## Caveats

- `--filename` matches loosely (e.g. `codeowners_test.go`); hence the `path`
  filter.
- Code search matches text: `@<user>` also hits `@<user>-bot`, `@<org>/<team>`
  also hits `@<org>/<team>-leads`. Check doubtful hits in the CODEOWNERS file.
- Code search covers default branches only and may lag; the team and repo APIs
  are exact.
- Code search skips archived repos, so CODEOWNERS hits are already non-archived.
