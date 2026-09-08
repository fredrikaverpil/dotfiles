# Wily desktop VM

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
- Nightlight is not compositor-specific: both sessions drive wl-gammarelay-rs
  over `zwlr_gamma_control_v1`, so its commands live in the nightlight
  service, not the compositor backends. Do not reintroduce hyprsunset.
- `Ui/Compositor.qml` selects a named backend registered in
  `CompositorModel.js`. `Ui/compositors/` owns commands, response parsing,
  scaling/focus policies, and workspace sources. Views use that interface, not
  compositor-identity booleans. Keep scheduling and shared state above it; no
  speculative plugin framework.
- Prefer purpose-built applications to large bespoke panels for infrequent
  tasks.
- Calendar credentials and bearer feed URLs are private user state, never
  Nix/Stow values. Keep Secret Service available before starting `dcal`: its
  local encrypted-keyring fallback uses a fixed password. Verify keyring use
  before adding real accounts; the service's startup probe does not guard
  manually launched instances. Password login unlocks GNOME Keyring via PAM;
  fingerprint-only login cannot supply that password.
- On first use, GNOME Keyring can advertise `login` without exporting the
  collection when keyring creation follows D-Bus startup. `OpenSession` alone
  misses this; also probe the collection. Recover by restarting the keyring
  daemon and unlocking it, then retry account setup. Do not delete keyring
  files. Console logout may leave the daemon alive while SSH keeps the user
  manager running.
- Selection requires exactly one session marker: `NIRI_SOCKET` or
  `HYPRLAND_INSTANCE_SIGNATURE`. Missing/ambiguous markers are errors, never an
  implicit Hyprland fallback.
- Load workspace sources by URL: importing `Quickshell.Hyprland` opens a socket.
  Niri event IDs are global; UI labels/actions use output-local workspace `idx`.
- Hyprland Lua option names use underscores even where `hyprctl` prints hyphens.
  Use the LuaLS stub. Niri KDL booleans are presence-only, not `option true`.
- Read the relevant Omarchy source before changing a ported feature (and
  `git pull` its source before reading):
  `~/code/public/github.com/omacom/omarchy`. Complementary references are:
  - `~/code/public/github.com/caelestia-dots/shell`
  - `~/code/public/github.com/AvengeMedia/DankMaterialShell`
  - `~/code/public/github.com/0xbbuddha/dotfiles_nothing_os`.

## Required local validation

Run relevant checks **before and after editing**, on the correct platform.
These are development gates, not CI jobs. They live only in the repository's
default devshell (`flake.nix`), entered by `direnv` at the repo root or run as
`nix develop ~/.dotfiles -c <command>` (not `#dev`) from anywhere in the
checkout. `compositor-test` and `shell-smoke` are Linux-only and are absent
from the shell on macOS.

| Change | Checks |
| --- | --- |
| JS/QML | `qml-test`, `qml-lint` (any platform) |
| Backend, compositor config, or bind contract | Also `compositor-test` (Linux) |
| Service IPC, `shell.qml` wiring, or systemd units | Also `shell-smoke <hyprland\|niri>` on the VM after deploy and restart, and exercise the affected path |
| Panel views | Also `shell-smoke <hyprland\|niri> --panels` |
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
  Its journal scan covers everything since the last service start; restart the
  service before re-running to clear stale errors.
- Smoke checks do not prove focus, object lifetime, authentication, daemon
  recovery, or physical input. Exercise affected paths explicitly. Agree on a
  recovery path before lock/PAM, suspend, DPMS-off, or connectivity tests.
- Test keyboard-first panels over SSH with Hyprland's native
  `hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "", key = "z" })'`.
  In niri, open the panel with `qs ipc call`, confirm it is the only
  `Keyboard interactivity: exclusive` layer in `niri msg layers`, then use
  `wtype -k z`. Niri drops virtual-keyboard input before bind handling, so
  `wtype` cannot test compositor binds. Verified in both sessions.
- Use `grim` to check how the shell looks. To check its internal state, use
  `qs ipc` and `shell-smoke` instead. Crop screenshots to the area you need
  with `-g`, for example `-g "0,0 1280x32"`, and use `-o` to select the output.
  Capture cost depends on the area captured; changing the image format,
  quality (`-q`), or scale (`-s`) does not reduce it. Hyprland reports layer
  positions and sizes in `hyprctl layers -j`. Niri does not, so work out the
  bar's position and size from `niri msg --json outputs` and the `barHeight`
  value in `shell.qml`.
- Report host/session, before/after results, existing diagnostics, and
  omissions. Ask the user to run Nix rebuilds; never run them yourself.

### Tests

- `tst_*.qml` imports production JS directly into QtTest. Keep meaningful pure
  parsing, transforms, and transitions; inline trivial single-use bindings.
  There is no independent JS consumer here, so no Deno/Node/Bun test suite or
  CommonJS export guards.
