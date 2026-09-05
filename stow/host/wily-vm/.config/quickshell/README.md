# Editor, lint and test setup for this tree

Design notes for the tree itself live in `nix/hosts/wily-vm/CLAUDE.md` ("How
the Quickshell tree is split"). This file covers only the tooling, which is
what you need when the LSP goes quiet.

Everything here runs **on the Mac or on the VM**, against this checkout, with
no running shell.

## Commands

The QML tooling lives in the repo's devshell (`flake.nix`, `devShells.default`),
entered by direnv through the `.envrc` at the repo root. From any shell inside
`~/.dotfiles`:

```sh
qml-lint       # qmllint -E over every .qml in this tree
qml-test-js    # deno test tests/
qml-test-qml   # qmltestrunner -input tests (offscreen)
```

Inside Neovim, `qmlls` attaches to `.qml` buffers automatically
(`nvim-fredrik/after/lsp/qmlls.lua`) — provided Neovim was launched from a shell
in this repo, so it inherits the devshell's `PATH` and `QML_IMPORT_PATH`.
Opened from elsewhere, only the QML LSP fails to start; nothing else notices.

Without direnv: `nix develop ~/.dotfiles -c qml-lint`.

## Which versions, and why they cannot drift

`qmlls`, `qmllint`, `qmlformat` and `qmltestrunner` all ship with
`qt6.qtdeclarative`, taken from the flake's `nixpkgs-unstable` input. Nothing
here picks a version, and **do not pin a different Qt** for this tree — the
whole invariant below is that the editor's Qt *is* the VM's Qt:

- **wily-vm and the devshell both track the `nixpkgs-unstable` flake input**
  (`flake.nix`). The Qt the VM runs and the Qt whose `qmlls` you type against
  are therefore the same derivation, and `nix flake update` moves them
  together. Today both are 6.11.1.
- **Quickshell's type info comes from the flake, never from the VM.** The
  devshell sets `QML_IMPORT_PATH` to `${quickshell}/lib/qt-6/qml` for the
  aarch64-linux quickshell — the exact store path the VM is running — plus Qt's
  own `lib/qt-6/qml` (qmlls and qmllint do not add their own module directory).
- Quickshell is Linux-only and cannot be *built* on Darwin, but the
  aarch64-linux path **substitutes** from cache.nixos.org. Nothing compiles.
  nix-direnv keeps the shell as a GC root, and re-evaluates it when `flake.lock`
  changes, so a `nix flake update` moves `qmlls` and the qmltypes together with
  nothing to run by hand.

`qmlls`, `qmllint` and `qmltestrunner` take import paths from **argv or their
environment only** — `.qmlls.ini` has no key for them. That is why the value is
an env var in the devshell and why the `.envrc` sits at the repo root rather
than in this directory: Neovim is rooted at `~/.dotfiles`, and a nested
`.envrc` would never fire for the session you edit QML in.

**Both import paths come from the flake, never from the qmlls binary's own
prefix.** Mason's registry carries a *standalone* `qmlls`
(`TheQtCompanyRnD/qmlls-workflow`, versioned 0.x) which is a bare binary with
no Qt module directory beside it. Deriving Qt's builtins from `exepath("qmlls")`
therefore made every `import QtQuick` fail whenever that copy won the PATH. The
devshell puts `qt6.qtdeclarative` ahead of Mason on `PATH`; if Mason's copy is
installed, uninstall it anyway: its nightly diverges from the Qt the VM runs,
and flags things — `id-shadows-member` on the `readonly property alias` wiring —
that 6.11.1 does not.

## `Ui/qmldir`

Required by the tooling, ignored by Quickshell. Without it neither tool can
resolve `pragma Singleton` through `import "Ui" as Ui`, and every member access
on `Compositor` reports as missing. A qmldir also hides what it does not list,
so **a new file under `Ui/` needs a line in it**.

## `.qmllint.ini`

Read by **both** `qmllint` and `qmlls`, so the editor and the terminal report
exactly the same findings — put suppressions there, never on either command
line. It lists only the four disabled categories; everything else keeps its
default.

`qmllint` currently **reports without failing**: the tree has pre-existing
findings (`palette`/`enabled`/`state` shadowing `QQuickItem` members,
`width`/`height` set on Layout children). Add `--warnings-are-errors` once
those are cleared.

## Tests

`tests/` holds a worked example of both kinds, with a `README.md` of its own
covering the boundary between them. Its subjects are stand-ins with no
counterpart in `plugins/`. There is no CI gate yet; `qml-test-js` and
`qml-test-qml` (above) are the two runners. `QML_IMPORT_PATH` is not optional
for the QML half — without it `QtTest` itself fails to resolve, which reports
as `Type TestCase unavailable` rather than as a missing import path.

The `*Model.js` files also self-check directly (`node NetworkModel.js` runs its
`demo()`); three of the six have one, and nothing runs them.

### What the QML half can reach

Only components that do **not** import Quickshell. Its QML modules ship
`qmldir` + `.qmltypes` + 8 `.qml` files and no plugin library — the types are
statically linked into `bin/quickshell`, and the qmltypes exist for `qmllint`
and `qmlls` alone. Any external QML engine, `qmltestrunner` included, reports
`Type ... unavailable`; it is not a matter of lacking a Wayland session.

19 of the 20 `.qml` files outside `tests/` import Quickshell, so as written that is nearly
none of the tree. The way across the line is the split `BatteryIndicator.qml`
demonstrates: keep the component pure QtQuick and put the logic in a `.js` file
both the shell and the tests can load. Instantiating the real types needs the
`quickshell` binary itself — a NixOS VM test with a headless compositor.
