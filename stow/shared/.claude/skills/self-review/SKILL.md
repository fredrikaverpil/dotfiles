---
name: self-review
description: >-
  Deliberate end-to-end review pass over a completed change, applying the
  laziness ladder. Invoke when the user asks for a review, or when
  orchestrating one. Not a routine step after every edit.
user-invocable: true
disable-model-invocation: false
---

# Self-Review

Review the change end-to-end. Read every file touched in full, not just the
diff — the surrounding code is what says whether the change belongs. Report
everything you find and fix what matters; don't self-censor to only the severe
findings.

## Review criteria

Beyond the obvious ones, weigh these — they are the ones most often missed:

- **Placement**: was the change made in the right place architecturally, or
  merely somewhere that works?
- **Simplicity over cleverness**: if something needs a comment to explain *why*
  it's written that way, it's probably too clever.
- **Consistency**: a codebase consistent with itself beats a change that is
  locally "better" but idiosyncratic.
- **DX and UX**: are APIs intuitive and error messages helpful, from both the
  developer's and the end user's side?
- **Testability**: look for clear seams, injectable dependencies, and logic
  separated from side effects. Hard-to-test code is a design smell — flag it
  rather than leaving it untested.
- **Robustness**: edge cases, race conditions, and assumptions that hold today
  but only by accident.

## Laziness ladder

The [ponytail](https://github.com/DietrichGebert/ponytail) plugin applies this
ladder while code is being *written*. Apply it here in reverse, to what **was**
written: for each piece of code the change added, check it climbed no higher
than necessary.

1. **Does this need to exist?** — if not, remove it (YAGNI).
2. **Already in this codebase?** — reuse it, don't rewrite.
3. **Standard library does it?** — use it.
4. **Native platform feature?** — use it.
5. **Already-installed dependency?** — use it.
6. **One line?** — one line.
7. **Only then**: the minimum that works.

Flag anything that skipped a lower rung — a new dependency where the stdlib or
a native feature would do, a reimplementation of something the codebase already
has, or an abstraction with a single caller.

The ladder never touches safety: trust-boundary and input validation, security,
data-loss and error handling, and accessibility are out of scope for trimming.

$ARGUMENTS
