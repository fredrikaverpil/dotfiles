# Wily desktop

`wily-vm` is the NixOS development VM for the future `wily` ThinkPad T14 Gen 6
Intel (Lunar Lake). Keep the shell portable; machine-specific settings belong
in the host's Nix/Stow configuration.

Document constraints, rationale and gotchas, not implementation inventories or
previous states.

## Architecture

- Hyprland and niri are alternative UWSM sessions, started with `hypr` or `niri`
  from the console. They never run together.
- `desktop.nix` owns packages, portals, PAM, systemd units, and the pre-suspend
  lock inhibitor. `stow/host/wily-vm/` owns compositor configuration and QML.
- `shell.qml` wires services and surfaces. Views belong in `plugins/panels/`;
  daemon/process state belongs in `plugins/services/`.
- `Ui/Compositor.qml` selects a named backend registered in `CompositorModel.js`.
  `Ui/compositors/` owns commands, response parsing, scaling/focus policies, and
  workspace sources. Views use that interface, not compositor-identity booleans.
  Keep scheduling and shared state above it; no speculative plugin framework.
- Selection requires exactly one session marker: `NIRI_SOCKET` or
  `HYPRLAND_INSTANCE_SIGNATURE`. Missing/ambiguous markers are errors, never an
  implicit Hyprland fallback.
- Load workspace sources by URL: importing `Quickshell.Hyprland` opens a socket.
  Niri event IDs are global; UI labels/actions use output-local workspace `idx`.
- Hyprland Lua option names use underscores even where `hyprctl` prints hyphens.
  Use the LuaLS stub. Niri KDL booleans are presence-only, not `option true`.
- Read the relevant Omarchy source before changing a ported feature:
  `~/code/public/github.com/omacom/omarchy`. Complementary references are
  `~/code/public/github.com/caelestia-dots/shell` and
  `~/code/public/github.com/AvengeMedia/DankMaterialShell`.

## Required local validation

Run relevant checks **before and after editing**, on the correct platform.
These are development gates, not CI jobs. Use the repository devshell (`direnv`
or `nix develop ~/.dotfiles -c <command>`):

| Change | Checks |
| --- | --- |
| JS/QML | `qml-test`, `qml-lint` on Linux |
| Backend, compositor config, or bind contract | Also `compositor-test` |
| Live shell behaviour | Also `shell-smoke <hyprland\|niri>` and exercise the affected path |
| Device-dependent behaviour | Also validate on the actual ThinkPad |

- Establish the target checkout, flake pin, and session first. Record baseline
  failures; after editing, check an isolated Linux copy before deploying into
  the live stowed tree. Repeat checks against the deployed shell.
- Shared compositor changes require live checks in **both** sessions. Coordinate
  switching with the user; do not automatically log out or switch compositors.
- Mac tests are supplementary. Report unavailable session/hardware coverage as
  **pending**, never substitute another platform or claim full validation.
- `shell-smoke` selects the running systemd service's PID and works over SSH.
  It checks actual service IPC and runtime errors. `--panels` additionally
  opens, queries, then closes Display, closing any competing panel. It refuses
  that operation while locked and does not change scaling or device settings.
- Smoke checks do not prove focus, object lifetime, authentication, daemon
  recovery, or physical input. Exercise affected paths explicitly. Agree on a
  recovery path before lock/PAM, suspend, DPMS-off, or connectivity tests.
- Report host/session, before/after results, existing diagnostics, and omissions.
  Ask the user to run Nix rebuilds; never run them yourself.

### Test boundaries and tooling

- `tst_*.qml` imports production JS directly into QtTest. Keep meaningful pure
  parsing, transforms, and transitions; inline trivial single-use bindings.
  There is no independent JS consumer here, so no Deno/Node/Bun test suite or
  CommonJS export guards. For future independent JS tools, prefer Node's built-in
  test runner/assertions unless the tool specifically targets another runtime.
- QtTest can test Qt-only components, but all transitive imports must be Qt-only.
  Quickshell's native types are linked into its executable, not loadable through
  its installed metadata. Even `Ui/BarButton.qml` shares the Quickshell-dependent
  `Compositor` singleton's module. Do not mock Quickshell to cross this boundary.