- QtTest can test Qt-only components, but all transitive imports must be
  Qt-only. Quickshell's native types are linked into its executable, not
  loadable through its installed metadata. Even `Ui/BarButton.qml` shares the
  Quickshell-dependent `Compositor` singleton's module. Do not mock Quickshell
  to cross this boundary.
- `compare()` handles objects/arrays but tolerates small numeric differences.
  Use `verify(actual === expected)` for exact values/identity and `fuzzyCompare`
  for explicit tolerances. Do not compare objects via JSON serialization.
- `compositor-test` checks real scale-config anchors, Hyprland's Lua/TSV
  contract with an `hl` spy and temporary `HOME`, and niri's KDL. It does not
  test dispatch.

### Tooling

- `qml-lint` fails on any warning. Shadowing an Item member that is public API
  (`palette`, IPC-visible `enabled`) or a lookup on an untyped `Loader.item`
  gets an inline `// qmllint disable <category>`; anything else gets fixed.
- Use the devshell's pinned Qt tools, not Mason's standalone `qmlls`. Launch
  Neovim from the repo so it inherits `PATH` and `QML_IMPORT_PATH`. The flake
  supplies both Qt imports and Quickshell metadata; deployed Qt must match the
  pin after updates. `qml-test` clears the GTK platform theme for offscreen SSH.
- `Ui/qmldir` must list new QML types in `Ui/` for tooling. `.qmllint.ini` is
  shared by the editor and CLI.
- Keep `hypr/.luarc.json`: rooting LuaLS at the entire repository can exhaust
  the VM. Hyprland watches only `hyprland.lua`; changes to `monitors.lua` need
  reload.

## Deployment safety

Discover the VM address each session:

```sh
VM=$(awk -F= '/name=wily-vm/{f=1} f&&/ip_address/{print $2; exit}' /var/db/dhcpd_leases)
```

Before any live file replacement or restart, inspect target changes and
preserve unrelated edits, check the lock, and record/temporarily disable idle
locking; hot reload can happen during copying. Restore the idle setting
afterward. **Never restart Quickshell while locked**: the compositor keeps the
session lock after its client dies.

```sh
qs ipc call idle status
qs ipc call idle disable
qs ipc call lock isLocked
```

Sync the checkout before live validation or a user-run rebuild, which evaluates
the VM clone. Checksums avoid replacing identical compositor files solely
because timestamps differ. New/moved files then need the normal Stow activation
from the root `CLAUDE.md`; never create Stow links manually or run
`git clean -fd` in the VM clone.

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@"$VM":~/.dotfiles/
ssh fredrik@"$VM" 'cd ~/.dotfiles && git add -AN .'
```

`rsync`, Git checkouts, and `sed -i` can replace inodes, so restart the
unlocked shell after deployment rather than relying on its watcher:

```sh
systemctl --user restart quickshell.service
```

For ordinary `qs ipc` and compositor commands over SSH, provide the active
session's `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and compositor socket/signature
from `systemctl --user show-environment`. Missing display context can make live
Quickshell instances appear dead. `shell-smoke` avoids that by selecting the
PID.

## Session and hardware constraints

- Keep `wayland-session-waitenv.service`: niri announces readiness before it
  publishes `WAYLAND_DISPLAY` to the user manager. Bind shell/sleep-lock units
  to compositor-specific targets; ordering after `graphical-session.target`
  creates a cycle.
- Quickshell unsets systemd's sparse `PATH` to inherit the UWSM session path.
  Removing that breaks launcher entries and `uwsm-app`.
- Every surface must be usable from the keyboard. Use `keyNavigation` for
  ordinary focus chains; use a panel-managed cursor where it cannot represent
  a control, such as a slider. Pointer-only controls are bugs.
- `Ui/Panel.qml` has a top-bar cutout so bar buttons can switch panels. Preserve
  focus-chain membership for visible but unavailable controls. The shell owns
  keyboard-layout state; compositor-side XKB toggles would desynchronize it.
- Tray submenus require one live opener per level. `QsMenuEntry.display()` needs
  a platform menu this shell does not have.
- UTM has one virtio output, no Wi-Fi/Bluetooth, battery, backlight, lid,
  touchpad, fingerprint reader, or hardware cursor plane. That output has no
  `GAMMA_LUT`, so nightlight cannot apply here: wl-gammarelay-rs accepts the
  DBus write and silently reverts. Verify nightlight on the ThinkPad.
- UTM pauses time while macOS sleeps; keep chrony. Its old virgl OpenGL requires
  software rendering for Ghostty. macOS captures some SUPER chords; distinguish
  host key capture from compositor bind failures.
- DPMS-off can resemble a frozen VM. Use bounded commands; `grim` can hang while
  no output produces frames. Recovery is `hyprctl dispatch 'hl.dsp.dpms("on")'`.
