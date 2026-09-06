# Tests

Nothing here is loaded by the shell.

## Running

Run these from the repository devshell (normally entered by direnv):

```sh
qml-test-js   # Deno unit tests for every pure JS model
qml-test-qml  # Qt-only component tests, offscreen
hypr-test     # sandboxed Hyprland Lua configuration and bind TSV contract
niri-validate # Linux only: validate niri's KDL configuration
qml-lint      # every QML file, including Quickshell imports
```

These commands are manual validation gates. The rules for when to run them
live in `nix/hosts/wily-vm/CLAUDE.md`.

## Boundary

The model files are QML-flavoured JS with a `module.exports` guard. Quickshell
imports the functions directly; Deno reaches the same files with
`createRequire`. Keep parsing, command construction, list transforms, and
state transitions in these files so `qml-test-js` can cover them without a
running compositor.

A component that imports Quickshell cannot be instantiated by
`qmltestrunner`. Quickshell's types are statically linked into its binary; the
installed QML metadata serves tooling only. `qml-test-qml` therefore tests only
QtQuick components such as the `BatteryIndicator` worked example. Test
Quickshell lifecycle, focus, and daemon interactions in the VM instead.

`hypr-test` supplies an `hl` spy and a temporary `HOME` to execute
`hyprland.lua`. It checks the monitor loader's valid and invalid fallbacks and
that the generated bind TSV agrees with registered binds. It deliberately does
not emulate Hyprland dispatch behavior.