- `compare()` handles objects/arrays but tolerates small numeric differences.
  Use `verify(actual === expected)` for exact values/identity and `fuzzyCompare`
  for explicit tolerances. Do not compare objects via JSON serialization.
- `compositor-test` checks real scale-config anchors, Hyprland's Lua/TSV contract
  with an `hl` spy and temporary `HOME`, and niri's KDL. It does not test dispatch.
- Use the devshell's pinned Qt tools, not Mason's standalone `qmlls`. Launch
  Neovim from the repo so it inherits `PATH` and `QML_IMPORT_PATH`. The flake
  supplies both Qt imports and Quickshell metadata; deployed Qt must match the
  pin after updates. `qml-test` clears the GTK platform theme for offscreen SSH.
- `Ui/qmldir` must list new QML types in `Ui/` for tooling. `.qmllint.ini` is shared
  by the editor and CLI. Lint currently reports pre-existing warnings without
  failing; compare diagnostics with the baseline.
- Keep `hypr/.luarc.json`: rooting LuaLS at the entire repository can exhaust the
  VM. Hyprland watches only `hyprland.lua`; changes to `monitors.lua` need reload.

## Deployment safety

Discover the VM address each session:

```sh
VM=$(awk -F= '/name=wily-vm/{f=1} f&&/ip_address/{print $2; exit}' /var/db/dhcpd_leases)
```

Inspect target changes and preserve unrelated edits before syncing. Before any
live file replacement or restart, check the lock and record/temporarily disable
idle locking; hot reload can happen during copying. Restore the previous idle
setting afterward. **Never restart Quickshell while locked**: the compositor
keeps the session lock after its client dies.

```sh
qs ipc call idle status
qs ipc call idle disable
qs ipc call lock isLocked
```

Sync the checkout before live validation or a user-run rebuild, which evaluates
the VM clone. Exclude platform-specific direnv state; checksums avoid replacing
identical compositor files solely because timestamps differ.

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@"$VM":~/.dotfiles/
ssh fredrik@"$VM" 'cd ~/.dotfiles && git add -AN .'
```

New/moved files need the normal Stow activation from the root `CLAUDE.md`.
Never create Stow links manually or run `git clean -fd` in the VM clone.
`rsync`, Git checkouts, and `sed -i` can replace inodes; restart the unlocked
shell after deployment rather than relying on its watcher:

```sh
systemctl --user restart quickshell.service
```

For ordinary `qs ipc` and compositor commands over SSH, provide the active
session's `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and compositor socket/signature
from `systemctl --user show-environment`. Missing display context can make live
Quickshell instances appear dead. `shell-smoke` avoids that by selecting the PID.

## Session and hardware constraints

- Keep `wayland-session-waitenv.service`: niri announces readiness before it
  publishes `WAYLAND_DISPLAY` to the user manager. Bind shell/sleep-lock units
  to compositor-specific targets; ordering after `graphical-session.target`
  creates a cycle.
- Quickshell unsets systemd's sparse `PATH` to inherit the UWSM session path.
  Removing that breaks launcher entries and `uwsm-app`.
- `Ui/Panel.qml` has a top-bar cutout so bar buttons can switch panels. Preserve
  focus-chain membership for visible but unavailable controls. The shell owns
  keyboard-layout state; compositor-side XKB toggles would desynchronize it.
- Tray submenus require one live opener per level. `QsMenuEntry.display()` needs
  a platform menu this shell does not have.
- UTM has one virtio output, no Wi-Fi/Bluetooth, battery, backlight, lid, touchpad,
  fingerprint reader, or hardware cursor plane. Validate those on the ThinkPad.
- UTM pauses time while macOS sleeps; keep chrony. Its old virgl OpenGL requires
  software rendering for Ghostty. macOS captures some SUPER chords; distinguish
  host key capture from compositor bind failures.
- DPMS-off can resemble a frozen VM. Use bounded commands; `grim` can hang while
  no output produces frames. Recovery is `hyprctl dispatch 'hl.dsp.dpms("on")'`.
- Prefer purpose-built applications to large bespoke panels for infrequent tasks.
