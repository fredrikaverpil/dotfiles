# niri + Quickshell desktop

This file documents the niri + Quickshell desktop and lives with it. Every
host running it shares one copy of everything: `desktop.nix` in this
directory, `../thinkpad.nix` next to it, and the compositor config and QML in
`stow/kaizen/`. An edit lands on every kaizen host at once, so there is no
promotion step and no drift to diff for.

What stays per host, in `nix/hosts/<host>/`: hardware and firmware settings
(`hardware-configuration.nix`, disk and resume devices, GPU drivers, sleep
policy), host-only programs and packages (`programs.*` set directly in
`configuration.nix`, `host.extraSystemPackages`, `personal.nix`), work-only
configuration (the `einride` submodule and what it pulls in), and the mpv
decode profile in `stow/host/<host>/`.

To try another shell, compositor or panel on one machine, use a git branch or
worktree, not a per-host copy of the tree.

Machine facts (firmware, BIOS, hardware quirks) belong in the host's
`README.md`, never here. Design intent and the layer model are in `KAIZEN.md`;
read it before adding a surface or service.

## Working model

- The desktop is keyboard-first. Every panel, dialog and bind works without a
  pointer; pointer-only controls are bugs.
- The desktop is built to be developed by an agent, usually run on the host
  itself, sometimes over SSH. Every part is reachable: `qs ipc` queries and
  drives shell services and panels, `niri msg` the compositor,
  `systemctl --user` the units, `grim` and the recording service capture what
  is on screen. Use them to verify your own work; what they cannot prove is
  listed under "Required local validation".

Document constraints, rationale and gotchas, not implementation inventories or
previous states. Explain a declaration next to it, not here.

## Gotchas

- "kaizen" names the shell (PAM `kaizen-lock`, `kaizen-*` units, layer
  namespaces, D-Bus path, state files). It is host-agnostic; `renoir` and
  `wily` are only hostnames.
- Nix comments carry the "why" for packages, portals, PAM, units and hardware
  integration. Read `desktop.nix` here and `../thinkpad.nix`, plus the host's
  `configuration.nix`, before asking.

## Architecture

- `desktop.nix` owns packages, portals, PAM, systemd units and the pre-suspend
  lock. `stow/kaizen/` owns compositor configuration and QML.
- `shell.qml` wires services and surfaces. Views belong in `plugins/panels/`;
  daemon/process state belongs in `plugins/services/`.
- Interactive surfaces come in three kinds; pick by what opens them:
  - Launcher (`plugins/menu/`): a large `Ui.Panel` drilling down through
    levels; the keyboard entry point to everything, tray menus included.
  - Panel (`Ui/Panel.qml`): a centered card for settings and views; `h`/`l`
    step focus.
  - Context menu (`Ui/ContextMenu.qml`): hangs from the bar button that opened
    it, on that button's output, sized to its rows; submenus cascade beside
    their row and `h`/`l` close and open them. Opened without a button
    (launcher, IPC), it resolves the focused output from the compositor.
  All three hold exclusive keyboard focus and close each other through
  `shell.claimPanel`.
- `Ui/Compositor.qml` is the compositor interface; `Ui/compositors/` owns niri
  commands, response parsing, and the workspace source. Views use that
  interface. Keep scheduling and shared state above it. Nightlight is not
  compositor-specific and lives in its service.
- Prefer purpose-built applications to large bespoke panels for infrequent
  tasks (bluetui pairs, nm-connection-editor edits connections, nwg-displays
  owns outputs).
- Clipboard history is in memory only and skips offers carrying
  `x-kde-passwordManagerHint`. Proton Pass and 1Password set it; a password
  manager that does not would be recorded.
- The screensaver is a privacy curtain, not a lock: an overlay layer surface
  (`kaizen-screensaver`), never `WlSessionLock`, and it never touches DPMS. Both
  are deliberate. A session lock replaces output content and a disabled output
  has nothing to copy, so either one defeats wlr-screencopy; the curtain exists
  so `qs ipc call screensaver close` leaves a desktop `grim` can still capture
  remotely. It dims the internal backlight to 0 while black and restores it
  before drawing the prompt, so the prompt is never painted onto a dark panel.
  Being only a layer surface, it dies with Quickshell, and anyone at the
  keyboard can close it. Use the lock whenever the machine is left alone.
- The recording camera is a circle because gpu-screen-recorder cannot mask its
  own camera overlay: the service runs mpv under the `kaizen-camera` app id and
  a niri window rule rounds and places it, so the screen capture records it as
  ordinary screen content. It must therefore sit inside a recorded region, and
  mpv sizes in device pixels, which is why the service asks niri for the
  focused output's scale instead of using Qt's rounded `devicePixelRatio`.
  niri has neither an aspect-ratio rule nor sticky windows, and mpv accepts any
  size it is given, so while the preview is up the service follows the event
  stream: it sets the window's height back to its width and moves it to each
  workspace that gains focus.
  Its diameter is a share of the captured frame's short side, so it covers the
  same part of the recording on a region as on an output of any resolution.
  The window rule's corner is the output's, which a region rarely reaches, so a
  region's circle is moved into the region's own bottom-right.
  `move-floating-window` takes coordinates in the output's working area, which
  the bar shortens at the top, and reads a bare negative number as a relative
  move.
  Both the scale and those coordinates belong to the output the circle opened
  on, which is whichever one had focus, so starting a recording *with a camera*
  focuses the output being captured. Recording without one never moves focus.
