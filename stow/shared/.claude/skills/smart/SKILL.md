---
name: smart
description:
  "Run a task through a budget-aware multi-model pipeline from one main chat
  that never switches model: plan and interview, orchestrate implementer
  subagents, then review. Use when you want planning, implementation, and
  review handled by different models."
user-invocable: true
disable-model-invocation: true
---

# Smart — multi-model workflow

Three phases from a single main chat on the smart model. The point is to keep
expensive tokens on the judgment work — planning, verifying, reviewing — and
delegate implementation and research to subagents carrying their own cheaper,
pinned model.

Hub-and-spoke, not a team: workers report to the orchestrator and never talk to
each other, so [subagents](https://code.claude.com/docs/en/sub-agents) fit and
[agent teams](https://code.claude.com/docs/en/agent-teams) don't. Leave
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset.

## Models: one main chat, subagents carry their own

Run the **whole session from the main chat on one model** — Opus 5, or Fable 5
— and never switch `/model`. Two phases *must* live there because a subagent
can't do them: the **interview** (only the main chat talks to you) and the
final **review** (wants the full session).

| Phase / role     | Runs in                 | Model      | Effort      |
| ---------------- | ----------------------- | ---------- | ----------- |
| Plan & interview | main chat               | Opus 5     | high → xhigh |
| Implement        | `impl-worker` subagents | Sonnet 4.5 | medium      |
| Research         | `researcher` subagents  | Haiku      | low         |
| Review           | main chat               | Opus 5     | high → xhigh |

Set effort once at the start and leave it. Default to `high`; step up to
`xhigh` only for genuinely demanding planning or review, since Opus 5 holds
quality at lower effort for a fraction of the tokens.

`impl-worker` pins the full ID `claude-sonnet-4-5` deliberately — the bare
`sonnet` alias resolves to Sonnet 5, which costs more than this role needs.

## Delegate deliberately

Delegation pays off on sizeable, genuinely independent tracks of work. It
multiplies cost and wall-clock time on small ones. Don't spawn a worker for
something you'd finish yourself in a handful of tool calls, and if one worker
can do the task, use one rather than several.

## Shared brain: smart-plan.md

Subagents are stateless cold starts and this flow spans three phases, so keep a
single working doc as shared state. Put it at `smart-plan.md` in the scratchpad
(or a gitignored path) — **do not commit it**. The name avoids colliding with
the harness's own `MEMORY.md`.

It holds the plan, settled decisions, open questions, one **task spec** per
delegated unit of work, and review findings. Point each subagent at the
relevant section instead of re-explaining context in the spawn prompt — that
keeps spawn prompts small and the main context lean.

Keep it to what the next phase actually needs; it's working state, not a
report.

## Testability (non-negotiable)

Every change must be written to be testable — clear seams, injectable
dependencies, pure logic separated from side effects, no hidden global state a
test can't reach. Design this in during planning.

If a piece genuinely can't be made reasonably testable, it doesn't get waved
through silently: the worker flags it, and the orchestrator gets your explicit
OK with `AskUserQuestion` before accepting it, recording the decision in
`smart-plan.md`.

## Phase 1 — Plan & interview

1. Set `/model` and `/effort` per the table, and leave them there.
2. Run the `plan-interview` skill: work back and forth with the user, leading
   with open questions and an outline before writing the plan.
3. **Choose the least-code approach — this is the planner's job, not the
   worker's.** Read the code the change will touch and trace the real flow
   first; be lazy about the solution, never about reading. Then walk the
   laziness ladder from the `self-review` skill and pick the lowest workable
   rung. Record the chosen approach so it flows into the task specs — the
   workers implement the rung you picked rather than exercising this judgment
   themselves.
4. Write the plan, decisions, and open questions into `smart-plan.md`.
5. Do **not** start implementing in this phase.

## Phase 2 — Implement (orchestrate from the main chat)

Stay in the main chat — no model switch. **You are the orchestrator: you verify
and coordinate, you do not write the implementation yourself.**

1. **Decompose.** Break the plan into self-contained tasks, each producing a
   clear deliverable. Write one **task spec** per task into `smart-plan.md`
   (files to touch, expected behaviour, constraints, done criteria). Include
   the minimal approach chosen in planning, so the worker builds that rather
   than its own idea of the solution.
2. **Delegate.** Spawn an `impl-worker` per task, subject to *Delegate
   deliberately* above. Keep the spawn prompt short: point it at its
   `smart-plan.md` section and the relevant files. Independent tasks can run in
   parallel; give each worker a disjoint set of files.
3. **Research cheaply.** For a web lookup, docs check, or library question,
   spawn a `researcher` rather than doing it in the main context — only its
   summary returns.
4. **Verify every return.** Read each worker's diff against its spec and the
   `self-review` criteria: placement, simplicity, DRY, YAGNI, idiom,
   robustness, and whether it over-built past the rung you picked. This is the
   verification step for worker output — one careful read, not a second pass on
   top of it. If it falls short, send precise feedback and re-delegate.
5. **Escalate, don't guess.** For ambiguous product decisions, ask with
   `AskUserQuestion` and record the answer. When a worker flags something as
   hard to test, follow **Testability** above.
6. **Second opinion, sparingly.** If a worker's diff is genuinely risky or
   ambiguous and a fresh read would change what you do, spawn one `reviewer`.
   This is a writer-verifier split — the worker wrote it, you didn't. Don't use
   it to re-check routine diffs, and never to double-check your own Phase 3
   review.

## Phase 3 — Review

1. Still in the main chat — no model switch needed.
2. Run the `self-review` skill across the whole change, reading every changed
   file in full rather than only diffs.
3. Fix what you find, or delegate mechanical fixes back to an `impl-worker`.
4. Record findings and fixes in `smart-plan.md`, then summarize for the user:
   lead with what happened, supporting detail after.

$ARGUMENTS
