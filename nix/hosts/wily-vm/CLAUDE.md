# wily-vm

Throwaway NixOS VM used to build up a Hyprland + Quickshell desktop before it
lands on the real machine (ThinkPad T14 G6, Core Ultra 7 258V / Lunar Lake,
x86_64). Keep the config portable — nothing VM-specific outside the notes
below.

## Reaching it

- `ssh fredrik@192.168.64.15` (key auth; password auth also on)
- Rebuild: `sudo nixos-rebuild switch --flake ~/.dotfiles#wily-vm`. Running
  this on **wily-vm only** is pre-authorized; every other host stays
  ask-first.
- `~/.dotfiles` on the VM is a clone of the GitHub repo. To test uncommitted
  work from a laptop:
  `rsync -a --delete --exclude .git --exclude result ~/.dotfiles/ fredrik@192.168.64.15:~/.dotfiles/`
  (**`--delete`** matters: without it, files deleted locally linger on the VM
  and keep getting stowed)
  then `git add -AN .` on the VM — **flakes ignore untracked files**, so a new
  file that is not at least intent-to-added fails evaluation with "Path ... is
  not tracked by Git".

## Seeing the screen over SSH

`grim` is installed. It needs the live session's env, and stale socket
directories accumulate under `/run/user/1000/hypr/` — always pick the newest:

```sh
ssh fredrik@192.168.64.15 "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
  HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t /run/user/1000/hypr | head -1); grim /tmp/shot.png"
scp fredrik@192.168.64.15:/tmp/shot.png .
```

The same env prefix is what `hyprctl` needs.

## Split of responsibilities

- **Nix** (`desktop.nix`) declares packages and the session: `programs.hyprland`
  with `withUWSM`, greetd autologin, and Quickshell as a systemd **user**
  service bound to `graphical-session.target`. greetd refuses to start unless
  `default_session` is set, even when only `initial_session` is wanted.
- **stow** (`stow/Linux/.config/{hypr,quickshell}/`) carries the config and
  QML. Deliberate: the Quickshell tree gets edited constantly and stow
  symlinks take effect with no rebuild. Do not move QML into the Nix store.

## Hyprland config is Lua, not .conf

hyprlang (`hyprland.conf`) is deprecated since 0.55 and removed in 0.57. The
config is `~/.config/hypr/hyprland.lua`; Omarchy Quattro is Lua-only too, so
snippets port straight across. The `hl` API, dumped live from 0.56.2:

- `hl.config{ general=…, decoration=…, input=…, misc=…, … }`
- `hl.monitor{ output="", mode="preferred", position="auto", scale=1 }`
- `hl.bind(keys, dispatcher, { description = … })`, `hl.unbind`
- `hl.dsp.*`: `exec_cmd exec_raw exit focus group layout workspace window
  cursor dpms submap send_key_state send_shortcut global pass no_op event
  force_idle force_renderer_reload release_input_capture`
- `hl.dsp.window.*`: `close move float fullscreen fullscreen_state resize
  center pin tag swap kill drag pseudo bring_to_top alter_zorder cycle_next
  set_prop signal toggle_swallow clear_tags deny_from_group`
- also `hl.exec_cmd hl.dispatch hl.on hl.timer hl.env hl.gesture
  hl.window_rule hl.layer_rule hl.workspace_rule hl.notification hl.get_*`

Gotchas found the hard way:

- **Switching workspace is `hl.dsp.focus{ workspace = "1" }`.**
  `hl.dsp.workspace` is a *table* (`.move`, `.toggle_special`), so calling it
  raises "attempt to call a table value".
- **A Lua error aborts the rest of the file silently.** Everything below the
  failing line simply never registers, which looks exactly like "that API does
  nothing". Check `hyprctl binds` and the on-screen error overlay before
  concluding a function is broken.
