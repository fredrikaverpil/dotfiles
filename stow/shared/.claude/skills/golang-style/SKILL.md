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
- Only wrap errors with `%w` if the underlying error should be
  exposed.
- Define expected error conditions as package-level sentinel errors
  (`var ErrNotFound = errors.New("not found")`) and check them with
  `errors.Is`, not `==` or string matching.

## Go version

Your idea of "current Go" is frozen at your training cutoff and is usually out
of sync with the project in both directions. Before writing code, read the `go`
directive in `go.mod` and check `go version`, and target the lower of the two.

That drift cuts both ways:

- Newer than you know: a helper you are about to hand-roll may already exist in
  `slices`, `maps`, `cmp`, `testing`, or a package you have never heard of.
- Older than you assume: a feature you treat as ordinary may postdate the `go`
  directive and simply not build.

`go doc <pkg>` answers both, but only for the toolchain installed here. To ask
about the version the module actually targets, use the pkg.go.dev API — no auth,
GET only ([announcement](https://go.dev/blog/pkgsite-api), spec at
`https://pkg.go.dev/v1beta/openapi.yaml`):

```sh
# Which symbols does a stdlib package have at a specific Go version?
curl -s "https://pkg.go.dev/v1beta/symbols/slices?version=v1.21.0"

# Current Go release, and any release candidate in flight.
curl -s "https://pkg.go.dev/v1beta/versions/std"

# Third-party: latest version, and the symbols it declares.
curl -s "https://pkg.go.dev/v1beta/module/github.com/google/go-cmp"
curl -s "https://pkg.go.dev/v1beta/symbols/github.com/google/go-cmp/cmp"
```

Release notes are not in the API — fetch https://go.dev/doc/go1.N for a
release's changes, or https://go.dev/doc/devel/release for the index.

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
