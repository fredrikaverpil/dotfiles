# Developing kaizen

How to work on kaizen. Its design, layers and map, with where each part lives
and which hosts it reaches, are in [`README.md`](README.md).

Every kaizen host shares one copy of the core, so an edit lands on all of them
at once: there is no promotion step and no drift to diff for.

To try another shell, compositor or panel on one machine, use a git branch or
worktree, not a per-host copy of the tree.

Document constraints, rationale and gotchas, not implementation inventories or
previous states. Explain a declaration next to it, not in these docs. Machine
facts (firmware, BIOS, hardware quirks) belong in the host's `README.md` or
`nix/shared/system/thinkpad.nix`.

## Working model

The desktop is built to be developed by an agent, usually run on the host
itself, sometimes over SSH. Every part is reachable: `kaizen ipc` queries and
drives shell services and panels, `niri msg` the compositor,
`systemctl --user` the units, `grim` and the recording service capture what is
on screen, and `wtype` and `wlrctl` take over the keyboard and the pointer to
press keys, point and click. Use them to verify your own work; what they cannot
prove is listed under "Required local validation".

## Versions

Your memory of Quickshell, Qt and niri may predate the pins, which move with
`nix flake update`. Check them first:

```sh
qs --version
niri --version
nix eval --raw .#nixosConfigurations.<host>.pkgs.qt6.qtdeclarative.version
```

Look up a Quickshell type, property or signal in Context7 at the pinned version
before using one that this tree does not already use, or when `qml-lint`
rejects one. For niri, do the same for a config node or action missing from
`niri/config.kdl`. `qml-lint` and `compositor-test` catch removed or misspelled
API, not features you did not know about.

Context7 indexes Quickshell per release
(`/websites/quickshell_v<major>_<minor>_<patch>`); its niri and Qt docs track
upstream's latest, and niri marks each option with the version it arrived in
("Since: 26.04").

## Gotchas

- Nix comments carry the "why" for packages, portals, PAM and hardware
  integration, and the units' comments for the units. Read
  `nix/shared/system/kaizen/default.nix`,
  `stow/kaizen/.config/systemd/user/`,
  `nix/shared/system/linux-desktop.nix` and `nix/shared/system/thinkpad.nix`,
  plus the host's `configuration.nix`, before asking.
- SSH keys come from the Proton Pass app's agent (`SSH_AUTH_SOCK` in
  `nix/shared/system/linux-desktop.nix`), so the app must be running. While it
  is locked, a key request waits 60 s for an unlock, then fails as
  `Permission denied (publickey)`. The app asks by showing its window, which
  niri ignores for a mapped window (no focus, no urgency), so the prompt stays
  on workspace 7; unlocking there within the minute lets the waiting `ssh`/`git`
  proceed.
- Apps differ in the actions and hints their notifications carry, and the shell
  logs none of it. `kaizen ipc call notifications toggleCapture` records each
  arriving notification's raw data, message text included, in memory (a new
  capture each time it is turned on); `captured` returns it as JSON. It is off
  after every shell restart. Capture a real one before handling an app's
  notifications specially.
- Whether Slack sent a notification at all is in its own logs:
  `~/.config/Slack/logs/default/webapp-console*.log` (`Store:
  NEW_NOTIFICATION` with a channel id, content redacted) and `browser.log`
  ("Creating new Electron notification"). What became of each toast shows in
  `dbus-monitor --session "interface='org.freedesktop.Notifications'"`:
  `NotificationClosed` reason 1 is a toast that expired on screen, 2 one
  dismissed or dropped untracked under DnD.
- `notify-send -a <app> <summary> <body>` fakes an app's notification, to try a
  notification rule without waiting for the real one, for example
  `notify-send -a Slack "[workspace] in #alerts" "<https://example.com|View>"`.
  It carries only what you pass, so copy the summary and body from a captured
  one.
- User units are named `kaizen-<name>`, plugin daemons included
  (`kaizen-dcal`). Units that must stay out of a non-kaizen session are listed
  in [`kaizen units`](../../stow/kaizen/.local/libexec/kaizen/units).
- Niri event IDs are global; UI labels/actions use output-local workspace `idx`.
- Niri KDL booleans are presence-only, not `option true`.
- Use `keyNavigation` for ordinary focus chains; use a panel-managed cursor
  where it cannot represent a control, such as a slider.
- `Ui/Panel.qml` has a top-bar cutout so bar buttons can switch panels. Preserve
  focus-chain membership for visible but unavailable controls.
- Tray submenus require one live opener per level. `QsMenuEntry.display()` needs
  a platform menu this shell does not have.