- The recording service also owns the region screenshot (`grim`), because that
  reuses its region selector; `selectMode` says which of the two the selection
  feeds. Niri's own `screenshot` binds are unrelated and stay compositor-side.
- Niri event IDs are global; UI labels/actions use output-local workspace `idx`.
- Niri KDL booleans are presence-only, not `option true`.
- Every surface must be usable from the keyboard. Use `keyNavigation` for
  ordinary focus chains; use a panel-managed cursor where it cannot represent
  a control, such as a slider. Pointer-only controls are bugs.
- `Ui/Panel.qml` has a top-bar cutout so bar buttons can switch panels. Preserve
  focus-chain membership for visible but unavailable controls. The shell owns
  keyboard-layout state; compositor-side XKB toggles would desynchronize it.
- Tray submenus require one live opener per level. `QsMenuEntry.display()` needs
  a platform menu this shell does not have.
- Read the relevant Omarchy source before changing a ported feature (and
  `git pull` its source before reading):
  `~/code/public/github.com/omacom/omarchy`. Complementary references are:
  - `~/code/public/github.com/caelestia-dots/shell`
  - `~/code/public/github.com/AvengeMedia/DankMaterialShell`
  - `~/code/public/github.com/0xbbuddha/dotfiles_nothing_os`.
- Any open source/public projects we might want to adopt/inspect can be cloned
  into `~/code/public/`.

## Required local validation

Run relevant checks **before and after editing**, on the correct platform.
These are development gates, not CI jobs. They live only in the repository's
default devshell (`flake.nix`), entered by `direnv` at the repo root or run as
`nix develop ~/.dotfiles -c <command>` (not `#dev`) from anywhere in the
checkout. `compositor-test` and `shell-smoke` are Linux-only and are absent
from the shell on macOS. All of them run against the single `stow/kaizen/`
tree, so a static check passing here passes for every kaizen host.

| Change | Checks |
| --- | --- |
| Nix | `nix fmt`, `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`; build both kaizen hosts, a shared module breaks both |
| JS/QML | `qml-test`, `qml-lint` (any platform) |
| Compositor interface, config, or bind contract | Also `compositor-test` (Linux) |
| Service IPC, `shell.qml` wiring, or systemd units | Also `shell-smoke` on the machine after deploy and restart, and exercise the affected path |
| Panel views | Also `shell-smoke --panels` |
| Device-dependent behaviour | Also validate on the actual ThinkPad |
| Timers, `Process`/`FileView`, services, panels, or `shell.qml` wiring | Ask the user whether to run `shell-perf` after deploy (see Performance) |

- Establish the target checkout, flake pin, and session first. Record baseline
  failures; after editing, check an isolated Linux copy before deploying into
  the live stowed tree. Repeat checks against the deployed shell.
- Mac tests are supplementary. Report unavailable session/hardware coverage as
  **pending**, never substitute another platform or claim full validation.
- `shell-smoke` selects the running systemd service's PID and works over SSH.
  It checks actual service IPC and runtime errors. `--panels` additionally
  opens, queries, then closes Display, closing any competing panel. It refuses
  that operation while locked and does not change scaling or device settings.
  Its journal scan covers everything since the last service start; restart the
  service before re-running to clear stale errors.
- Every Quickshell start logs `qt.qpa.services: Failed to register with host
  portal ... Connection already associated with an application ID`. It is a
  known baseline (since at least 2026-09-11), passes `shell-smoke`, and has no
  observed effect; the root cause is unverified. Do not attribute it to a
  change.
- Smoke checks do not prove focus, object lifetime, authentication, daemon
  recovery, or physical input. Exercise affected paths explicitly. Agree on a
  recovery path before lock/PAM, suspend, DPMS-off, or connectivity tests.
- Hardware-dependent paths: Wi-Fi/Bluetooth, battery, backlight, lid,
  touchpad, fingerprint reader, `GAMMA_LUT` (nightlight). Validate on the
  machine.
- Test keyboard-first panels over SSH: open the panel with `qs ipc call`,
  confirm it is the only `Keyboard interactivity: exclusive` layer in
  `niri msg layers`, then use `wtype -k z`. Niri drops virtual-keyboard input
  before bind handling, so `wtype` cannot test compositor binds.
- Use `grim` to check how the shell looks; `qs ipc` and `shell-smoke` for
  internal state. Crop with `-g "0,0 1280x32"` and pick the output with `-o`;
  capture cost depends only on the area. Niri does not report layer geometry,
  so derive the bar's from `niri msg --json outputs` and `barHeight` in
  `shell.qml`.
