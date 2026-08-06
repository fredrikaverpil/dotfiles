---
name: golang-style
description:
  Go conventions specific to this author. Use before writing or editing any Go
  (.go) file.
---

# Go conventions

Where this author deviates from, or tightens, idiomatic Go defaults.

## Errors and control flow

- Structure functions so the happy path flows straight down: handle each error
  and return early, then continue with the main logic. Main logic never nests
  inside an `if err == nil` branch.
- Wrap every propagated error with `%w` and context naming the operation and
  the relevant identifiers — no "failed to" prefix:
  `fmt.Errorf("create order for customer %s: %w", customerID, err)`. A bare
  `return err` loses the trail.
- Define expected error conditions as package-level sentinel errors
  (`var ErrNotFound = errors.New("not found")`) and check them with
  `errors.Is`, not `==` or string matching.

## Go version

Your idea of "current Go" is frozen at your training cutoff and is usually out
of sync with the project in both directions. Before writing code, read the `go`
directive in `go.mod` and check `go version`, and target the lower of the two.

That drift cuts both ways, so treat the toolchain as the authority over memory:

- Newer than you know: a stdlib package or function you have never seen may
  exist, and a helper you would hand-roll may have landed in `slices`, `maps`,
  `cmp`, or `testing`. Check with `go doc <pkg>` before writing your own.
- Older than you assume: a feature you consider ordinary may postdate the `go`
  directive and fail to build. Confirm with `go doc` or the release notes rather
  than assuming availability.

`go doc` reads the toolchain actually installed, so it is the cheapest way to
settle any of this.

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
