# Renoir desktop (ThinkPad T14 Gen 1)

`renoir` is the personal ThinkPad T14 Gen 1 (AMD Renoir, x86_64) running the
Wily desktop. Machine-specific settings (microcode, VAAPI driver, kernel choice)
belong in `configuration.nix`.

Document constraints, rationale and gotchas, not implementation inventories or
previous states.

## Architecture

- niri is the only session, run under UWSM and started with `niri` from the
  console.
- `desktop.nix` owns packages, portals, PAM, systemd units, and the pre-suspend
  lock inhibitor. `stow/host/renoir/` owns compositor configuration and QML.
- `shell.qml` wires services and surfaces. Views belong in `plugins/panels/`;
  daemon/process state belongs in `plugins/services/`.
- Nightlight is not compositor-specific: wl-gammarelay-rs drives
  `zwlr_gamma_control_v1`, so its commands live in the nightlight service, not
  `Ui/Compositor.qml`.
- `Ui/Compositor.qml` is the compositor interface; `Ui/compositors/` owns niri
  commands, response parsing, and the workspace source. Views use that
  interface. Keep scheduling and shared state above it.
- Prefer purpose-built applications to large bespoke panels for infrequent
  tasks.
- Niri event IDs are global; UI labels/actions use output-local workspace `idx`.
- Niri KDL booleans are presence-only, not `option true`.
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
from the shell on macOS. Static checks run against every host's tree;
`shell-smoke` uses the tree of the host it runs on (`hostname -s`).

| Change | Checks |
| --- | --- |
| JS/QML | `qml-test`, `qml-lint` (any platform) |
| Compositor interface, config, or bind contract | Also `compositor-test` (Linux) |
| Service IPC, `shell.qml` wiring, or systemd units | Also `shell-smoke` on the machine after deploy and restart, and exercise the affected path |
| Panel views | Also `shell-smoke --panels` |
| Device-dependent behaviour | Also validate on the actual ThinkPad |

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
- Test keyboard-first panels over SSH: open the panel with `qs ipc call`,
  confirm it is the only `Keyboard interactivity: exclusive` layer in
  `niri msg layers`, then use `wtype -k z`. Niri drops virtual-keyboard input
  before bind handling, so `wtype` cannot test compositor binds.
- Use `grim` to check how the shell looks. To check its internal state, use
  `qs ipc` and `shell-smoke` instead. Crop screenshots to the area you need
  with `-g`, for example `-g "0,0 1280x32"`, and use `-o` to select the output.
  Capture cost depends on the area captured; changing the image format,
  quality (`-q`), or scale (`-s`) does not reduce it. Niri does not report
  layer positions and sizes, so work out the bar's position and size from `niri msg --json outputs` and the `barHeight`
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
- `compositor-test` checks the real theme-edit anchor and niri's KDL. It does
  not test dispatch.

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

## Deployment safety

On renoir, `~/.dotfiles` is this checkout and the live stowed tree: edits
deploy as they are saved. From another host, it is reached over SSH as
`fredrik@renoir`.

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
never create Stow links manually or run `git clean -fd` in the ThinkPad clone.

When working from another host, sync the checkout before live validation or a
user-run rebuild, which evaluates the ThinkPad clone. Checksums avoid replacing
identical compositor files solely because timestamps differ.

```sh
rsync -ac --delete --exclude .git --exclude result --exclude .direnv ~/.dotfiles/ fredrik@renoir:~/.dotfiles/
ssh fredrik@renoir 'cd ~/.dotfiles && git add -AN .'
```

`rsync`, Git checkouts, and `sed -i` can replace inodes, so restart the
unlocked shell after deployment rather than relying on its watcher:

```sh
systemctl --user restart quickshell.service
```

For ordinary `qs ipc` and compositor commands over SSH, provide the active
session's `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `NIRI_SOCKET` from `systemctl --user show-environment`. Missing display context can make live
Quickshell instances appear dead. `shell-smoke` avoids that by selecting the
PID.

## Firmware

BIOS and device firmware come from LVFS through fwupd (`services.fwupd`).
Updates reboot the machine, so the user runs them.

```sh
fwupdmgr refresh --force               # stale metadata reports "no updates"
fwupdmgr get-updates                   # lists each device's "Device ID"
cat /sys/class/power_supply/AC/online   # must print 1
fwupdmgr update <device-id>
```

- Refresh first; without it `get-updates` can falsely report nothing pending.
- The BIOS update needs AC power and reboots into a UEFI capsule flash. It
  is staged on the ESP (`/boot`); keep room there.
- Secure Boot is disabled, so the KEK CA, UEFI CA and dbx updates are
  unnecessary. Update only the device you need, by ID.
- After the reboot, confirm `/sys/class/dmi/id/bios_version` and recheck
  `journalctl -b -k -p warning`.
- A BIOS update can reset EFI settings; recheck Config → Power → Sleep State.
  "Linux" enables S3 (`deep` in `/sys/power/mem_sleep`).
