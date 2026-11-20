# Developing kaizen

Workflow, validation, and deployment guide. For architecture, layers, and file
locations, see [`README.md`](../README.md).

All kaizen hosts share a single copy of the core, so edits land on every host
at once—there is no promotion step and no host drift to reconcile. To test an
alternative shell, compositor, or panel on one machine, use a git branch or
worktree instead of copying files per host.

**Documentation guidelines:** Document constraints, rationale, and gotchas—not
implementation inventories or historical states. Explain specific declarations
in comments next to the code rather than here. Machine-specific facts
(firmware, BIOS, hardware quirks) belong in the host's `README.md` or
`nix/shared/system/thinkpad.nix`.

## Working model

kaizen is built to be developed and verified by an agent, either locally on the
host or over SSH. Every layer is scriptable:

- `kaizen ipc` queries and drives shell services and panels.
- `niri msg` or `umbriel msg` drives the compositor.
- `systemctl --user` manages user units.
- `grim` and the recording service capture the screen.
- `kaizen keys` and `wlrctl` simulate keyboard and pointer input.

Use these tools to verify your changes; see
[Required local validation](#required-local-validation) for what cannot be
proven automatically.

Prefer `kaizen` commands over raw tools—each encodes safety guards that the raw
tool omits:

| Goal | Use | Avoid |
| --- | --- | --- |
| Query or drive a shell service or panel | `kaizen ipc` | `qs ipc` (requires the unit's PID) |
| Check desktop health | `kaizen doctor` | `journalctl -p warning` (misses Quickshell's log levels) |
| Check shell state (unit, PID, tree, lock) | `kaizen status` | combining `systemctl --user show` and `qs ipc` (`qs` prints errors as output) |
| Apply shell edits and see QML errors | `kaizen reload` | `kaizen ipc call shell reload` (returns before loading and hides errors) |
| Test a worktree's QML live | `kaizen dev` | editing main's tree directly |
| Restart the shell | `kaizen reload --restart` | `systemctl --user restart` (will restart while locked) |
| Capture an output or its bar | `kaizen shot` | raw `grim` (guesses the output and can leave the curtain lifted on failure) |
| Send keys to a panel, menu, or window | `kaizen keys` | `wtype` (types into whatever has focus, including your terminal or lock prompt) |
| Focus or launch an app | `kaizen focus` | `niri msg action focus-window` (needs a window ID and cannot launch the app) |
| List available commands | `kaizen --json` | `ls ~/.local/libexec/kaizen` (omits Go subcommands and usage) |

## Versions

Pinned versions of Quickshell, Qt, niri, and umbriel advance with
`nix flake update`, so check them before relying on memory:

```sh
qs --version
niri --version
umbriel --version
nix eval --raw .#nixosConfigurations.<host>.pkgs.umbriel.src.rev
nix eval --raw .#nixosConfigurations.<host>.pkgs.qt6.qtdeclarative.version
```

- **Quickshell:** Look up unfamiliar types, properties, or signals in Context7
  at the pinned release (`/websites/quickshell_v<major>_<minor>_<patch>`)
  before using them, or whenever `qml-lint` rejects one.
- **niri and Qt:** Context7 tracks upstream latest; niri docs mark when each
  option was introduced (for example, "Since: 26.04"). Check any config node or
  action not already used in `niri/kaizen.kdl` or host `config.kdl` files.
- **umbriel:** Check `docs/user/` at the pinned commit, or run
  `umbriel config schema --json`, for any key or action not already in
  `umbriel/kaizen.toml`.

Remember that `qml-lint` and `compositor-test` catch removed or misspelled
APIs, not newer features you did not know existed.

## Gotchas

- **Read inline comments first:** Nix files explain the "why" for packages,
  portals, PAM, and hardware setup; unit files explain unit ordering and
  dependencies. Check `kaizen/nix/default.nix`,
  `kaizen/stow/.config/systemd/user/`, `nix/shared/system/linux-desktop.nix`,
  `nix/shared/system/thinkpad.nix`, and the host's `configuration.nix` before
  asking.
- **Proton Pass SSH agent:** SSH keys come from the Proton Pass app
  (`SSH_AUTH_SOCK` in `nix/shared/system/linux-desktop.nix`), so the app must
  be running. When locked, key requests wait 60 seconds for an unlock before
  failing with `Permission denied (publickey)`. Because niri ignores focus and
  urgency requests from an already-mapped window, the unlock prompt stays
  quietly on workspace 7; unlocking there within the minute lets the waiting
  `ssh` or `git` command proceed.
- **Capturing raw notifications:** Apps vary in the actions and hints they send,
  and the shell does not log them. Run
  `kaizen ipc call notifications toggleCapture` to record incoming
  notifications (including message text) in memory, then call `captured` to
  read them as JSON. Enabling capture starts a fresh buffer, and restarting the
  shell turns capture off. Always capture a real notification before writing
  app-specific rules.
- **Debugging Slack notifications:** Check Slack's logs to see whether it sent
  a notification at all: `~/.config/Slack/logs/default/webapp-console*.log`
  (`Store: NEW_NOTIFICATION` with a channel ID, content redacted) and
  `browser.log` ("Creating new Electron notification"). To trace what happened
  to each toast, run
  `dbus-monitor --session "interface='org.freedesktop.Notifications'"`:
  `NotificationClosed` reason `1` means the toast timed out; reason `2` means
  it was dismissed or dropped untracked while held.
- **Faking notifications for rules:** Use
  `notify-send -a <app> <summary> <body>` to test a rule without waiting for a
  real alert—for example:
  `notify-send -a Slack "[workspace] in #alerts" $'Error rate high\nView alert'`.
  Copy the exact summary and body from a captured notification (Slack sends
  plain text with link labels only, not URLs).
- **`kaizen status`:** Prints shell state as `key value` lines (or JSON with
  `--json`): unit state and PID, whether `kaizen dev` is active, IPC
  reachability (`error` explains failures), and `kaizen ipc call shell status`
  (active tree, bar height, and lock/curtain/idle status). Unknown fields are
  `null`, and the command always exits 0. Prefer it over querying services
  individually.
- **`kaizen reload`:** Hot-reloads the running shell, or runs
  `systemctl --user daemon-reload` and restarts the unit when the shell is
  down, failed to load its config, or `--restart` is passed. It waits until the
  shell loads and answers IPC, prints any warnings/errors logged during load,
  exits 1 if loading fails, and refuses to run while locked.
- **Unit naming:** All user units use the `kaizen-<name>` prefix, including
  plugin daemons (such as `kaizen-dcal`).
- **Quiet IPC in scripts and binds:** Any bind, unit, or script that may fire
  during a shell restart must call `kaizen ipc -q call ...`, which stays silent
  and exits 0 if the shell is down or the call fails. Without `-q`, failures
  print an error and exit 1.
- **niri workspace IDs vs. indices:** niri event IDs are global; UI labels and
  actions use output-local workspace `idx`.
- **niri KDL booleans:** Booleans are presence-only flags, not `option true`.
- **Panel focus chain:** Panels navigate via their focus chain
  (`keyNavigation`) with no separate cursor. Value controls (like
  `Ui/PanelSlider.qml`) consume `h`/`l` and `←`/`→` while letting `↑`/`↓` pass
  through.
- **Panel layout and disabled controls:** `Ui/Panel.qml` leaves a top-bar
  cutout so bar buttons remain clickable to switch panels. Keep visible but
  unavailable controls in the focus chain, except disabled segmented-control
  options and inactive buttons, which focus skips (see `style.md` › Panels ›
  Focus and state).
- **Tray submenus:** Each submenu level requires one live opener.
  `QsMenuEntry.display()` requires a platform menu that kaizen does not
  provide.
- **Reference shells:** Before modifying a feature ported from another shell,
  read its upstream source (`git clone` if missing, `git pull` to update):
  - `~/code/public/github.com/caelestia-dots/shell`
  - `~/code/public/github.com/duxlabs-dev/dux-shell`
  - `~/code/public/github.com/snowarch/iNiR`
  - `~/code/public/github.com/Gakuseei/Ricelin`
  - `~/code/public/github.com/0xbbuddha/dotfiles_nothing_os`
  - `~/code/public/github.com/omacom/omarchy`
  - `https://noctalia.dev/plugins` (plugin registry)
- Clone any other open-source projects you need to inspect into
  `~/code/public/`.

## Required local validation

Run the relevant checks **before and after editing**, on the appropriate
platform. These are local development gates (not CI jobs) provided only by the
repository's default devshell (`flake.nix`)—entered via `direnv` at the repo
root, or run as `nix develop ~/.dotfiles -c <command>` (not `#dev`) from
anywhere in the checkout.

`compositor-test` and `shell-smoke` are Linux-only and omitted on macOS. All
static checks run against the shared `kaizen/stow/` tree and therefore cover
every kaizen host; `compositor-test` also validates each host's niri
`config.kdl` and umbriel `config.toml` together with their includes.

| Change | Checks |
| --- | --- |
| Nix | `nix fmt`, `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` for **both** kaizen hosts (shared modules affect both; the build fails if any `requires` `cmd`, `file`, or `data` item is not installed) |
| JS/QML | `qml-format`, `qml-test`, `qml-lint`, `requires-check` (any platform) |
| `kaizen` CLI (Go) | `go test ./...` and `go vet ./...` in `kaizen/cli/`, plus build both kaizen hosts (Nix builds run the tests) |
| Compositor interface, configs (`kaizen.kdl`, `kaizen.toml`, or host configs), or bind contract | Also `compositor-test` (Linux) and `qml-test` |
| Service IPC, `shell.qml` wiring, or systemd units | Also `shell-smoke` on the host after deploy and restart, and exercise the affected path |
| Panel views | Also `shell-smoke --panels` |
| Device-dependent behavior | Also validate on the physical ThinkPad |
| Timers, `Process`/`FileView`, services, panels, or `shell.qml` wiring | Ask the user whether to run `shell-perf` after deploy (see [Performance](#performance)) |

- **Workflow and baselines:** Confirm the target checkout, flake pin, and
  active session first, and record baseline failures. When working from another
  host, validate an isolated Linux copy before deploying to the live tree, then
  re-check the deployed shell. On the host itself, `~/.dotfiles` *is* the live
  stowed tree, so edit in place and re-run checks after saving—or use a
  worktree for disruptive changes (see
  [Working from a worktree](#working-from-a-worktree)).
- **Platform honesty:** macOS checks are supplementary. Always report
  unavailable session or hardware coverage as **pending**—never claim full
  validation from another platform.
- **`shell-smoke`:** Targets the running systemd service by PID and works over
  SSH. It checks live service IPC, runtime errors, and QML warnings
  (`WARN scene:`, `WARN qml:`). `--panels` also opens, queries, and closes the
  Display panel (dismissing any competing panel, refusing while locked, and
  leaving scaling/device settings untouched). Because it scans journal logs
  since the last service start, restart the service before re-running to clear
  stale errors.
- **`kaizen doctor`:** Reports current-run warnings/errors from all `kaizen-*`
  units and validates units, the running shell binary, compositor configs, the
  portal, `gsr-kms-server` capabilities, plugin directories/manifests, and
  `requires` files. `--json` outputs structured findings with stable check
  `id`s and `hint` fixes. Passing `journalctl` arguments (`--since -1h`,
  `-b -1`) scans that journal window instead of running live checks. Stream
  live logs with `journalctl --user -u 'kaizen-*' -f`. (Quickshell logs every
  line at syslog priority 6 with the severity in the message text, which is why
  `journalctl -p warning` misses it.) The bar shows a doctor indicator whenever
  any finding exists.
- **Beyond smoke tests:** Smoke checks do not verify focus handling, object
  lifetimes, authentication, daemon recovery, or physical input—exercise
  affected paths directly. Agree on a recovery plan with the user before
  testing lock/PAM, suspend, DPMS-off, or network changes.
- **Hardware-dependent paths:** Validate Wi-Fi/Bluetooth, battery, backlight,
  lid events, touchpad, fingerprint reader, and `GAMMA_LUT` (nightlight) on the
  physical machine.
- **Keyboard testing for layer surfaces (`kaizen keys --layer`):** Open the
  panel with `kaizen ipc call`, find its namespace with `niri msg layers` (or
  `umbriel layers`), and send keys with
  `kaizen keys --layer NAMESPACE KEY...`. It sends keys only while that layer
  alone holds keyboard focus (`exclusive` on niri; `focused` on umbriel, where
  a primed panel drops to on-demand), temporarily lifts the curtain, and
  refuses while locked. Keys use XKB names (`Return`, `ctrl+k`, `shift+Tab`—note
  `shift+Tab` arrives as `Tab` with `Shift`, not `Backtab`). Put any key that
  dismisses or shifts focus (like `Esc`) last. niri drops virtual-keyboard
  input before compositor binds, so `kaizen keys` cannot test compositor binds.
- **Keyboard testing for windows (`kaizen keys --window`):** Run
  `kaizen keys --window ID KEY...` to focus a window (such as a plugin app),
  send keys only while that window is focused and no layer holds the keyboard,
  and restore focus to the previous window afterward. Run each test round as a
  single command that opens a fresh window, sends keys, and closes it—never
  reuse an existing window across commands, since it remembers its last focused
  item (such as a draft input field).
- **Safe key automation:** `Enter` and `Space` activate whatever has focus, and
  destructive or paid actions (like Discard or Re-run in the incident
  investigator) are often just a few `Tab`s away. Only send `Enter`/`Space` to
  a control confirmed focused by a screenshot in the same command, and never
  after a `Tab` sequence whose starting point depends on an earlier step.
  Structure rounds as one command per line under `set -e`—avoid `a && b` chains
  because a failing `&&` list does not trigger `set -e` and subsequent lines
  still execute. Clear any filters set during the test before finishing.
- **Pointer testing (`wlrctl`):** Use the devshell's
  `wlrctl pointer move DX DY` and `wlrctl pointer click [left|right]`. Moves
  are relative and niri does not report cursor coordinates, so verify cursor
  position with a screenshot before clicking. Never move the pointer into the
  top-left corner (that opens niri's overview). `wlrctl` cannot hold a button,
  so drag interactions must be tested by the user; double-clicking selects a
  word.
- **Screenshots (`kaizen shot`):** Use `kaizen shot` to inspect visuals (and
  `kaizen ipc` / `shell-smoke` for internal state). It prints the captured
  output name and file path (under `~/.cache/kaizen-shell/shots/` unless `-o`
  is given). Pass an output name explicitly, or omit it to auto-select the sole
  output or the output holding an open panel, menu, or launcher (it never
  defaults to the focused output because that follows the user, and exits 2 if
  multiple candidates exist). `--bar` captures the bar; `WxH+X+Y` captures a
  region relative to the output. By default the longest edge scales to 1600 px
  so 4K outputs read like laptop panels; pass `--full` for native pixels (for
  example, when inspecting a region). `kaizen shot` lifts and restores the
  curtain and refuses while locked. (Under the hood, `grim` crops in layout
  coordinates with `-g "0,0 1280x32"` or captures an output with `-o`—never
  both—and capture cost scales only with area. Because niri does not report
  layer geometry, bar height comes from `kaizen ipc call shell barHeight` and
  width from `niri msg --json outputs`.)
- **Recording for verification:** Run
  `kaizen ipc call recording capture WxH+X+Y` (`0x0+X+Y` for the full monitor)
  to record with no countdown, audio, or camera (the bar still shows the
  recording indicator). It returns the output path; call
  `kaizen ipc call recording stop` to finalize it, and extract frames with
  `nix shell nixpkgs#ffmpeg`.
- **DPMS-off hazard:** Turned-off monitors can look like a frozen machine, and
  `grim` can hang when no output is producing frames. Always use bounded
  commands; recover with `niri msg action power-on-monitors`.
- **Reporting:** Summarize the host/session, before/after results, pre-existing
  diagnostics, and any omitted checks. Always ask the user to run Nix
  rebuilds—never run them yourself.

### Tests

- `tst_*.qml` files import production JS directly into QtTest. Keep meaningful
  pure parsing, transforms, and state transitions in JS modules, and inline
  trivial single-use bindings. Because there is no separate JS runtime here, do
  not add a Deno/Node/Bun test suite or CommonJS export guards.
- QtTest can test Qt-only QML components only if all transitive imports are
  Qt-only. Quickshell's native C++ types are compiled into the `quickshell`
  binary and cannot be loaded from installed metadata (for example,
  `Ui/BarButton.qml` pulls in the Quickshell-dependent `Compositor` singleton
  from its module). Do not mock Quickshell to cross this boundary.
- `compare()` checks strings, booleans, and `null` strictly, compares
  objects/arrays deeply, and allows small floating-point tolerances. Use
  `compare()` for everything except numbers (for better failure messages),
  `verify(actual === expected)` for exact numbers or object identity, and
  `fuzzyCompare()` for explicit tolerances. Never compare objects via JSON
  serialization.
- `compositor-test` validates niri KDL and umbriel TOML syntax (not action
  dispatch). `qml-test` verifies that `niri/kaizen.kdl` and
  `umbriel/kaizen.toml` expose identical titled keybinds via each backend's
  `readBinds`.

### Tooling

- `qml-lint` fails on any warning (see [`issues.md`](issues.md) for warnings
  caused by upstream bugs). Add an inline `// qmllint disable <category>` only
  when shadowing a public-API `Item` member (`palette`, IPC-visible `enabled`)
  or accessing properties on an untyped `Loader.item`; fix all other warnings.
- Always use the devshell's pinned Qt tools rather than a standalone `qmlls`.
  Launch Neovim from the repo root so it inherits `PATH` and `QML_IMPORT_PATH`.
  The flake provides both Qt imports and Quickshell metadata, so the deployed
  Qt version must match the flake pin after updates. `qml-test` clears the GTK
  platform theme so offscreen SSH runs succeed.
- Register every new QML type under `Ui/` in `Ui/qmldir` so tooling finds it.
  Editor and CLI share `.qmllint.ini`.

### Performance

`shell-perf` (run from the devshell on the host) restarts the unlocked shell,
benchmarks it, appends a row to `nix/hosts/<host>/shell-perf.tsv`, and compares
it against the previous row for the same Quickshell build and monitor setup.
Commit the new row alongside the change it measures.

- Ask the user before running `shell-perf`: it restarts the shell and requires
  leaving the machine untouched for roughly 10 minutes.
- Preconditions: the script refuses to run on battery, outside the `balanced`
  power profile, while locked, with the curtain up, or with a 1-minute load of
  1.5 or higher. Because restarting the shell reapplies the saved AC power
  profile, it rechecks power state after warm-up and before recording the row.
  Discard any row where it warns the system was over 10% busy.
- Measure on `eDP-1` only: lid open, no external monitors, plugged into a plain
  USB-C charger (unplugging a power-delivery monitor drops AC).
- Rows are only comparable within the same `quickshell` build (including Qt)
  and `outputs`. After a flake update or monitor change, run `shell-perf` on
  the previous commit first to establish a new baseline.
- Run-to-run variance is uncalibrated; short runs have varied by ~5 MB PSS and
  ~15 MB peak, so repeat a run before trusting a delta in that range.
- For suspected memory leaks, run `shell-perf --soak HOURS [PANEL]` to sample
  PSS every minute (optionally holding `PANEL` open) and report growth in MB/h.
  A few hours separates real leaks from warm-up.
- To profile QML binding costs, restart manually with `qs --debug PORT` and
  attach the devshell's `qmlprofiler --attach localhost:PORT`. Because that
  instance runs outside `kaizen-shell.service`, `kaizen ipc` and binds will not
  reach it—use `qs ipc -c kaizen` instead.

## Working from a worktree

Static checks (`qml-*`, `requires-check`, `compositor-test`) and Nix builds run
directly inside a worktree. To run that worktree's QML live:

```sh
kaizen dev .      # from the worktree root (or: kaizen dev NAME)
kaizen dev        # print the shell tree kaizen-shell currently runs
kaizen dev off    # return to main's tree
```

- `kaizen dev PATH` writes a systemd drop-in under `$XDG_RUNTIME_DIR` and
  restarts `kaizen-shell.service` against the worktree's shell tree (printing
  startup warnings and errors to stderr, like `kaizen reload --restart`).
  Quickshell then hot-reloads edits from that tree, and `kaizen ipc`,
  compositor binds, and `shell-smoke` all talk to it. `kaizen dev` fails if the
  unit does not end up running that tree. While active, `kaizen doctor` warns
  and validates the worktree's `requires` and plugins. Rebooting resets to
  main's tree.
- Agents may run `kaizen dev` without asking; it refuses while locked.
- Only shell QML (including generic plugins) comes from the worktree. Scripts,
  systemd units, compositor configs, host plugins, and the investigator's
  `-dir` remain on main, so changes to those still go through main. To run a
  worktree's scripts, invoke its own `./kaizen/cli/kaizen` binary (see
  [Building kaizen](#building-kaizen)).
- Only one worktree can be live at a time. Run `kaizen dev off` before removing
  a worktree or ending a task. If a live worktree is deleted or contains broken
  QML, the unit fails—`kaizen dev off` recovers both cases.

## Building kaizen

`kaizen` is a Go binary built from [`kaizen/cli/`](../cli/). A Nix rebuild
installs it into the system profile and runs its Go tests (failing tests block
the rebuild). Go is provided by the default devshell. To test CLI changes
without rebuilding:

- **In a worktree:** Run `go build -o kaizen .` inside `kaizen/cli/` and invoke
  it by path (`./kaizen/cli/kaizen --json`). It dispatches to the worktree's
  own scripts, and scripts calling `kaizen` reuse that same binary. Never
  install a worktree build globally—units, binds, and QML should keep using
  main's `kaizen`.
- **In `~/.dotfiles`:** Run
  `nix develop ~/.dotfiles -c ~/.dotfiles/kaizen/cli/build.sh` to install
  `~/.local/bin/kaizen`. That path takes precedence over the system profile
  only in interactive shells (`exports.sh`); systemd units, binds, and QML
  inherit the user manager's `PATH` (which omits `~/.local/bin`) and keep using
  the system binary until a rebuild. `build.sh` refuses to run outside
  `~/.dotfiles` so parallel sessions do not clobber `~/.local/bin`. The next
  rebuild deletes `~/.local/bin/kaizen`; until then, `kaizen doctor` warns and
  prints its commit (`kaizen --version`).

## Deployment safety

On the host, `~/.dotfiles` is both the Git checkout and the live stowed tree,
so edits take effect on save. Because Quickshell's file watcher can miss
inode-replacing edits (such as `sed -i` or a Git checkout), apply QML edits
with `kaizen reload`, which also prints any QML errors. From another machine,
connect over SSH as `fredrik@<host>`.

Before overwriting live files, inspect local changes and preserve unrelated
edits. Quickshell's watcher can hot-reload mid-copy without checking the lock
state, so record and temporarily disable idle locking beforehand and restore it
afterward. **Never restart Quickshell while locked**: the compositor holds the
session lock even if the lock client dies. `kaizen reload` and `kaizen dev`
both refuse to run while locked.

```sh
kaizen ipc call idle status
kaizen ipc call idle disable
```

After adding or moving stowed files, run `~/.dotfiles/stow.sh` (which also
removes stale symlinks and reloads the systemd user manager). After editing a
unit file, run `systemctl --user daemon-reload` (`kaizen reload --restart` does
this automatically for the shell unit). Never create Stow symlinks manually or
run `git clean -fd` in the host checkout.

When developing from another machine, sync the checkout before running live
validation or asking the user to rebuild (which evaluates the host's clone).
Use checksums (`-c`) so identical compositor configs are not touched just for
differing timestamps. Check `git status` on the host before syncing with
`--delete`, as the host may have uncommitted theme edits in `kaizen/stow/`:

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@<host>:~/.dotfiles/
ssh fredrik@<host> 'cd ~/.dotfiles && git add -AN .'
```

Because `rsync`, Git checkouts, and `sed -i` can replace inodes, restart the
shell explicitly after syncing instead of relying on hot-reload:

```sh
kaizen reload --restart
```

This reloads the user manager, restarts `kaizen-shell.service`, waits for the
shell to load and answer IPC, and prints any warnings or errors—while refusing
to run if locked.

When running compositor commands over SSH, export the active session's
`XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `NIRI_SOCKET` (or `UMBRIEL_SOCKET` on
umbriel) from `systemctl --user show-environment`; `kaizen` subcommands detect
the compositor from its socket variable and refuse to run without it.
`kaizen ipc` and `shell-smoke` target the shell by unit PID and require no
display environment.
