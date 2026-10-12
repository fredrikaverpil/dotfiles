---
name: plan-loop
description:
  Plan work with the user in a PLAN.md, then implement it one step at a time
  with /clear in between. Use before creating a plan, when the user mentions a
  PLAN.md, or when resuming work after /clear.
user-invocable: true
disable-model-invocation: false
---

# Plan loop

We discuss the work, write it down in `PLAN.md`, then implement one step at a
time with `/clear` in between. This keeps me in the loop to pivot between
steps, and keeps the context small: cheaper, and you stay sharper.

Recommended: Opus at high effort. If you are not running on Opus, say so and ask
whether to proceed anyway. You cannot see the effort level (no need to remind me
about it).

## Gather information

Work back and forth with me, starting with your open questions and outline
before writing the plan.

## PLAN.md

When I mention a PLAN.md, ask whether to use a git worktree or work directly.

Keep the plan in `PLAN.md` at the root of the worktree
(`./.claude/worktrees/<tree-name>/PLAN.md`), or at the repo root when working
directly. It is the source of truth that survives `/clear`:

- Goal, decisions made (with a short why), open questions.
- Steps as a checklist; tick them off as commits land.
- Key files to re-read when resuming.

Update it whenever a decision is made or a step completes, not only at the end.

## Step loop

1. After `/clear`, read `PLAN.md` and the files it lists before doing anything
   else. If no `PLAN.md` is at the root of the current checkout, list
   `.claude/worktrees/*/PLAN.md` and ask which one.
2. Implement the first unticked step only.
3. Update `PLAN.md` so a fresh context can resume from it alone: tick the step,
   record decisions and findings, name the next step.
4. Re-read all of `PLAN.md` for contradictory or outdated passages and fix
   them. If that raises a decision or a change of course, discuss it with me
   first.
5. Stop and ask me to run `/clear`, then `/plan-loop`. Do not start the next
   step.

When every step is done, ask whether to delete `PLAN.md` and, if used, the
worktree. First check its branch is in the main branch
(`git merge-base --is-ancestor HEAD main`). Then:

- From a session inside the worktree: `ExitWorktree` with `remove`. It
  counts commits against the session's starting point, not the main branch,
  so once the branch is merged and I agreed, pass `discard_changes: true`.
- Otherwise, from the main checkout: `git worktree remove <path>`, then
  `git branch -d <branch>` (the worktree removal keeps the branch).