- To record, `qs ipc call recording capture WxH+X+Y` (`0x0+X+Y` is the whole
  monitor): no countdown, audio or camera, and the bar shows it. It returns the
  file; `qs ipc call recording stop` finalizes it. Extract frames with
  `nix shell nixpkgs#ffmpeg`.
- DPMS-off can resemble a frozen machine. Use bounded commands; `grim` can hang
  while no output produces frames. Recovery is
  `niri msg action power-on-monitors`.
- Report host/session, before/after results, existing diagnostics, and
  omissions. Ask the user to run Nix rebuilds; never run them without asking.

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
- `compositor-test` validates niri's KDL. It does not test dispatch.

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

### Performance

`shell-perf` (devshell, on the host) restarts the unlocked shell, measures it,
appends a row to `nix/hosts/<host>/shell-perf.tsv` and compares it with the
last row on the same Quickshell build and outputs. Commit the row with the
change it measures.

- Ask the user before running it; it restarts the shell and needs the machine
  untouched for about 10 minutes.
- It refuses to run off AC, outside the `balanced` profile, while locked, or
  at a 1-minute load of 1.5 or more. The restart applies the profile the shell
  saved for AC, so it rechecks power after warm-up and before writing the row.
  It warns when the system was over 10% busy; discard such rows.
- Measure with `eDP-1` only: lid open, no external monitor, on a plain
  USB-C charger (the monitor supplies power; unplugging it drops AC).
- Rows are comparable only within the same `quickshell` build (Qt included)
  and `outputs`. After a flake update or a monitor change, run it on the old
  commit first to get a new baseline.
- Run-to-run noise is uncalibrated. Short test runs varied by about 5 MB PSS
  and 15 MB peak; repeat a run before trusting a delta of that size.
- `shell-perf --soak HOURS [PANEL]` samples PSS each minute, with PANEL held
  open, and records growth in MB/h. Use it for suspected leaks; a few hours
  distinguishes growth from warm-up.
- For per-binding cost, restart with `qs --debug PORT` and attach the
  devshell's `qmlprofiler --attach localhost:PORT`.

## Deployment safety

On the host, `~/.dotfiles` is this checkout and the live stowed tree: edits
deploy as they are saved. From another host it is reached over SSH as
`fredrik@<host>`.

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

New/moved files need the normal Stow activation from the root `CLAUDE.md`;
never create Stow links manually or run `git clean -fd` in the host clone.

When working from another host, sync the checkout before live validation or a
user-run rebuild, which evaluates the host's clone. Checksums avoid replacing
identical compositor files solely because timestamps differ. The host may
carry uncommitted theme edits in `stow/kaizen/`; check `git status`
there before `--delete`.

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@<host>:~/.dotfiles/
ssh fredrik@<host> 'cd ~/.dotfiles && git add -AN .'
```

`rsync`, Git checkouts, and `sed -i` can replace inodes, so restart the
unlocked shell after deployment rather than relying on its watcher:

```sh
systemctl --user restart quickshell.service
```

For ordinary `qs ipc` and compositor commands over SSH, provide the active
session's `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `NIRI_SOCKET` from
`systemctl --user show-environment`. Missing display context can make live
Quickshell instances appear dead. `shell-smoke` avoids that by selecting the
PID.

## Session constraints

- Keep `wayland-session-waitenv.service`: niri announces readiness before it
  publishes `WAYLAND_DISPLAY` to the user manager. Bind shell/sleep-lock units
  to compositor-specific targets; ordering after `graphical-session.target`
  creates a cycle.
- Screen sharing from other apps goes through `xdg-desktop-portal-gnome`,
  which needs the Mutter D-Bus services that niri serves only as
  `niri --session`. Session mode also serves `org.freedesktop.ScreenSaver`
  idle inhibitors and the a11y bus, and takes the power key from logind unless
  `disable-power-key-handling` is set. The shell's own recording never uses a
  portal (`programs.gpu-screen-recorder`).
- On first use, gnome-keyring can advertise `login` without exporting the
  collection when keyring creation follows D-Bus startup. Recover by
  restarting the keyring daemon and unlocking it, then retry account setup.
  Do not delete keyring files.
- Chromium and Electron pick their secret store from `XDG_CURRENT_DESKTOP`.
  They do not recognise `niri` and fall back to `basic_text`, so logins and
  secrets do not persist or are stored under a hardcoded key. Wrap each such
  app with `pkgs.withGnomeLibsecret` (`desktop.nix`), which adds
  `--password-store=gnome-libsecret`; `chromium` passes the flag directly.
  Do not add `GNOME` to `XDG_CURRENT_DESKTOP`: autostart entries such as
  `nm-applet` and `print-applet` use `NotShowIn=GNOME`. Once an app has encrypted secrets with
  the keyring, removing the flag locks it out of them.
- Lid close uses logind defaults: suspend (the sleep-lock unit locks first),
  or nothing when docked. Niri turns off `eDP-1` while docked with the lid
  closed.
