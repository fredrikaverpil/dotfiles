# wily-vm

Throwaway NixOS VM for developing a portable Quickshell desktop before it moves
to the ThinkPad. Keep the configuration portable; host-specific work belongs in
`stow/host/wily-vm/` or this host's Nix files.

The actual Thinkpad hardware this VM is preparing for:

```txt
LENOVO ThinkPad T14 G6 Intel
Core Ultra 7 258V Lunar Lake 14inch
WUXGA AG 500n LP 32GB 1TB
UMA W11P 3YPS
```

Comments and this document should preserve constraints, surprising behaviour,
and rationale that the code cannot express. Do not record routine settings,
commands that can be discovered from the code, investigation history, or
superseded alternatives.

## Architecture

- Hyprland and niri are alternative compositors, started with `hypr` or `niri`
  from the console through UWSM. They never run together.
- `desktop.nix` owns packages, portals, PAM, session units, and the
  pre-suspend lock inhibitor. The shell is a systemd user service.
- `stow/host/wily-vm/` owns both compositor configurations and Quickshell.
  Edits to an existing stowed file take effect immediately; new files need a
  Stow activation.
- `shell.qml` wires services and surfaces. `Ui/Compositor.qml` is the only
  compositor-specific Quickshell layer. Views live under `plugins/panels/`;
  daemon/process state belongs in the matching `plugins/services/` directory.
- The Quickshell layout mirrors Omarchy where useful, so read its source code
  before changing a ported feature. Use
  caelestia and DankMaterialShell for alternate or complementary QML designs.
  - `~/code/public/github.com/omacom/omarchy`
  - `~/code/public/github.com/caelestia-dots/shell`
  - `~/code/public/github.com/AvengeMedia/DankMaterialShell`

## QML and Lua tooling

Run the QML tools from the repository devshell (normally entered by direnv):

```sh
qml-lint
qml-test-js
qml-test-qml
hypr-test
niri-validate  # Linux only
```

Run the relevant checks before copying a shell change to the VM; they are
manual gates, not CI jobs. `qml-test-js` covers every extracted pure JS model
and must run for any shell logic change. Run `qml-lint` after every QML edit,
`qml-test-qml` after changing a Qt-only component or its bindings, and
`hypr-test` after changing `hyprland.lua`, `monitors.lua`, or the bind TSV
contract. On Linux, run `niri-validate` after every `config.kdl` edit. Changes
to `Ui/Compositor.qml` or a shared compositor feature require `qml-test-js`,
`hypr-test`, and validation of the affected live compositor path.

`stow/host/wily-vm/.config/quickshell/README.md` owns the tooling details.
`qmlls` needs the devshell's `PATH` and `QML_IMPORT_PATH`, so launch Neovim
from the repository. `Ui/qmldir` is tooling-only but must list every `Ui` QML type.

LuaLS can exhaust the VM when rooted at the repository. The stowed
`hypr/.luarc.json` makes the Hypr config a small workspace and supplies the
Hyprland stubs; do not remove it. Hyprland watches only `hyprland.lua`, so
changes to `monitors.lua` need `hyprctl reload`.

## Deploying to the VM

The VM has a DHCP address. Get it from the Mac each session:

```sh
VM=$(awk -F= '/name=wily-vm/{f=1} f&&/ip_address/{print $2; exit}' /var/db/dhcpd_leases)
```

**Before a rebuild or live-VM validation, copy this checkout to the VM and
intent-to-add new files.** A rebuild evaluates the VM clone, not the local
checkout.

```sh
rsync -a --delete --exclude .git --exclude result ~/.dotfiles/ fredrik@"$VM":~/.dotfiles/
ssh fredrik@"$VM" 'cd ~/.dotfiles && git add -AN .'
```

`rsync`, `git checkout`, and `sed -i` replace files by rename. Quickshell's
watcher stays on the old inode, so restart it after deploying QML and never
rely on hot reload after such a write:

```sh
systemctl --user restart quickshell.service
```

Do not restart Quickshell while its native lock is active: the compositor keeps
the session lock after its client dies. Disable idle locking before an extended
QML session and verify that the lock is not active:

```sh
qs ipc call idle disable
qs ipc call lock isLocked
```

A newly added stowed file also needs the normal Stow activation on the VM:

