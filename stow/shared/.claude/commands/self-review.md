---
description: Self-review the work you just implemented
---

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

## Process

1. Identify all files you changed in this session
2. Re-read each file in full context (not just the diff)
3. Evaluate against the criteria above
4. If you find issues, fix them
5. Summarize what you reviewed and any changes made

$ARGUMENTS
