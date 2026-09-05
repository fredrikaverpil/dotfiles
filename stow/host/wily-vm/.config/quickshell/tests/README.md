# Tests

Nothing here is loaded by the shell.

`TrayModel_test.js` covers real code: `plugins/bar/widgets/TrayModel.js`.

The four `Battery*` files are a worked example of the two kinds of test this
tree can support, and of the boundary between them; they are stand-ins with no
counterpart in `plugins/`. `tst_BatteryIndicator.qml` is still the only example
of the QML component kind, which is why they have not been deleted.

## Running

```sh
qml-test-js   # deno test tests/
qml-test-qml  # qmltestrunner -input tests, offscreen
```

Both come from the repo devshell (`.envrc` at the root), which also sets the
`QML_IMPORT_PATH` that `qmltestrunner` needs or `QtTest` will not resolve.

## What each kind is for

**`BatteryModel_test.js` — unit tests, no Qt.** The model files are
QML-flavoured JS with a `module.exports` guard, so a JS runtime can load them
directly. Deno reaches them through `createRequire`, not `import`: they are not
ES modules, and the guard is what makes the dual life work. This is the layer
that covers arithmetic and parsing — `NightlightModel`'s solar equation,
`Model.js`'s scale rounding.

Writing the example turned up a bug in its own subject on the first run:
`Number(null)` is `0`, which `isFinite` accepts, so an unknown battery level
read as flat. The same idiom sits in `services/idle/IdleModel.js`:
`secondsFromConfig(null, 600)` and `secondsFromConfig("", 600)` both return `0`
rather than the fallback. Latent rather than live — `idle/Service.qml` imports
`IdleModel` without ever calling it, which is one of the `unused-imports`
findings — but it is the bug a test would have caught before the caller landed.

**`tst_BatteryIndicator.qml` — component tests, real QML engine.** Instantiates
the component, drives properties, asserts on bindings and on signals via
`SignalSpy`. Worth the extra machinery only for what the JS tests cannot see:
the binding graph, and signals fired from property transitions. `_data()`
functions give table-driven cases natively.

## The boundary

**A component that imports Quickshell cannot be tested this way.** Not "needs a
compositor" — the types do not resolve at all:

```sh
$ find "$(nix eval --raw ~/.dotfiles#nixosConfigurations.wily-vm.pkgs.quickshell)" -name '*.so'
# nothing
```

Quickshell's QML module tree ships `qmldir` + `.qmltypes` + 8 `.qml` files and
no plugin library; its root `qmldir` says `optional plugin
quickshell-coreplugin` / `linktarget quickshell-coreplugin`, and the types are
statically linked into `bin/quickshell`. The `.qmltypes` exist for `qmllint`
and `qmlls` and nothing else. An external QML engine — `qmltestrunner`, `qml` —
gets `Type ... unavailable`.

19 of the 20 `.qml` files under this tree import Quickshell, so component
testing reaches almost none of it as written. `BatteryIndicator.qml` is
testable *because* it imports only QtQuick and delegates its logic to a `.js`
file the tests can also load. That split is the only thing that moves code
across the line.

Stubbing Quickshell with dummy QML types would make more of the tree
instantiable, at the cost of testing the stubs — and precisely in the case that
matters, a Quickshell update, the stub and reality part company silently.

Anything that genuinely needs Quickshell types instantiated needs the
`quickshell` binary itself, i.e. a NixOS VM test with a headless compositor.
