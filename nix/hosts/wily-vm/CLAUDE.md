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

These get used constantly. `HYPRLAND_INSTANCE_SIGNATURE` must be the
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

**The shell can be driven end to end without a keyboard**, which is the only
way to test it from a Mac (see the SUPER-binds section below). `qs ipc` opens
a panel and `hl.dsp.send_key_state` types into it — synthetic keys do reach a
layer-shell surface, so navigation, search and Enter are all exercisable:

```sh
qs ipc call menu level system          # or: toggle, close, level learn.keybindings
press() {                              # one key, down then up
  hyprctl dispatch "hl.dsp.send_key_state({ mods = \"\", key = \"$1\", state = \"down\" })"
  sleep 0.15
  hyprctl dispatch "hl.dsp.send_key_state({ mods = \"\", key = \"$1\", state = \"up\" })"
}
for k in s c r a t c h; do press $k; done   # type into the search box
press Return
```

Assert on state rather than on the picture where possible: `hyprctl -j clients`
for window geometry, `dconf read` for the theme, `ls` for a screenshot the menu
was asked to take.

Do **not** `git clean -fd` in the VM clone: it deletes the rsync'd
`hyprland.lua`, Hyprland auto-reloads, and the session drops into emergency
mode. `rm` the specific files instead.

`stow` cannot be re-run on the VM: the existing links are absolute into
`~/.dotfiles`, so it reports *"Ignoring an absolute symlink"* and then
*"existing target is not owned by stow"* and aborts the whole run. Editing an
already-linked file is unaffected — rsync writes through the link — but a
**new** file under `stow/` needs the link made by hand:

```sh
ln -sfn ~/.dotfiles/stow/Linux/.config/hypr/newfile.lua ~/.config/hypr/newfile.lua
```

## Split of responsibilities

