---
name: plan-loop
description:
  Plan work with the user in a PLAN.md, then implement it step by step, with
  /clear once the context fills up. Use before creating a plan, when the user
  mentions a PLAN.md, or when resuming work after /clear.
user-invocable: true
disable-model-invocation: false
---

# Plan loop

We discuss the work, write it down in `PLAN.md`, then implement it step by
step, with `/clear` once the context fills up. This keeps me in the loop to
pivot between steps, and keeps the context small: cheaper, and you stay
sharper.

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
- Steps as a checklist.
- Key files to re-read when resuming.

Update it whenever a decision is made or a step completes, not only at the end.

## Step loop

The context-meter plugin (`~/.claude/local-plugins/context-meter`) provides
`mcp__context-meter__usage`, which reports how full the context window is.
Load it with ToolSearch (`select:mcp__context-meter__usage`); if it is not
found, warn me that the plugin is not loaded.

1. After `/clear`, read `PLAN.md` and the files it lists before doing anything
   else. If no `PLAN.md` is at the root of the current checkout, list
   `.claude/worktrees/*/PLAN.md` and ask which one.
2. Implement the first unticked step.
3. Update `PLAN.md`: tick the step, record decisions and findings, name the
   next step.
4. Re-read all of `PLAN.md` for contradictory or outdated passages and fix
   them.
5. Call `mcp__context-meter__usage`, then continue with the next step (back
   to 2), unless:
   - The step or the re-read raised a decision, a surprise or a change of
     course: discuss it with me first.
   - The context is at 20% or more, or the plugin is not loaded: stop and ask
     me to run `/clear`, then `/plan-loop`.

When every step is done, ask whether to delete `PLAN.md` and, if used, the
worktree. First check its branch is in the main branch
(`git merge-base --is-ancestor HEAD main`). Then:

- From a session inside the worktree: `ExitWorktree` with `remove`. It
  counts commits against the session's starting point, not the main branch,
  so once the branch is merged and I agreed, pass `discard_changes: true`.
- Otherwise, from the main checkout: `git worktree remove <path>`, then
  `git branch -d <branch>` (the worktree removal keeps the branch).
