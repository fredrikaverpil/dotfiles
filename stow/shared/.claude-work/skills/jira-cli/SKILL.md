---
name: jira-cli
description: Jira CLI (`jira`) command reference. Use when working with Jira issues, epics, sprints, Jira ticket numbers, Jira URLs, or any Jira operations from the command line.
---

# Jira CLI Quick Reference

The `jira` CLI is a command-line tool for Jira interaction. This is a quick
reference for common workflows—for comprehensive docs, see
https://github.com/ankitpokhrel/jira-cli

## Getting Help

```bash
jira --help                  # List all commands
jira <command> --help        # Help for specific command
jira me                      # Show current user
```

## Discovery Patterns

```bash
jira <command> --plain       # Plain output for scripting
jira <command> --raw         # JSON output
jira <command> --csv         # CSV output for spreadsheets
jira issue list --limit N    # Limit results (avoid large output)
jira open [ISSUE-KEY]        # Open in browser
```

Use `--no-input` to skip interactive prompts when automating.

**Important:** Always use `--limit` when querying to avoid overwhelming output.

## Common Workflows

### Issue Management

```bash
# List and search
jira issue list
jira issue list -a$(jira me)              # Assigned to me
jira issue list -a$(jira me) --created week
jira issue list -s"To Do"                 # By status
jira issue list -yHigh -tBug              # High priority bugs

# View details
jira issue view ISSUE-KEY
jira issue view ISSUE-KEY --comments

# Create (use with caution!)
jira issue create -tBug -s"Summary" -yHigh --no-input

# Edit and transition
jira issue edit ISSUE-KEY
jira issue move ISSUE-KEY "In Progress"
jira issue assign ISSUE-KEY USERNAME

# Comment and log work
jira issue comment add ISSUE-KEY "comment text"
jira issue worklog add ISSUE-KEY "2h 30m"
```

### Sprint Workflow

```bash
# View sprints
jira sprint list
jira sprint list --current                # Active sprint issues
jira sprint list --state active

# Manage sprint items
jira sprint add SPRINT-ID ISSUE-1 ISSUE-2
```

### Epic Management

```bash
# List and create
jira epic list
jira epic create --name "Epic Name" --summary "Description"

# Manage epic items
jira epic add EPIC-KEY ISSUE-1 ISSUE-2
jira epic remove ISSUE-1 ISSUE-2
```

## Core Commands Quick Reference

### Issue Commands

```bash
jira issue list [-a ASSIGNEE] [-s STATUS] [-y PRIORITY] [-t TYPE] [-l LABEL]
jira issue view ISSUE-KEY [--comments]
jira issue create -t TYPE -s "Summary" [-y PRIORITY] [-l LABEL]
jira issue edit ISSUE-KEY
jira issue move ISSUE-KEY "STATUS"
jira issue assign ISSUE-KEY USERNAME
jira issue link TYPE INWARD OUTWARD
jira issue clone ISSUE-KEY
```

### Sprint Commands

```bash
jira sprint list [--current] [--state active|future|closed]
jira sprint add SPRINT-ID ISSUE-1 [ISSUE-2...]
```

### Epic Commands

```bash
jira epic list
jira epic create --name "Name" --summary "Summary"
jira epic add EPIC-KEY ISSUE-1 [ISSUE-2...]
jira epic remove ISSUE-1 [ISSUE-2...]
```

### Project & Board

```bash
jira project list
jira board list
jira open [ISSUE-KEY]                     # Open in browser
```

## Powerful Filtering

The jira CLI supports rich filtering for `issue list`:

```bash
# By assignee
-a$(jira me)                 # Me
-aUSERNAME                   # Specific user
-ax                          # Unassigned

# By reporter
-r$(jira me)                 # Reported by me

# By status
-s"To Do"                    # Specific status
-s~Done                      # NOT Done

# By priority
-yHigh                       # High priority
-yMedium -yLow               # Medium or Low

# By type
-tBug -tStory                # Bugs or Stories

# By labels
-lbackend -lurgent           # Multiple labels

# By component
-CBackend -CFrontend         # Multiple components

# By date
--created week               # Created this week
--created -7d                # Last 7 days
--updated -30m               # Updated in last 30 minutes

# By watching
-w                           # Issues I'm watching

# History
--history                    # Issues I recently viewed
```

## Output Formats

```bash
# Default: Interactive table
jira issue list

# Plain text (for scripting)
jira issue list --plain

# JSON (for parsing)
jira issue list --raw

# CSV (for spreadsheets)
jira issue list --csv
```

## Common Patterns

### Find My Work

```bash
# What's assigned to me
jira issue list -a$(jira me)

# What I created this week
jira issue list -r$(jira me) --created week

# What I worked on today
jira issue list --history

# Current sprint items
jira sprint list --current
```

### Filtering Examples

```bash
# High priority bugs assigned to me
jira issue list -a$(jira me) -yHigh -tBug

# Unassigned stories in "To Do"
jira issue list -ax -tStory -s"To Do"

# Recent updates with specific labels
jira issue list -lurgent --updated -2d

# Not done, watching, high priority
jira issue list -w -s~Done -yHigh
```

### Scripting with JSON

```bash
# Get raw JSON data
jira issue list -a$(jira me) --raw

# Process with jq
jira issue list --raw | jq '.issues[] | {key, summary, status}'
```

## Best Practices

- Use `$(jira me)` to reference current user
- Combine filters for powerful queries
- Use `--limit` to avoid large result sets
- Use `--plain` or `--raw` for scripting
- Use `--no-input` to skip prompts in automation
- Always check syntax with `--help` when uncertain