- Read the reference shell's source before changing a feature ported from it
  (`git clone` if missing and `git pull` its source before reading):
  - `~/code/public/github.com/caelestia-dots/shell`
  - `~/code/public/github.com/AvengeMedia/DankMaterialShell`
  - `~/code/public/github.com/snowarch/iNiR`
  - `~/code/public/github.com/Gakuseei/Ricelin`
  - `~/code/public/github.com/0xbbuddha/dotfiles_nothing_os`
  - `~/code/public/github.com/omacom/omarchy`
  - and `https://noctalia.dev/plugins` which contains a registry of plugins
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
| JS/QML | `qml-format`, `qml-test`, `qml-lint`, `requires-check` (any platform) |
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
  It checks actual service IPC, runtime errors and QML warnings (`WARN scene:`,
  `WARN qml:`). `--panels` additionally opens, queries, then closes Display,
  closing any competing panel. It refuses that operation while locked and does
  not change scaling or device settings. Its journal scan covers everything
  since the last service start; restart the service before re-running to clear
  stale errors.
- `kaizen doctor` lists the warnings and errors from each `kaizen-*` unit's
  current run, and checks units, the shell's binary, niri's config, the plugin
  dirs and the `requires` files; `--json` prints one document, and journalctl
  arguments (`--since -1h`, `-b -1`) report that span of the journal instead,
  without the checks. Follow the units with
  `journalctl --user -u 'kaizen-*' -f`. Quickshell logs everything at priority 6
  with the level in the text, so `journalctl -p warning` misses it. The bar's
  doctor indicator shows whenever it reports anything.
- Smoke checks do not prove focus, object lifetime, authentication, daemon
  recovery, or physical input. Exercise affected paths explicitly. Agree on a
  recovery path before lock/PAM, suspend, DPMS-off, or connectivity tests.
- Hardware-dependent paths: Wi-Fi/Bluetooth, battery, backlight, lid,
  touchpad, fingerprint reader, `GAMMA_LUT` (nightlight). Validate on the
  machine.
- Test keyboard-first panels over SSH: open the panel with `kaizen ipc call`,
  confirm it is the only `Keyboard interactivity: exclusive` layer in
  `niri msg layers`, then use the devshell's `wtype -k z`. Niri drops
  virtual-keyboard input before bind handling, so `wtype` cannot test
  compositor binds.
- Test a window, such as a plugin's application, the same way: focus it
  (`niri msg action focus-window --id ID`) and check `niri msg -j
  focused-window` before every key, or keys land in the user's window. Run
  each round as one command that opens a fresh window, focuses it, sends the
  keys and closes it: the user may be answering an agent's permission prompt
  in their terminal between commands, which takes focus. Never reuse a window
  across commands: it restores its last focused item, such as a draft's field.
  Give focus back afterwards. `wtype -M shift -k Tab` arrives as Tab with Shift
  held, not as Backtab.
- Enter or Space acts on whatever has focus, and a few Tabs away there is
  usually a delete or a paid run (an investigator's Discard or Re-run). Send
  them only to a control a capture in the same command showed focused, and
  never after a Tab sequence whose start depends on an earlier step. A round
  stops at its first failed step: one command per line under `set -e`, not
  lines of `a && b`, since a failing `&&` list does not trip `set -e` and the
  next line still runs. Clear any filter a round set before it ends.
- Drive the pointer with the devshell's `wlrctl pointer move DX DY` and
  `wlrctl pointer click [left|right]`. Moves are relative and niri does not
  report the cursor's position, so confirm where it is with a capture before
  clicking. Never move it into the top-left corner, which opens niri's
  overview. `wlrctl` cannot hold a button, so a drag is the user's to check; a
  double-click selects a word.
- Use `grim` to check how the shell looks; `kaizen ipc` and `shell-smoke` for
  internal state. Crop with `-g "0,0 1280x32"` (layout coordinates) or capture
  one output with `-o`; the two do not combine. Capture cost depends only on
  the area. Niri does not report layer geometry, so derive the bar's from
  `niri msg --json outputs` and `barHeight` in `shell.qml`.
- To record, `kaizen ipc call recording capture WxH+X+Y` (`0x0+X+Y` is the whole
  monitor): no countdown, audio or camera, and the bar shows it. It returns the
  file; `kaizen ipc call recording stop` finalizes it. Extract frames with
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
kaizen ipc call idle status
kaizen ipc call idle disable
kaizen ipc call lock isLocked
```

New/moved files need `~/.dotfiles/stow.sh`, which also removes the links a
move left behind and reloads the user manager; an edited unit needs
`systemctl --user daemon-reload`. Never create Stow links manually or run
`git clean -fd` in the host clone.

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
systemctl --user restart kaizen-shell.service
```

For ordinary `kaizen ipc` and compositor commands over SSH, provide the active
session's `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `NIRI_SOCKET` from
`systemctl --user show-environment`. Missing display context can make live
Quickshell instances appear dead. `shell-smoke` avoids that by selecting the
PID.
