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
  `rsync -a --exclude .git --exclude result ~/.dotfiles/ fredrik@192.168.64.15:~/.dotfiles/`
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
  plus greetd autologin. greetd runs `start-hyprland`, not `Hyprland` — the
  bare binary boots but prints a "started without start-hyprland" warning.
  greetd also refuses to start unless `default_session` is set, even when only
  `initial_session` is wanted.
- **stow** (`stow/Linux/.config/{hypr,quickshell}/`) carries the config and
  QML. Deliberate: the Quickshell tree gets edited constantly and stow
  symlinks take effect with no rebuild. Do not move QML into the Nix store.

## VM graphics facts

virtio-gpu, `+virgl` (GLES works, Hyprland renders), `-context_init` (no
Vulkan — if anything reaches for it, `QSG_RHI_BACKEND=opengl`),
`-resource_blob -host_visible` (no zero-copy dmabuf, so sluggishness and
screencopy/portal oddities are environmental, not config bugs), 1 scanout (no
multi-monitor testing possible here — don't write multi-monitor logic).
`cursor { no_hardware_cursors = true }` in `hyprland.conf` is for this.

## Reference

Omarchy 4 "Quattro" is the model, cloned at
`~/code/public/github.com/omacom/omarchy` (branch `quattro`). Its Quickshell
tree is `shell/` (~95 QML files: `shell.qml`, `Ui/`, `services/`, `plugins/`),
Hyprland config in `config/hypr/`, and package list in
`install/omarchy-base.packages`. Approach is vendor-and-prune: port pieces
across on request rather than rewriting from scratch.

## Known, not yet done

- Hyprland warns the `.conf` config format is removed in 0.57. Currently on
  0.56.2. Needs a migration before that bump.
- home-manager's stow activation step did not run on the switch that
  introduced these files; `cd ~/.dotfiles/stow && stow --target="$HOME"
  --restow --no-folding --adopt shared Linux` fixed it. Watch for a repeat.
- Keyboard layout is left at default (us). Unset deliberately — confirm before
  adding `input { kb_layout }`.
- No wallpaper, launcher, notifications, lock, OSD or polkit agent yet.
