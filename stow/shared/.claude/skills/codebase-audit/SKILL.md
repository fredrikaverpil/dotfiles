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

### 0. Detect GitHub availability

Before starting the analysis, check whether the repo is GitHub-hosted and `gh`
is authenticated:

```bash
gh repo view --json nameWithOwner 2>/dev/null
```

If this succeeds, set a mental flag that GitHub enrichments are available. If it
fails (not a GitHub repo, or `gh` not authenticated), skip all `gh`-prefixed
sub-steps below and rely on git-only analysis. Do not warn or apologize — just
use what's available.

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

Commit count alone is a poor proxy for ownership. Someone reformatting config
files 100 times looks more "important" than someone who architected a core
subsystem in 5 commits. Gather multiple signals to build a nuanced picture.

#### 1b-i. Commit counts (all-time vs recent)

```bash
git shortlog -sn --no-merges
```

```bash
git shortlog -sn --no-merges --since="6 months ago"
```

#### 1b-ii. Lines changed per author

For the top 5 contributors by commit count, measure insertions and deletions:

```bash
git log --author="<name>" --numstat --no-merges --format='' | awk '{ add += $1; del += $2 } END { print "+" add, "-" del }'
```

This distinguishes high-volume contributors from high-frequency ones.

#### 1b-iii. Subsystem ownership

Identify the top-level directories in the repo, then for each one show the top 3
contributors:

```bash
git shortlog -sn --no-merges -- <directory>
```

This reveals domain expertise — one person may own 80% of `infra/` while another
owns `src/auth/`. Concentrated subsystem ownership is a bus-factor risk even when
overall commit counts look balanced.

#### 1b-iv. Commit sampling

For each of the top 3 contributors, sample their 5 most recent commits:

```bash
git log --author="<name>" --no-merges --oneline -5
```

Use the commit messages to characterize the nature of their work: features, bug
fixes, refactoring, formatting, dependency updates, etc. This adds qualitative
context that numbers alone cannot provide.

#### 1b-v. (gh) PR review patterns

Only if GitHub is available. Query merged PRs to understand who reviews whose
code:

```bash
gh pr list --state merged --limit 100 --json author,reviews
```

Look for review silos — if only one person reviews a particular author's PRs,
that's a knowledge concentration risk. Also note if anyone is a "review
bottleneck" (appears as reviewer on most PRs).

#### 1b-vi. (gh) GitHub contributor stats

Only if GitHub is available. GitHub's own contributor statistics include weekly
additions/deletions per author, which is more efficient than looping `git log
--numstat` per author:

```bash
gh api repos/{owner}/{repo}/stats/contributors
```

Use this to cross-validate the git-based lines-changed data from 1b-ii. If
available, prefer this data as it's pre-aggregated.

#### Synthesis

Combine all signals into an ownership assessment. A contributor with few commits
but large line changes in critical subsystems is more important than commit count
suggests. Conversely, someone with many commits that are mostly formatting or
config changes carries less bus-factor risk. PR review patterns (if available)
reveal knowledge sharing — or the lack of it.

**Success criteria**: Contributor rankings (all-time and recent), lines-changed
breakdown, per-subsystem ownership, commit samples, and (if GitHub is available)
review patterns are produced, with a nuanced bus-factor assessment that goes
beyond raw commit counts.

### 1c. Bug Hotspots

Run in parallel with steps 1a-1b, 1d-1e.

#### 1c-i. Git commit grep

```bash
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20
```

Show the top 20 files most frequently touched in bug-related commits.

#### 1c-ii. (gh) GitHub issues labeled as bugs

Only if GitHub is available. Query actual bug reports for a richer picture than
commit message grep alone:

```bash
gh issue list --label bug --state all --limit 50 --json title,assignees,url,closedAt
```

Cross-reference with the git-based hotspot data. Issues give you the user-facing
bugs that were reported, while commit grep gives you the files that were patched.
Together they paint a fuller picture.

#### Synthesis

Overlay bug hotspots against churn data from step 1a to identify highest-risk
code — files that both change frequently and attract bug fixes.

**Success criteria**: A ranked list of bug-hotspot files is produced, enriched
with issue data if GitHub is available.

### 1d. Project Momentum

Run in parallel with steps 1a-1c, 1e.

#### 1d-i. Monthly commit counts

```bash
git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
```

Display monthly commit counts over the repo's entire history. Note the overall
trend: steady rhythm, growth, or decline. Flag sudden drops.

#### 1d-ii. (gh) PR merge cadence

Only if GitHub is available. PR merge rate is often a better velocity signal than
raw commits, especially in squash-merge workflows:

```bash
gh pr list --state merged --limit 200 --json mergedAt
```

Group by month and compare against commit cadence.

#### 1d-iii. (gh) Release cadence

Only if GitHub is available:

```bash
gh release list --limit 20
```

Regular releases indicate a healthy delivery rhythm. Long gaps between releases
may signal stalled work or big-bang deployments.

**Success criteria**: A monthly commit-count timeline is produced with trend
observations, enriched with PR merge and release cadence if GitHub is available.

### 1e. Firefighting Patterns

Run in parallel with steps 1a-1d.

#### 1e-i. Git commit grep

```bash
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
```

Count and list reverts, hotfixes, and emergency commits from the past year.

#### 1e-ii. (gh) Reverted PRs

Only if GitHub is available. Squash-merged reverts don't always show up in `git
log --oneline`, so also search merged PRs:

```bash
gh pr list --state merged --search "revert OR hotfix OR emergency" --limit 50 --json title,mergedAt,url
```

Frequent reverts indicate deploy instability and test reliability issues.

**Success criteria**: A count and list of firefighting commits (and PRs if
GitHub is available) is produced.

### 2. Synthesize Report

After all parallel steps complete, combine findings into a structured markdown
report with the following sections:

1. **High-Churn Files** -- table + observations
2. **Team Ownership** -- tables (all-time / recent) + bus-factor assessment
3. **Bug Hotspots** -- table + cross-reference with churn
4. **Project Momentum** -- timeline + trend analysis
5. **Firefighting Patterns** -- count + list + observations
6. **Key Takeaways** -- 3-5 bullet points summarizing the most important findings

If GitHub data was available, note this at the top of the report. If not,
mention that the analysis is git-only and could be enriched by running against a
GitHub-hosted repo with `gh` authenticated.

**Success criteria**: A single, coherent markdown report covering all 5
dimensions with actionable observations is returned to the user.
