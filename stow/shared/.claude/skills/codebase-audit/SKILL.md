---
name: codebase-audit
# Source: https://piechowski.io/post/git-commands-before-reading-code/
description: >
  Analyze a git repo's history to surface high-churn files, ownership risks, bug
  hotspots, momentum trends, and firefighting patterns. Use this skill whenever
  the user wants to understand a codebase, assess repo health, or orient
  themselves before reading code — even if they don't explicitly say "audit".
allowed-tools:
  - Bash
when_to_use: >
  Use when the user wants to understand the health, ownership, or risk profile
  of a git repository before reading the code. Examples: "audit this repo",
  "codebase audit", "analyze this repo's history", "what's the state of this
  codebase?", "bus factor", "churn analysis", "tell me about this repo",
  "who owns this code?", "is this repo healthy?".
context: fork
---

# Codebase Audit

Analyze the current git repository's history to produce a structured health
report covering churn, ownership, bugs, momentum, and firefighting patterns.

## Goal

Produce a structured markdown report with one section per dimension, including
raw data (top files/contributors) and observations. The report should help the
reader orient themselves in an unfamiliar codebase and identify risk areas before
reading code.

## Steps

### 1a. High-Churn Files

Run in parallel with steps 1b-1e.

```bash
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
```

Report the top 20 most-modified files in the past year. Flag any file that
appears disproportionately often -- this is the clearest signal of codebase drag.

**Success criteria**: A ranked list of files with change counts is produced.

### 1b. Team Ownership / Bus Factor

Run in parallel with steps 1a, 1c-1e.

Run both of these commands:

```bash
git shortlog -sn --no-merges
```

```bash
git shortlog -sn --no-merges --since="6 months ago"
```

Compare all-time vs recent 6-month contributor rankings. Flag single points of
failure (one person > 60% of commits) and note whether original architects are
still active.

**Success criteria**: Two ranked contributor lists (all-time and recent) are
produced, with bus-factor observations.

### 1c. Bug Hotspots

Run in parallel with steps 1a-1b, 1d-1e.

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

Show the top 20 files most frequently touched in bug-related commits. Overlay
against churn data from step 1a to identify highest-risk code.

**Success criteria**: A ranked list of bug-hotspot files is produced.

### 1d. Project Momentum

Run in parallel with steps 1a-1c, 1e.

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

Display monthly commit counts over the repo's entire history. Note the overall
trend: steady rhythm, growth, or decline. Flag sudden drops.

**Success criteria**: A monthly commit-count timeline is produced with trend
observations.

### 1e. Firefighting Patterns

Run in parallel with steps 1a-1d.

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

Count and list reverts, hotfixes, and emergency commits from the past year.
Frequent reverts indicate deploy instability and test reliability issues.

**Success criteria**: A count and list of firefighting commits is produced.

### 2. Synthesize Report

After all parallel steps complete, combine findings into a structured markdown
report with the following sections:

1. **High-Churn Files** -- table + observations
2. **Team Ownership** -- tables (all-time / recent) + bus-factor assessment
3. **Bug Hotspots** -- table + cross-reference with churn
4. **Project Momentum** -- timeline + trend analysis
5. **Firefighting Patterns** -- count + list + observations
6. **Key Takeaways** -- 3-5 bullet points summarizing the most important findings

**Success criteria**: A single, coherent markdown report covering all 5
dimensions with actionable observations is returned to the user.
