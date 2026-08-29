# wily-vm

Throwaway NixOS VM used to build up a Hyprland + Quickshell desktop before it
lands on the real machine (ThinkPad T14 G6, Core Ultra 7 258V / Lunar Lake,
x86_64). Keep the config portable — nothing VM-specific outside the notes
below.

This file is worked on as the setup grows — update it in the same commit as
the change it describes. Worth writing down: a fact that cost time to
establish (an API shape, a hardware limit, why a mechanism was chosen over the
obvious one), and anything that will bite the next person the same way. Not
worth writing down: what the code already says.

**Delete entries as they stop being true.** A stale line here is worse than a
missing one, because it gets believed and acted on.

## Reaching it

- `ssh fredrik@192.168.64.15` (key auth; password auth also on)
- Rebuild: `sudo nixos-rebuild switch --flake ~/.dotfiles#wily-vm`. Running
  this on **wily-vm only** is pre-authorized; every other host stays
  ask-first.
- `~/.dotfiles` on the VM is a clone of the GitHub repo; see the next section
  for pushing uncommitted work to it.

## Driving it over SSH

Three things get used constantly. `HYPRLAND_INSTANCE_SIGNATURE` must be the
**newest** directory — stale ones accumulate under `/run/user/1000/hypr/`.

```sh
# push uncommitted work from the laptop (--delete matters: without it, files
# deleted locally linger on the VM and keep getting stowed). The git add -AN is
# not optional: flakes ignore untracked files, and a new file that is not at
# least intent-to-added fails evaluation with "Path ... is not tracked by Git".
rsync -a --delete --exclude .git --exclude result ~/.dotfiles/ fredrik@192.168.64.15:~/.dotfiles/
ssh fredrik@192.168.64.15 'cd ~/.dotfiles && git add -AN .'   # flakes ignore untracked files

# run something inside the live session (hyprctl, grim, an app)
ssh fredrik@192.168.64.15 "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
  HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t /run/user/1000/hypr | head -1); <cmd>"

# screenshot, then pull it back and look at it
… 'grim /tmp/shot.png'; scp fredrik@192.168.64.15:/tmp/shot.png .
```

Looking at the screenshot is not optional — the on-screen error overlays
(Hyprland's config errors, Ghostty's dialog) never reach any log this side of
the SSH connection.

Do **not** `git clean -fd` in the VM clone: it deletes the rsync'd
`hyprland.lua`, Hyprland auto-reloads, and the session drops into emergency
mode. `rm` the specific files instead.

## Split of responsibilities

- **Nix** (`desktop.nix`) declares packages and the session: `programs.hyprland`
  with `withUWSM`, greetd autologin, and Quickshell as a systemd **user**
  service bound to `graphical-session.target`. greetd refuses to start unless
  `default_session` is set, even when only `initial_session` is wanted.
  `environment.PATH = lib.mkForce null` on that unit is what makes the launcher
  able to start anything: NixOS otherwise pins a sparse PATH on user units, and
  unsetting it is the only way to inherit the session PATH uwsm imports into
  the user manager. Both hops need it — finding `uwsm-app`, and then the bare
  command name in each app's `Exec`. Nothing reports the failure:
  `Quickshell.execDetached` is silent, and `systemd-run` inherits the same
  broken PATH, so a launch just does nothing.
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

## Reaching Quickshell from a keybind

`qs ipc call launcher toggle` — the launcher's `IpcHandler { target = "launcher" }`
in `shell.qml`. No config selection is needed: `~/.config/quickshell/shell.qml`
registers as the `default` config and `qs ipc` picks the instance on the
current display. Every future panel reuses this; the bar button instead calls
`launcher.toggle()` directly, being the same process.

Apps start with `uwsm-app -- <id>.desktop`, which puts each app in its own
scope under `app-graphical.slice`. Launching them as children of the shell
would kill them all on `systemctl --user restart quickshell`.

`DesktopEntries.applications` fills in a few seconds **after** the shell
starts, so the app list must be a QML binding. Building it once when the
launcher opens gives an empty list on the first open after a restart.

## Light and dark

One key drives everything: `/org/gnome/desktop/interface/color-scheme` in
dconf. `xdg-desktop-portal-gtk` republishes it as the portal's
`org.freedesktop.appearance color-scheme`, Ghostty switches between the
`zenbones_dark`/`zenbones_light` themes named in its config, and Neovim follows
the terminal over OSC 11 (`OSC11.nvim`). Verified live — no restart of either.
The same mechanism macOS drives from its system appearance, which is why the
Ghostty and Neovim configs need nothing platform-specific.

The bar's  /  button writes that key plus `gtk-theme`
(`Adwaita`/`Adwaita-dark`, what Omarchy's `omarchy-theme-set-gnome` does) and
also answers `qs ipc call theme toggle|dark|light`. It *watches* the key with a
long-running `dconf watch` rather than trusting its own writes, so a
`dconf write` from anywhere else moves the bar too. dconf persists, so the mode
survives a reboot for free.

Bar and launcher colours are the zenbones palettes, lifted from
`stow/shared/.config/ghostty/themes/zenbones_{dark,light}` so the bar and the
terminal are literally the same colours. `gsettings` is not installed; `dconf`
is, and writes the same database.

`\uf185` renders as a cog in JetBrains Mono Nerd Font, not a sun; `\uf522` is
the one that reads as a sun at 14px.

## Next steps

The plumbing is in place — portals (`xdg-desktop-portal` + `-hyprland` +
`-gtk`), pipewire/wireplumber and NetworkManager are all running. What is
missing is the shell itself, which is exactly what Quattro moved into
Quickshell.

1. **Wallpaper.** The desktop is black.
2. **Keybinding cheatsheet.** Nearly free now that IPC exists — read
   `hyprctl binds -j`, which already carries the `description` fields set in
   `hyprland.lua`.
3. Notifications, then lock/idle, then a polkit agent.

The launcher is apps-only with hardcoded colours. Quattro's menu tree (power,
screenshots, settings, themes) and a theme system are both still open;
Quattro binds the apps-only view to `SUPER + ALT + SPACE`, so keep that free
for when a root menu takes over `SUPER + SPACE`.

## Known, not yet done

- Keyboard layout is `us`. Swedish is wanted eventually as a second layout,
  but not yet — `kb_layout = "us,se"` with a `grp:` toggle in `kb_options`
  when the time comes.
- No wallpaper, notifications, lock, OSD or polkit agent yet — no polkit agent
  is running at all, so any privileged GUI action will fail.
- The bar uses JetBrains Mono Nerd Font (`nix/shared/system/linux.nix` installs
  several nerd fonts). Berkeley Mono is wanted as the system font eventually,
  but it is a paid font and needs vendoring before Nix can install it.
- Only one emoji font is installed; `noto-fonts-color-emoji` is commented out
  in `nix/shared/system/linux.nix` as slow to build. Quickshell UI will want it.
- Mason installs prebuilt glibc binaries, which cannot run on NixOS. Neovim
  itself works on the VM (all 74 vim.pack plugins installed cleanly), but the
  Mason-managed language servers are expected to be broken. Untested.
- Root filesystem is at 63%; consider `nix.gc` before it matters.