- **`hyprctl dispatch` takes Lua now**: `hyprctl dispatch 'hl.dsp.exec_cmd("ghostty")'`.
- Bind workspace keys as `code:10`..`code:19` so they survive a layout change.
- **Emergency mode** appears as a red banner when no binds register at all
  (bad config, or the file went missing). It provides SUPER+Q → a terminal,
  SUPER+R → hyprland-run, SUPER+M → exit. Recover with `hyprctl reload` once
  the config is valid again.
- Hyprland auto-reloads on config change, so anything that momentarily removes
  `hyprland.lua` — `git clean -fd` on the VM clone, for instance — trips
  emergency mode even if the file reappears a second later.

## uwsm: never restart greetd, reboot

`systemctl restart greetd` races the old session's user-unit teardown; the new
uwsm start then dies with *"A compositor or graphical-session* target is
already active"* and you get a black screen with greetd stopped. Reboot
instead. This is also why Quickshell is a systemd user service — it can be
restarted on its own (`systemctl --user restart quickshell`) while iterating on
QML, without touching the compositor.

## VM graphics facts

virtio-gpu, `+virgl` (GLES works, Hyprland renders), `-context_init` (no
Vulkan — if anything reaches for it, `QSG_RHI_BACKEND=opengl`),
`-resource_blob -host_visible` (no zero-copy dmabuf, so sluggishness and
screencopy/portal oddities are environmental, not config bugs), 1 scanout (no
multi-monitor testing possible here — don't write multi-monitor logic).
`no_hardware_cursors` in `hyprland.lua` is for this.

Concretely, from `eglinfo` on the VM: renderer `virgl (ANGLE (Apple, Apple M1,
OpenGL 4.1 Metal))`, **desktop OpenGL 2.1**, **OpenGL ES 3.0**. Hyprland is
happy because it uses GLES. GTK4 apps are not: Ghostty sets
`GDK_DISABLE=gles-api,vulkan` itself, so it requires desktop GL >= 3.3 and dies
with "Unable to acquire an OpenGL context". `LIBGL_ALWAYS_SOFTWARE=1` gives
llvmpipe at GL 4.6, which is why `desktop.nix` wraps Ghostty in it. No UTM
setting lifts this — the ceiling is the host's ANGLE-over-Metal translation,
and turning acceleration *off* would remove the GLES 3.0 Hyprland depends on.

## Reference

Omarchy 4 "Quattro" is the model, cloned at
`~/code/public/github.com/omacom/omarchy` (branch `quattro`). Its Quickshell
tree is `shell/` (~95 QML files: `shell.qml`, `Ui/`, `services/`, `plugins/`),
Hyprland config in `config/hypr/`, and package list in
`install/omarchy-base.packages`. Approach is vendor-and-prune: port pieces
across on request rather than rewriting from scratch.

## Newly added stow files need a nudge

`nixos-rebuild switch` restarts `home-manager-fredrik.service` — which is what
runs the stow step — only when the home-manager *generation* changes. A change
that touches system config and `stow/` alone leaves the generation identical,
so the unit stays `active (exited)` and nothing gets stowed. Editing an
already-stowed file is unaffected (it is a symlink), but a **new** file under
`stow/` needs one of:

    sudo systemctl restart home-manager-fredrik.service

a reboot, or a manual `stow` run. Not a bug — a fresh machine always has a new
generation, so first-boot bootstrap works.

## Known, not yet done

- Hyprland warns the `.conf` config format is removed in 0.57. Currently on
  0.56.2. Needs a migration before that bump.
- Keyboard layout is `us`. Swedish is wanted eventually as a second layout,
  but not yet — `kb_layout = "us,se"` with a `grp:` toggle in `kb_options`
  when the time comes.
- Ghostty shows a "Configuration Errors" dialog until Neovim has been run on
  the host: the shared config (`stow/shared/.config/ghostty/config`) points
  `theme =` at zenbones files under `~/.local/share/nvim-fredrik/site/...`,
  which the plugin install creates. Run Neovim once; no repo change needed.
- No wallpaper, launcher, notifications, lock, OSD or polkit agent yet.
- Root filesystem is at 63%; consider `nix.gc` before it matters.
