---
name: smart
description:
  "Run a task through a budget-aware multi-model pipeline from a Fable/Opus main
  chat that never switches model: plan and interview, orchestrate Sonnet 4.5
  implementer subagents, then self-review. Use when the user wants planning,
  implementation, and review handled by different models."
user-invocable: true
disable-model-invocation: false
---

# Smart — multi-model workflow

Run a task through three phases from a single main chat on the smart model
(Fable, or Opus). The point is to keep expensive tokens on the judgment work —
planning, verifying, reviewing — and delegate implementation and research to
subagents that each carry their own pinned, cheaper model — **without** the
token blow-up of agent teams.

## Why subagents, not teams

This is a **hub-and-spoke** workflow: an orchestrator hands out self-contained
work and workers report back. That is exactly what
[subagents](https://code.claude.com/docs/en/sub-agents) are for — each runs in
its own context window and only a summary returns to the main context, so both
cost and main-context bloat stay low.

[Agent teams](https://code.claude.com/docs/en/agent-teams) exist for the
opposite case: teammates that talk to _each other_. They spin up a full Claude
instance per teammate (token cost scales linearly) and add coordination
overhead we don't need here. So we do **not** set
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. When the orchestrator wants a second
opinion, it spawns a one-off `reviewer` subagent instead of forming a team.

## Models: one main chat, subagents carry their own

Run the **whole session from the main chat on one model** — Fable (or Opus if
Fable is unavailable) — and never switch `/model`. Two phases *must* live in the
main chat because a subagent can't do them: the **interview** (only the main
chat talks to you) and the final **self-review** (wants the full session). Both
want the smart model anyway, so it's already there.

Everything delegated carries its own model and effort from its subagent
definition, so the sub-context switches model for you:

| Phase / role     | Runs in                      | Model          | Effort |
| ---------------- | ---------------------------- | -------------- | ------ |
| Plan & interview | main chat                    | Fable (→ Opus) | xhigh  |
| Implement        | `impl-worker` subagents      | Sonnet 4.5     | medium |
| Research         | `researcher` subagents       | Haiku          | low    |
| Review           | main chat + `reviewer` (opt) | Fable (→ Opus) | xhigh  |

Set the main chat to Fable (or Opus) at `xhigh` effort once, at the start. The
`impl-worker` pins the full ID `claude-sonnet-4-5`, because the bare `sonnet`
alias resolves to Sonnet 5 — the pricier model we don't want here.

## Shared brain: MEMORY.md

Subagents are stateless cold starts and this flow spans three phases, so keep a
single working doc as the shared state. Put it in the scratchpad (or a
gitignored path) — **do not commit it**.

It holds:

- **Plan** — the agreed approach and scope.
- **Decisions** — settled questions and their answers.
- **Open questions** — anything still blocking, for you to resolve.
- **Task specs** — one section per delegated unit of work (see Phase 2).
- **Review findings** — what Phase 3 surfaced and what was fixed.

The orchestrator points each subagent at the relevant section instead of
re-explaining context in the spawn prompt. This keeps spawn prompts small and
the main context lean.

## Phase 1 — Plan & interview (Fable, xhigh effort)

1. Set `/model` to Fable (or Opus) and `/effort` to xhigh — and leave it there;
   you won't switch again this session.
2. Run the `plan-interview` skill: work back and forth with the user, leading
   with open questions and an outline before writing the plan.
3. **Choose the least-code approach — this is the planner's job, not the
   worker's.** First read the code the change will touch and trace the real
   flow; be lazy about the solution, never about reading. Then, for each piece
   of work, walk the laziness ladder (defined in the `self-review` skill) and
   pick the lowest workable rung: does it need to exist at all, and can existing
   code, the standard library, a native feature, or an already-installed
   dependency do it before anything new is written? Record the chosen approach
   in the plan so it flows into the task specs — the Sonnet 4.5 workers
   implement the rung you picked rather than exercising this judgment
   themselves. Never trim safety (validation, security, error handling,
   accessibility).
4. Write the agreed plan, settled decisions, and any open questions into
   `MEMORY.md`.
5. Do **not** start implementing in this phase.

## Phase 2 — Implement (orchestrate from the main chat)

Stay in the main chat (Fable/Opus) — no model switch. **You are the
orchestrator: you verify and coordinate, you do not write the implementation
yourself.**

1. **Decompose.** Break the plan into self-contained tasks — a function, a file,
   a test suite — each producing a clear deliverable. Write one **task spec**
   per task into `MEMORY.md` (files to touch, expected behaviour, constraints,
   done criteria). Include the minimal approach chosen in planning — which
   existing code, stdlib, native feature, or dependency to use — so the worker
   builds that, not its own idea of the solution.
2. **Delegate.** Spawn an `impl-worker` (Sonnet 4.5) subagent per task. Keep the
   spawn prompt short: point it at its `MEMORY.md` section and the relevant
   files. Independent tasks can run in parallel; give each worker a disjoint set
   of files to avoid conflicts.
3. **Research cheaply.** For any web lookup, docs check, or library research,
   spawn a `researcher` (Haiku) subagent rather than doing it in the main
   context — only its summary returns.
4. **Verify every return.** Read each worker's diff against its spec and against
   the `self-review` criteria (placement, simplicity, DRY, YAGNI, idiom,
   robustness). If it falls short, send precise feedback and re-delegate. Answer
   worker questions.
5. **Escalate, don't guess.** For ambiguous product decisions, ask the user with
   `AskUserQuestion` and record the answer in `MEMORY.md`. For a second opinion
   on a risky diff, spawn a `reviewer` (Fable) subagent.

## Phase 3 — Self-review (Fable, xhigh effort)

1. Still in the main chat (Fable/Opus) — no model switch needed.
2. Run the `self-review` skill across the whole change — read every changed file
   in full, not just diffs.
3. Fix issues found, or delegate fixes back to an `impl-worker` if mechanical.
4. Record findings and fixes in `MEMORY.md`, then summarize for the user.

$ARGUMENTS
