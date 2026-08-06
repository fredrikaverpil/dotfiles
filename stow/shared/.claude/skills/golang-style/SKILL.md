---
name: golang-style
description:
  Go conventions specific to this author. Use before writing or editing any Go
  (.go) file.
---

# Go conventions

Idiomatic Go — happy path flowing straight down, errors wrapped with `%w` and
operation context, sentinel errors compared with `errors.Is` — is assumed. Use
`go doc <symbol>` rather than guessing at a signature. What follows is where
this author deviates from, or tightens, the defaults.

## Formatting

- Maximum line length 120 characters. Break long signatures and `fmt.Errorf`
  calls one argument per line.
- Indent with tabs rendered 2 wide.
- Organize imports with `gci`.

## Comments

Every comment ends with a period, including inline ones inside a function body.

## Naming

Never shadow a predeclared identifier with a variable or parameter name — not
`new`, `len`, `make`, `copy`, `max`, `min`, `clear`, `any`, `error`, `string`,
or any other builtin function, constant, or type. Pick a descriptive name
instead: `length` over `len`, `dataCopy` over `copy`.

## Einride

If the project is under the Einride organization, run tasks through the
project's Sage-generated Makefiles (the `.sage` folder) rather than invoking
`go` directly.
