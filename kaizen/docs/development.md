# Developing kaizen

How to work on kaizen. Its design, layers and map, with where each part lives
and which hosts it reaches, are in [`README.md`](../README.md).

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
on screen, and `kaizen keys` and `wlrctl` take over the keyboard and the
pointer to press keys, point and click. Use them to verify your own work; what
they cannot prove is listed under "Required local validation".

Each `kaizen` command carries a rule the raw tool leaves to you:

| To | Use | Not |
| --- | --- | --- |
| Query or drive a shell service or panel | `kaizen ipc` | `qs ipc`, which needs the unit's PID |
| Learn whether the desktop is healthy | `kaizen doctor` | `journalctl -p warning`, which misses Quickshell's log level |
| Learn the shell's state: unit, PID, tree, lock | `kaizen status` | `systemctl --user show` and `qs ipc`, each half of it; `qs` prints its errors as answers |
| Apply a change to the shell's files and see its QML errors | `kaizen reload` | `kaizen ipc call shell reload`, which reports no load failure and returns before the load |
| See a worktree's QML live | `kaizen dev` | editing main's tree |
| Restart the shell | `kaizen reload --restart` | `systemctl --user restart`, which restarts while locked |
| Capture an output or its bar | `kaizen shot` | `grim` by hand, which guesses the output and leaves the curtain lifted on failure |
| Press keys in a panel, menu or window | `kaizen keys` | `wtype`, which types into whatever holds the keyboard: your terminal, or the lock's password field |
| Focus an app or open it | `kaizen focus` | `niri msg action focus-window`, which needs the window id and never opens the app |
| List the commands | `kaizen --json` | `ls ~/.local/libexec/kaizen`, which lists none of the usage |

## Versions

Your memory of Quickshell, Qt and niri may predate the pins, which move with
`nix flake update`. Check them first:

```sh
qs --version
niri --version
umbriel --version  # the flake input's commit
nix eval --raw .#nixosConfigurations.<host>.pkgs.qt6.qtdeclarative.version
```

Look up a Quickshell type, property or signal in Context7 at the pinned version
before using one that this tree does not already use, or when `qml-lint` rejects
one. For niri, do the same for a config node or action missing from
`niri/kaizen.kdl` and the hosts' `config.kdl`. For umbriel, read its
`docs/user/` at the pinned commit, or `umbriel config schema --json`, for a key
or action missing from `umbriel/kaizen.toml`. `qml-lint` and `compositor-test`
catch removed or misspelled API, not features you did not know about.

Context7 indexes Quickshell per release
(`/websites/quickshell_v<major>_<minor>_<patch>`); its niri and Qt docs track
upstream's latest, and niri marks each option with the version it arrived in
("Since: 26.04").

## Gotchas

- Nix comments carry the "why" for packages, portals, PAM and hardware
  integration, and the units' comments for the units. Read
  `kaizen/nix/default.nix`,
  `kaizen/stow/.config/systemd/user/`,
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
  `notify-send -a Slack "[workspace] in #alerts" $'Error rate high\nView alert'`.
  It carries only what you pass, so copy the summary and body from a captured
  one: Slack's body is plain text, a link only its label.
- `kaizen status` prints the shell's state, one `key value` line per fact or
  one JSON document with `--json`: the unit's state and PID, whether
  `kaizen dev` runs it, whether it answers IPC (`error` says why not), and
  `kaizen ipc call shell status`: the tree it runs, the bar's height, and the
  lock, curtain and idle services' `status`. A fact it could not learn is
  `null`. It exits 0 whatever the shell's state. Read it rather than querying
  the services one by one.
- `kaizen reload` hot-reloads the shell, or restarts its unit after
  `systemctl --user daemon-reload` when it is down, never loaded its config, or
  with `--restart`. It waits until the shell has loaded its config and answers,
  prints the warnings and errors it logged meanwhile, and exits 1 when the
  config failed to load. It refuses while the session is locked.
- User units are named `kaizen-<name>`, plugin daemons included
  (`kaizen-dcal`).
- A bind, unit or script that may run while the shell restarts calls
  `kaizen ipc -q call ...`: silent, and exit 0 when the shell is down or the
  call fails. Without `-q` the call exits 1 with a message.
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
from the shell on macOS. All of them run against the single `kaizen/stow/`
tree, so a static check passing here passes for every kaizen host;
`compositor-test` also validates each host's niri `config.kdl` with its
includes.