- The BIOS has no CPPC option, so `amd_pstate` stays disabled and cpufreq
  uses `acpi-cpufreq`.

## Fingerprint reader

The Synaptics reader (`06cb:00bd`) is not enabled; it is unused by choice.
To enable it:

```nix
# fprintAuth defaults to on for every PAM service. login (and wily-lock,
# which includes it) and sudo stay password-only until tested on hardware.
services.fprintd.enable = true;
security.pam.services.login.fprintAuth = false;
security.pam.services.sudo.fprintAuth = false;
```

Then rebuild, and run `fprintd-enroll` and `fprintd-verify`.

- Check the generated PAM with
  `nix eval --raw .#nixosConfigurations.renoir.config.security.pam.services.<name>.text`;
  `environment.etc."pam.d/<name>".text` is null because it uses `source`.
- The lock screen starts PAM only after a password is submitted, so
  fprintd in its stack would block typing until the finger prompt times
  out. It needs a separate, concurrent fingerprint `PamContext`. Test
  it with a recovery plan before enabling it for `login`.
- fwupd cannot read the reader's firmware version: it answers with an
  unmapped status `0x315`. libfprint talks to it independently; untested.

## Screen recording

- `gpu-screen-recorder` captures monitors over KMS through the setcap
  `gsr-kms-server` wrapper (`programs.gpu-screen-recorder`), with no dialog.
  Cameras are composited in-process (`monitor:DP-1|v4l2:/dev/video2;...`), and
  SIGUSR2 toggles pause within one file. A camera held by a recording is
  unavailable to other applications.
- The countdown overlay unmaps before capture starts; the bar indicator is
  recorded. An `IdleInhibitor` on each bar window keeps idle locking from
  interrupting a recording. `xdg-open` runs mpv in the foreground, and mpv
  quits at the end of the clip.
- Region capture (`-w region -region WxH+X+Y`) takes logical, global
  coordinates — Quickshell's screen geometry — and gsr scales them and rounds
  to even pixels itself. `region|v4l2:...` composites the camera. The selector
  overlay stays mapped, click-through, while recording; its outline sits a few
  pixels outside the region so rounding never captures it.
- Agents record with `qs ipc call recording capture WxH+X+Y` (`0x0+X+Y` is the
  whole monitor there): no countdown, audio, camera or opening, and the bar
  shows it. It returns the file; `qs ipc call recording stop` finalizes it.
  Extract frames with `nix shell nixpkgs#ffmpeg`.
- LosslessCut trims clips by stream copy, so cuts snap to keyframes; it is
  not a default handler, and mpv still opens finished recordings.
- Window recording is deferred; a region covers it. Window capture goes through
  `xdg-desktop-portal-gnome` (routed as niri's
  `org.freedesktop.impl.portal.ScreenCast`, not installed), which needs
  niri's Mutter D-Bus services; niri starts those
  only as `niri --session` (`src/dbus/mod.rs`). `shell/sourcing.sh` starts bare
  `niri` under UWSM, so the portal reports no source types. `--session` would
  also make niri import the environment into systemd (not cleaned up by UWSM),
  take the power key from logind (`disable-power-key-handling` keeps logind),
  and serve `org.freedesktop.ScreenSaver` idle inhibitors. It needs a
  relogin. `debug { dbus-interfaces-in-non-session-instances }`
  enables the D-Bus interfaces without it, minus the portal-dialog service
  channel.

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
- nwg-displays owns output layout, mode and scale in the untracked
  `~/.config/niri/monitor.kdl`; the shell never writes output config. niri
  cannot mirror outputs; `wl-mirror` shows one in a fullscreen window.
- Hardware-dependent paths: Wi-Fi/Bluetooth, battery, backlight, lid,
  touchpad, fingerprint reader, `GAMMA_LUT` (nightlight). Validate those on
  this machine.
- Bluetooth pairing belongs to bluetui, which registers its own BlueZ agent;
  the shell registers none and never scans. The panel only toggles power and
  connects paired devices. It uses `adapter.enabled`, which BlueZ does not
  persist, so `powerOnBoot` turns the radio back on after every boot.
- The mic-mute key mutes every PipeWire source, not only the default: muting
  yourself must survive default changes such as a headset connecting. The LED
  is lit only while all are muted. The kernel's `audio-micmute` trigger
  follows only the built-in ALSA capture switches, so a udev rule clears it
  and the audio panel writes `platform::micmute` via logind. The keyboard backlight is firmware-driven (Fn+Space); leave it alone.
- Charge thresholds are set by a boot unit in `configuration.nix`; the battery
  panel only displays them and never writes sysfs. power-profiles-daemon
  conflicts with TLP; keep TLP disabled.
- Lid close uses logind defaults: suspend (the pre-suspend unit locks first),
  or nothing when docked. Niri turns off `eDP-1` while docked with the lid
  closed.
- DPMS-off can resemble a frozen machine. Use bounded commands; `grim` can hang
  while no output produces frames. Recovery is
  `niri msg action power-on-monitors`.
