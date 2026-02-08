---
name: gh-cli
description: GitHub CLI (gh) command reference. Use when working with GitHub repositories, PRs, issues, actions, or any GitHub operations from the command line.
---

# GitHub CLI Quick Reference

The `gh` CLI is GitHub's official command-line tool. This is a quick reference for
common workflows—for comprehensive docs, see https://cli.github.com/manual

## Getting Help

```bash
gh --help                    # List all commands
gh <command> --help          # Help for specific command
gh auth status               # Check authentication
```

## Discovery Patterns

```bash
gh <command> --web           # Open in browser
gh <command> --json FIELDS   # JSON output for scripting
gh <command> <subcommand> -h # Quick help for any command
gh <command> list --limit N  # Limit results to avoid large output (default: 20-30)
```

Use tab completion to explore available commands and flags.

**Important:** Always use `--limit` when querying lists to avoid overwhelming output,
especially with `pr list`, `issue list`, `run list`, etc.

## Common Workflows

### PR Workflow

```bash
# Create PR
gh pr create --fill          # Use commit messages for title/body
gh pr create --web           # Open browser to create PR

# View and checkout
gh pr list                   # List PRs
gh pr view [NUMBER]          # View PR details
gh pr checkout NUMBER        # Checkout PR locally

# Review
gh pr review NUMBER --approve
gh pr review NUMBER --comment -b "feedback"

# Merge
gh pr merge --squash --delete-branch
```

### Review Workflow

```bash
# Find PRs needing your review
gh pr list --search "review-requested:@me"

# Review process
gh pr checkout NUMBER
# ... test locally ...
gh pr review NUMBER --approve
```

### CI/CD Debugging

```bash
# Check recent runs
gh run list --limit 5
gh run list --status failure

# View logs
gh run view RUN_ID --log-failed

# Rerun after fix
gh run rerun RUN_ID --failed
```

### Issue Triage

```bash
gh issue list
gh issue list --assignee @me
gh issue create --title "Title" --body "Description"
gh issue view NUMBER
gh issue comment NUMBER -b "Comment"
gh issue close NUMBER
```

## Core Commands Quick Reference

### Pull Requests

```bash
gh pr list [--state open|closed|merged] [--author @me]
gh pr create [--draft] [--title "..."] [--body "..."]
gh pr view [NUMBER] [--web]
gh pr checkout NUMBER
gh pr diff [NUMBER]
gh pr merge [NUMBER] [--squash|--merge|--rebase]
```

### Issues

```bash
gh issue list [--assignee @me] [--label "bug"]
gh issue create [--title "..."] [--body "..."]
gh issue view NUMBER [--web]
gh issue close NUMBER
```

### Workflows & Runs

```bash
gh run list [--workflow "CI"] [--status failure]
gh run view RUN_ID [--log] [--log-failed]
gh run watch RUN_ID
gh workflow run WORKFLOW_FILE [--ref branch]
```

### Repositories

```bash
gh repo clone OWNER/REPO
gh repo view [--web]
gh repo fork OWNER/REPO
gh repo create NAME [--public|--private]
```

## Power User Tips

### JSON Output

```bash
# Get structured data
gh pr list --json number,title,author

# Filter with jq
gh pr list --json number,title | jq '.[] | select(.number > 100)'
```

### API Access

```bash
# Direct API calls
gh api repos/OWNER/REPO
gh api repos/OWNER/REPO/pulls -f title="PR Title" -f head=branch -f base=main

# GraphQL
gh api graphql -f query='{ viewer { login } }'
```

### Aliases

```bash
gh alias set pv 'pr view'
gh alias set co 'pr checkout'
gh alias list
```

### Environment Variables

- `GH_TOKEN`: Authentication token
- `GH_REPO`: Default repository (OWNER/REPO format)
- `GH_EDITOR`: Preferred editor for interactive commands
- `GH_PAGER`: Pager for output (e.g., `less`)

## Finding Your Work

```bash
gh pr list --author @me
gh issue list --assignee @me
gh search prs "author:username is:open"
gh search issues "assignee:username is:open"
```