| Change | Checks |
| --- | --- |
| Nix | `nix fmt`, `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`; build both kaizen hosts, a shared module breaks both; the build fails on a `requires` `cmd`, `file` or `data` line the host does not install |
| JS/QML | `qml-format`, `qml-test`, `qml-lint`, `requires-check` (any platform) |
| The `kaizen` command (Go) | `go test ./...` and `go vet ./...` in `kaizen/cli/`; build both kaizen hosts, whose build runs the tests |
| Compositor interface, config (`kaizen.kdl`, `kaizen.toml` or a host's compositor config), or bind contract | Also `compositor-test` (Linux) |
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
  current run, and checks units, the shell's binary, the compositor's config,
  the portal, `gsr-kms-server`'s capability, the plugin dirs and manifests and
  the `requires` files;
  `--json` prints one document, each finding with its check's stable `id`
  and, when there is one, its fix as `hint`; journalctl arguments
  (`--since -1h`, `-b -1`) report that span of the journal instead, without
  the checks. Follow the units with `journalctl --user -u 'kaizen-*' -f`.
  Quickshell logs everything at priority 6 with the level in the text, so
  `journalctl -p warning` misses it. The bar's doctor indicator shows whenever
  it reports anything.
- Smoke checks do not prove focus, object lifetime, authentication, daemon
  recovery, or physical input. Exercise affected paths explicitly. Agree on a
  recovery path before lock/PAM, suspend, DPMS-off, or connectivity tests.
- Hardware-dependent paths: Wi-Fi/Bluetooth, battery, backlight, lid,
  touchpad, fingerprint reader, `GAMMA_LUT` (nightlight). Validate on the
  machine.
- Test keyboard-first panels over SSH: open the panel with `kaizen ipc call`,
  then `kaizen keys --layer NAMESPACE KEY...` with its namespace from
  `niri msg layers` (`umbriel layers` on umbriel). It presses each key only
  while that layer alone holds the keyboard (`exclusive`), lifts the curtain
  meanwhile, and refuses while locked. A key is a chord of xkb names
  (`Return`, `ctrl+k`, `shift+Tab`, which arrives as Tab with Shift held, not
  as Backtab); a key that moves the keyboard elsewhere, such as an Esc that
  closes the panel, comes last. Niri drops virtual-keyboard input before bind
  handling, so it cannot test compositor binds.
- Test a window, such as a plugin's application, with
  `kaizen keys --window ID KEY...`: it focuses the window, presses each key
  only while the window has focus and no layer holds the keyboard, and gives
  focus back to the window that had it. Run each round as one command that
  opens a fresh window, sends the keys and closes it: never reuse a window
  across commands, since it restores its last focused item, such as a draft's
  field.
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
- Use `kaizen shot` to check how the shell looks; `kaizen ipc` and
  `shell-smoke` for internal state. It names the output it captured and prints
  the file, under `~/.cache/kaizen-shell/shots/` unless `-o` says otherwise. It
  takes the output as an argument, and without one picks the only output, or
  the one holding an open panel, menu or launcher; the focused output follows
  the user, so it is never the default, and with several candidates it lists
  them and exits 2. `--bar` captures that output's bar, and a `WxH+X+Y`
  argument a region of it, relative to the output. The longest edge is scaled
  to 1600 px so a 4K output reads like a laptop panel; `--full` keeps native
  pixels, which a region is for. It lifts the curtain for the capture and puts
  it back, and refuses while locked. `grim` itself crops with
  `-g "0,0 1280x32"` (layout coordinates) or captures one output with `-o`;
  the two do not combine, and capture cost depends only on the area. Niri does
  not report layer geometry, so the bar's height comes from
  `kaizen ipc call shell barHeight` and its width from
  `niri msg --json outputs`.
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
- Use the devshell's pinned Qt tools, not a standalone `qmlls`. Launch
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
- It refuses to run off AC, outside the `balanced` profile, while locked, with
  the curtain up, or at a 1-minute load of 1.5 or more. The restart applies
  the profile the shell saved for AC, so it rechecks power after warm-up and
  before writing the row. It warns when the system was over 10% busy; discard
  such rows.
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
  devshell's `qmlprofiler --attach localhost:PORT`. That shell runs outside
  `kaizen-shell.service`, so `kaizen ipc` and the binds miss it; reach it with
  `qs ipc -c kaizen`.

## Working from a worktree

Static checks (`qml-*`, `requires-check`, `compositor-test`) and Nix builds run
in the worktree. To see its QML live:

```sh
kaizen dev .      # from the worktree's root, or kaizen dev NAME (its directory)
kaizen dev        # prints the shell tree kaizen-shell runs
kaizen dev off    # back to main's
```

- `kaizen dev PATH` restarts `kaizen-shell.service` on the worktree's shell
  tree through a drop-in under `$XDG_RUNTIME_DIR`, as
  `kaizen reload --restart` does, with the shell's warnings and errors on
  stderr; Quickshell then hot-reloads the tree's edits.
  It fails unless the unit runs that tree, and `kaizen ipc`, the binds and
  `shell-smoke` reach it. `kaizen doctor` warns while it does, and checks the
  worktree's `requires` and plugins. A reboot returns to main's.
- An agent runs it without asking. It refuses while locked: the rule below
  applies.
- Only the shell's QML, generic plugins included, comes from the worktree.
  Scripts, units, niri's config, a host's plugins and the investigator's `-dir`
  stay main's, so changes to them still go through main. The worktree's own
  `./kaizen/cli/kaizen` runs its scripts: Building kaizen.
- One worktree is live at a time. Run `kaizen dev off` before removing the
  worktree or ending the task. A removed worktree, or QML that fails to load,
  leaves the unit failing; `kaizen dev off` recovers either.

## Building kaizen

`kaizen` is a Go binary built from [`kaizen/cli/`](../cli/). A rebuild
compiles it into the system profile, and a failing test fails the rebuild. Go
comes from the default devshell. To use a change without a rebuild:

- In a worktree, `go build -o kaizen .` in `kaizen/cli/` writes
  `kaizen/cli/kaizen`; run it by path (`./kaizen/cli/kaizen --json`). It runs
  the worktree's scripts, and a script's `kaizen` is the same binary. Never install it: units, binds and QML
  keep main's `kaizen`.
- In `~/.dotfiles`,
  `nix develop ~/.dotfiles -c ~/.dotfiles/kaizen/cli/build.sh` installs
  `~/.local/bin/kaizen`, which precedes the system profile's on PATH: shells,
  binds and QML take it at once, units on their next start. It refuses
  anywhere else, since parallel sessions share `~/.local/bin`. A rebuild
  deletes it, returning to the system profile's; until then `kaizen doctor`
  warns, naming its commit (`kaizen --version`).

## Deployment safety

On the host, `~/.dotfiles` is this checkout and the live stowed tree: edits
deploy as they are saved. From another host it is reached over SSH as
`fredrik@<host>`.

Before any live file replacement, inspect target changes and preserve
unrelated edits. Quickshell's watcher can hot-reload during copying, with no
lock guard, so record and temporarily disable idle locking, and restore it
afterward. **Never restart Quickshell while locked**: the compositor keeps the
session lock after its client dies. `kaizen reload` and `kaizen dev` refuse
while locked.

```sh
kaizen ipc call idle status
kaizen ipc call idle disable
```

New/moved files need `~/.dotfiles/stow.sh`, which also removes the links a
move left behind and reloads the user manager; an edited unit needs
`systemctl --user daemon-reload`, which `kaizen reload --restart` runs for the
shell's. Never create Stow links manually or run `git clean -fd` in the host
clone.

When working from another host, sync the checkout before live validation or a
user-run rebuild, which evaluates the host's clone. Checksums avoid replacing
identical compositor files solely because timestamps differ. The host may
carry uncommitted theme edits in `kaizen/stow/`; check `git status`
there before `--delete`.

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@<host>:~/.dotfiles/
ssh fredrik@<host> 'cd ~/.dotfiles && git add -AN .'
```

`rsync`, Git checkouts, and `sed -i` can replace inodes, so restart the
shell after deployment rather than relying on its watcher:

```sh
kaizen reload --restart
```

It reloads the user manager, restarts `kaizen-shell.service`, waits until the
shell has loaded its config and answers, and prints its warnings and errors.
It refuses while the session is locked, so use it instead of
`systemctl --user restart`.

For compositor commands over SSH, provide the active session's
`XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `NIRI_SOCKET` (`UMBRIEL_SOCKET` on
umbriel, without which the `kaizen` commands drive niri) from
`systemctl --user show-environment`. `kaizen ipc` and `shell-smoke` select the
shell by its unit's PID, so they need no display context.