- **Nix** (`desktop.nix`) declares packages and the session: `programs.hyprland`
  with `withUWSM`, greetd autologin, and Quickshell as a systemd **user**
  service bound to `graphical-session.target`. greetd refuses to start unless
  `default_session` is set, even when only `initial_session` is wanted.
  `environment.PATH = lib.mkForce null` on that unit is what makes the menu
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
  hl.window_rule hl.layer_rule hl.workspace_rule hl.get_*`
- `hl.notification` is a **table**, not a function:
  `hl.notification.create{ text = …, timeout = … }` and `.get`.
- Nothing in `hl` watches a file. Hyprland auto-reloads `hyprland.lua`
  itself, but a `dofile`/`require`d second file is not a tracked
  dependency — editing it changes nothing until `hyprctl reload`. That is
  why the binds are inline rather than in their own `bindings.lua`.

Gotchas found the hard way:

- **Switching workspace is `hl.dsp.focus{ workspace = "1" }`.**
  `hl.dsp.workspace` is a *table* (`.move`, `.toggle_special`), so calling it
  raises "attempt to call a table value".
- **A Lua error aborts the rest of the file silently.** Everything below the
  failing line simply never registers, which looks exactly like "that API does
  nothing". Check `hyprctl binds` and the on-screen error overlay before
  concluding a function is broken. The bind block runs under `pcall` for
  this reason: without it a single bad bind also skips the recorder at the
  bottom of the file, so a typo blanks the cheatsheet as well as the
  keymap. `pcall` catches a runtime error, not a syntax error.
- **`hyprctl dispatch` takes Lua now**: `hyprctl dispatch 'hl.dsp.exec_cmd("ghostty")'`.
- Bind workspace keys as `code:10`..`code:19` so they survive a layout
  change — but **`hyprctl binds` reports a `code:` bind with an empty
  `key` and `keycode: 0`**, and every Lua bind as `dispatcher: __lua` with
  an opaque registry index for `arg`. So hyprctl can list the binds and
  their descriptions, and can tell you neither the chord nor the action.
  `hyprland.lua` therefore records its own chords to
  `~/.local/state/hypr-binds.tsv` as it registers them, and the cheatsheet
  reads that. A bare `hl.bind()` that skips the local `bind()` helper
  registers fine and is invisible in the cheatsheet. (Omarchy solves the
  same problem by re-evaluating `hyprland.lua` in a fake-`hl` Lua sandbox
  — `omarchy-menu-keybindings`, ~500 lines — because their menu also
  *dispatches* the selected bind, and their users write raw `hl.bind` in
  `~/.config/hypr/bindings/`. Neither applies here.)
- **`hyprctl -j binds` reports `mouse: false` on a working drag bind.**
  `SUPER + mouse:272` with `{ mouse = true }` moves windows correctly; the
  JSON field is not the way to check. Verify by dragging and reading
  `hyprctl -j clients` for a changed `at`/`size`.
- **Emergency mode** appears as a red banner when no binds register at all
  (bad config, or the file went missing). It provides SUPER+Q → a terminal,
  SUPER+R → hyprland-run, SUPER+M → exit. Recover with `hyprctl reload` once
  the config is valid again.
- Hyprland auto-reloads on config change, so anything that momentarily removes
  `hyprland.lua` — `git clean -fd` on the VM clone, for instance — trips
  emergency mode even if the file reappears a second later.

## The keymap is Omarchy's

`hyprland.lua` mirrors Omarchy's `default/hypr/bindings/*.lua` — same chords,
same wording in the descriptions, so their cheatsheet and ours read alike.
Dropped, all for want of a target rather than by preference:

- anything invoking an `omarchy-*` script (close-all, tiled fullscreen, pop
  window out, window width save/restore, workspace layout, monitor scaling,
  transparency and gap toggles)
- every monitor bind — one scanout here
- all of `media.lua` (XF86 volume/brightness/media keys): no such keys on the
  VM, and each one routes through an `omarchy-*` script anyway. Wanted on the
  ThinkPad.

Consequences of following them exactly: `SUPER + W` is a second Close window,
so the wallpaper picker moved to `SUPER + CTRL + SPACE` (their "Background
switcher"), and there is no hjkl focus — Omarchy puts focus on `SUPER +
arrows` and uses `SUPER + J`/`SUPER + L` for split and layout.

## From a Mac, macOS eats the SUPER binds

SUPER is Command on a Mac host, and macOS claims `Cmd + W`, `Cmd + Q`,
`Cmd + Space` and `Cmd + Tab` before the guest sees them — so Close window
kills the UTM window, and `SUPER + SPACE` opens Spotlight. Omarchy's keymap is
overwhelmingly SUPER-based, so a large slice of it is untestable from the Mac
until UTM captures the keyboard. **A chord that appears dead is a host-capture
question before it is a config question** — check `hyprctl -j binds` first, it
is authoritative. None of this exists on the ThinkPad, where SUPER is a real
Super key.

This is also why the bar carries a menu icon at all, rather than leaving
`SUPER + SPACE` as the only way in.

## uwsm: never restart greetd, reboot

`systemctl restart greetd` races the old session's user-unit teardown; the new
uwsm start then dies with *"A compositor or graphical-session* target is
already active"* and you get a black screen with greetd stopped. Reboot
instead. This is also why Quickshell is a systemd user service — it can be
restarted on its own (`systemctl --user restart quickshell`) while iterating on
QML, without touching the compositor.

## What a rebuild does and does not restart

`nixos-rebuild switch` leaves the running session alone, which is mostly what
you want and occasionally the trap:

- **`hyprland.lua`** — nothing to do. It is stowed and Hyprland auto-reloads it.
- **The Quickshell unit** — user units are *reloaded*, not restarted: a switch
  writes the new `quickshell.service` but the running process keeps the old
  environment. Changing `QT_PLUGIN_PATH` or anything else on that unit needs an
  explicit `systemctl --user restart quickshell`.
- **The compositor** — keeps running its old binary out of the store, which
  stays alive because the old generation is still referenced. A rebuild that
  bumps the hyprland package therefore does nothing until logout or reboot, and
  in the meantime the new `hyprctl` is talking to an older compositor. Compare
  `pgrep -af "bin/Hyprland"` against
  `readlink -f /run/current-system/sw/bin/Hyprland` to see whether they have
  drifted apart. (Not yet exercised here — no package bump has landed.)
- **greetd / the session itself** — reboot; see the uwsm section above for why
  restarting it is not an option.

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

or a reboot. Not a bug — a fresh machine always has a new generation, so
first-boot bootstrap works.

A manual `stow` run is *not* the third option it looks like: on this VM it
aborts (see "Driving it over SSH"), so make the link by hand instead.

## Reaching Quickshell from a keybind

`qs ipc call menu toggle` — the `IpcHandler { target = "menu" }` in
`shell.qml`. No config selection is needed: `~/.config/quickshell/shell.qml`
registers as the `default` config and `qs ipc` picks the instance on the
current display. Every future panel reuses this; the bar icon instead calls
`menu.toggle()` directly, being the same process.

**Do not name an IPC function `show`.** `qs ipc show` is a CLI subcommand, so
the argument parser rejects the call with "The following argument was not
expected" before it ever reaches the handler — and `qs ipc show` will happily
list the function as registered while it is unreachable. The one that opens a
given level is `level` for this reason: `qs ipc call menu level style.theme`.

Apps start with `uwsm-app -- <id>.desktop`, which puts each app in its own
scope under `app-graphical.slice`. Launching them as children of the shell
would kill them all on `systemctl --user restart quickshell`.

`DesktopEntries.applications` fills in a few seconds **after** the shell
starts, so the app list must be a QML binding. Building it once when the menu
opens gives an empty list on the first open after a restart.

## The menu

One panel with a level stack, in Omarchy's `omarchy-menu.jsonc` shape: dotted
ids imply the hierarchy, so `style.theme.dark` is a child of `style.theme` and
no nesting syntax is needed. Kind is inferred — an entry with an `action`
fires, one with children descends, one with a `provider` fills its level from
elsewhere (only `apps` so far, from `DesktopEntries`). Their `Menu.qml` plus
`MenuModel.js` is ~2000 lines of jsonc parsing, plugin manifests and provider
indirection; this is ~25 entries in a QML object literal and needs none of it.

`enabled: false` lists a row with nothing behind it yet: dim, skipped by the
arrow keys and inert on Enter, rather than absent — so what is still missing
stays visible. Those are the rows to edit when the feature lands, and they are
the running list of what this desktop does not do yet.

Reachable as `qs ipc call menu toggle|open|close` and `level <id>`; bound to
`SUPER + SPACE`, with `SUPER + ALT + SPACE` (apps), `SUPER + ESCAPE` (system),
`SUPER + K` (keybindings) and `SUPER + SHIFT + CTRL + SPACE` (theme) opening a
level directly.

The keybinding sheet is the `binds` provider, reading
`~/.local/state/hypr-binds.tsv` through a `FileView` with `watchChanges`, so a
config reload refreshes it without restarting the shell. Rows carry a `chord`
instead of an icon, which is also what widens the window for that level — 28
characters of chord before the description starts, and ~100 rows. It is
**display only**: the recorder keeps the chord and the label, not the action,
so Enter does nothing there. Making it fire would mean serializing every
dispatcher back to Lua source, which is the expensive half of Omarchy's
script (their `lua_literal` alone is ~40 lines, and our binds are almost all
table arguments).

Escape and Left back out one level and only close at the root. Selection lands
on the first *enabled* row, deferred through `Qt.callLater` because ListView
resets `currentIndex` itself when the model changes, after `onRowsChanged`
runs.

## Wallpapers

Images live in `~/Pictures/wallpapers` — deliberately outside the repo, so no
binaries get committed. The shell scans it recursively (`find`,
png/jpg/jpeg/webp), so subfolders are for tidiness only, not meaning. The pick
is **per mode**: `~/.local/state/wallpaper-dark` and `-light`, each a plain
path, so flipping light/dark also swaps the picture and each side remembers its
own. A mode with no pick yet shows the gradient. `SUPER + CTRL + SPACE` (or
the menu's Style › Background) opens the picker; `qs ipc call wallpaper` also takes
`open/close/toggle`, `set <path>`, and `rescan` after adding files.

webp works, but only because `desktop.nix` sets `QT_PLUGIN_PATH` to
`qt6.qtimageformats` on the Quickshell unit — the package ships no webp
decoder, and without it a webp wallpaper silently falls back to the gradient.
The wrapper prefixes its own plugin paths, so setting the variable does not
displace them.

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

Bar and menu colours are the zenbones palettes, lifted from
`stow/shared/.config/ghostty/themes/zenbones_{dark,light}` so the bar and the
terminal are literally the same colours. `gsettings` is not installed; `dconf`
is, and writes the same database.

`\uf185` renders as a cog in JetBrains Mono Nerd Font, not a sun; `\uf522` is
the one that reads as a sun at 14px.

## Next steps

The plumbing is in place — portals (`xdg-desktop-portal` + `-hyprland` +
`-gtk`), pipewire/wireplumber and NetworkManager are all running, and the menu
now covers apps, wallpaper, theme, screenshots, power and the keybinding
sheet. The dim rows in it are the shortest list of what is still missing.

1. Notifications, then lock/idle, then a polkit agent.
2. **A display panel**, ported from Omarchy's
   `shell/plugins/panels/monitor/` (resolution, scaling, text size). Light/dark
   and nightlight belong in there rather than as their own bar buttons — so
   the  /  button is a placeholder, not a design.
3. **Nightlight**, the equivalent of macOS Night Shift: `hyprsunset` shifts
   colour temperature, and Omarchy drives it with a toggle plus a restart
   script. Wants a schedule; composes with light/dark rather than replacing
   it.

Half of Omarchy's tree cannot port: Install / Remove / Update are `pacman`
operations, and on NixOS that is a rebuild. The root menu here is necessarily
smaller than theirs.

## Known, not yet done

- Keyboard layout is `us`. Swedish is wanted eventually as a second layout,
  but not yet — `kb_layout = "us,se"` with a `grp:` toggle in `kb_options`
  when the time comes.
- No notifications, lock, OSD or polkit agent yet — no polkit agent is running
  at all, so any privileged GUI action will fail.
- Four packages the Omarchy keymap and menu assume are not installed in
  `desktop.nix`: `hyprlock` (lock), `wl-clipboard` (clipboard history, share),
  `slurp` (region select, so `grim` can only take the whole screen) and
  `hyprsunset` (nightlight). Menu rows and binds for these stay dim until they
  land.
- The bar uses JetBrains Mono Nerd Font (`nix/shared/system/linux.nix` installs
  several nerd fonts). Berkeley Mono is wanted as the system font eventually,
  but it is a paid font and needs vendoring before Nix can install it.
- Only one emoji font is installed; `noto-fonts-color-emoji` is commented out
  in `nix/shared/system/linux.nix` as slow to build. Quickshell UI will want it.
- Mason installs prebuilt glibc binaries, which cannot run on NixOS. Neovim
  itself works on the VM (all 74 vim.pack plugins installed cleanly), but the
  Mason-managed language servers are expected to be broken. Untested.
- No LSP for either config yet. `qmlls` is the QML one and ships inside
  `qt6.qtdeclarative` (confirmed present in nixpkgs, `bin/qmlls`), so it is a
  package plus an `nvim-fredrik/lsp/` entry — it must come from Nix, not
  Mason, whose prebuilt binaries cannot run here. For `hyprland.lua` the
  situation is worse: `hyprls` only understands hyprlang `.conf`, which is the
  format we do not use, so the realistic option is `lua_ls` plus a hand-written
  LuaCATS stub for the `hl` API. Unverified — nobody has tried either here.
- Root filesystem is at 63%; consider `nix.gc` before it matters.