```sh
cd ~/.dotfiles
stow --dir=stow --target="$HOME" --restow --no-folding --adopt shared
stow --dir=stow/platform --target="$HOME" --restow --no-folding --adopt Linux
host="$(hostname -s)"
[ -d "stow/host/$host" ] && stow --dir=stow/host --target="$HOME" --restow --no-folding --adopt "$host"
```

Do not create Stow links manually: Stow owns relative links only. Do not run
`git clean -fd` in the VM clone. Any Git operation which temporarily removes
`hyprland.lua` requires `hyprctl reload` afterwards.

Nix rebuilds and privileged recovery are for the user to run:

```sh
sudo nixos-rebuild switch --flake ~/.dotfiles#wily-vm
```

For commands inside a Hyprland session, provide its runtime environment:

```sh
ssh fredrik@"$VM" "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
  HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t /run/user/1000/hypr | head -1); <cmd>"
```

`qs ipc` also needs `WAYLAND_DISPLAY`; without it, it can report dead instances
as though the shell crashed. Prefer state checks such as `qs list`,
`systemctl --user is-active quickshell.service`, `hyprctl -j clients`, and
`hyprctl configerrors` to screenshots.

## Session constraints

- `wayland-session-waitenv.service` is required before Quickshell and the sleep
  lock unit. niri announces readiness before it publishes `WAYLAND_DISPLAY` to
  the user manager; ordering only after its compositor unit races that export.
- Do not order either user service after `graphical-session.target`: it creates
  a systemd cycle. They are instead bound to their compositor-specific session
  targets, preventing a second desktop from starting another shell.
- NixOS gives user units a sparse `PATH`. Quickshell deliberately unsets it to
  inherit the UWSM session path; otherwise launcher entries and `uwsm-app` fail
  silently.
- `Ui/Panel.qml` uses a full-screen input surface with a top-bar cutout so a
  bar button can switch open panels. Keyboard panels use Qt's focus chain;
  keep buttons in that chain while they are visible even when temporarily
  unavailable, or focus can be stranded.
- The tray draws app menus itself. `QsMenuEntry.display()` requires a platform
  menu unavailable to this shell, and submenu entries require one live opener
  per level.
- The shell owns keyboard-layout state. Do not add a compositor-side XKB group
  toggle: it would desynchronise the bar label.

## Compositor differences

`Ui/Compositor.qml` contains the command tables. Test both paths when changing
an abstraction.

- niri has no Quickshell module. Workspace sources are selected by URL because
  importing `Quickshell.Hyprland` attempts a socket connection. niri event IDs
  are global and non-contiguous; UI actions and labels use each output's `idx`.
- niri needs `NIRI_SOCKET` in the systemd user manager; without it the shell
  follows the Hyprland command path.
- Hyprland's Lua option names use underscores even where `hyprctl` prints a
  hyphenated path. Use the LuaLS stub, not the `hyprctl` spelling.
- niri KDL booleans are presence-only (`natural-scroll`, not
  `natural-scroll true`). Validate its config after edits.
- Hyprland and niri use different nightlight daemons. Keep scheduling above
  the compositor backend.

## VM limitations

- UTM supplies one virtio output and no Wi-Fi, Bluetooth, battery, backlight,
  lid, touchpad, or hardware cursor plane. Do not infer laptop behaviour from
  those features in the VM.
- UTM pauses guest time while the Mac sleeps; chrony is intentional. Its virgl
  desktop OpenGL is too old for Ghostty, so only Ghostty is wrapped with
  software GL.
- A DPMS-off Hyprland output resembles a frozen VM. `hyprctl -j monitors` still
  reports state; recover with `hyprctl dispatch 'hl.dsp.dpms("on")'`. Use
  `timeout` around `grim`, which can hang while no output produces frames.
- macOS captures many Command/SUPER chords. A failed physical SUPER bind is a
  host-input question first; inspect the compositor bind list or use IPC.

## Current scope

The VM shell owns the bar, launcher, backgrounds, display/theme controls,
network and audio panels, media, keyboard layout, tray, notifications, lock,
idle, polkit, and nightlight. Hardware-specific work (battery, Bluetooth,
Wi-Fi interaction, brightness, lid/suspend-resume, fingerprint) waits for the
ThinkPad. Do not add a large bespoke panel for an infrequent system task when a
purpose-built application is adequate.
