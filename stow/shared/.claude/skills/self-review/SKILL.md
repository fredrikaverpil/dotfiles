---
name: self-review
description: When done with implementation, perform self-review of the work
user-invocable: true
disable-model-invocation: false
---

# Self-Review

Go back and critically review your recent implementation end-to-end. Read
through all changed files and evaluate the work as a whole.

## Review criteria

- **Placement**: Was the change made in the right place architecturally? Does it
  fit naturally into the existing structure?
- **Simplicity over cleverness**: Prefer simple, explicit code over clever,
  implicit solutions. If something requires a comment to explain _why_ it's
  written that way, it's probably too clever.
- **DRY**: Did the change introduce redundant duplication? Is there existing
  code that already handles this or could be reused?
- **YAGNI**: Was anything added that isn't needed right now? Remove speculative
  abstractions, unused parameters, and premature generalization.
- **Idiomatic code**: Does the code follow conventions of the language,
  framework, and ecosystem? It should look like it belongs in the codebase.
- **DX and UX**: Is the change pleasant to use from both a developer and
  end-user perspective? Are APIs intuitive? Are error messages helpful?
- **Consistency**: Does the change follow the patterns already established in
  the project? A consistent codebase is more important than a locally "better"
  approach.
- **Maintainability**: Will this be easy to understand and modify six months
  from now by someone unfamiliar with the change?
- **Robustness**: Is the code brittle or potentially buggy? Look for edge cases,
  race conditions, or assumptions that could break.
- **Testability**: Can this be tested? Look for clear seams, injectable
  dependencies, and logic separated from side effects. Hard-to-test code is a
  design smell — flag it rather than leaving it untested.

## Laziness ladder

For every piece of code the change added, check it climbed no higher than
necessary. Walk the ladder and stop at the first rung that holds:

1. **Does this need to exist?** — if not, remove it (YAGNI).
2. **Already in this codebase?** — reuse it, don't rewrite.
3. **Standard library does it?** — use it.
4. **Native platform feature?** — use it.
5. **Already-installed dependency?** — use it.
6. **One line?** — one line.
7. **Only then**: the minimum that works.

Flag anything that skipped a lower rung — a new dependency where the stdlib or a
native feature would do, a reimplementation of something the codebase already
has, or an abstraction with a single caller.

This is about the _solution_, never about _reading_: still trace the real flow
through the code the change touches before judging a rung. And the ladder never
touches safety — trust-boundary and input validation, security, data-loss and
error handling, and accessibility are out of scope for trimming.

_Adapted from the "laziness ladder" in
[ponytail](https://github.com/DietrichGebert/ponytail)._

## Process

1. Identify all files you changed in this session
2. Re-read each file in full context (not just the diff)
3. Evaluate against the criteria above and the laziness ladder
4. If you find issues, fix them
5. Summarize what you reviewed and any changes made

$ARGUMENTS
