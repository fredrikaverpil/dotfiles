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
- Rebuild: `sudo nixos-rebuild switch --flake ~/.dotfiles#wily-vm`. Intended
  to be pre-authorized on **wily-vm only**, but in practice the permission
  layer refuses it over SSH along with `sudo reboot` — hand both to the user
  rather than retrying. Every other host stays ask-first regardless. If
  `home-manager-fredrik.service` fails at the end, read the stow section
  below: that step runs after activation, so it is not a failed rebuild.
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
# unlock the session first: this reloads Quickshell, and a reload under a lock
# strands it (see "Losing the lock surface" below).
rsync -a --delete --exclude .git --exclude result ~/.dotfiles/ fredrik@192.168.64.15:~/.dotfiles/
ssh fredrik@192.168.64.15 'cd ~/.dotfiles && git add -AN .'   # flakes ignore untracked files

# run something inside the live session (hyprctl, grim, an app)
ssh fredrik@192.168.64.15 "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
  HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t /run/user/1000/hypr | head -1); <cmd>"

# screenshot, then pull it back and look at it
… 'grim /tmp/shot.png'; scp fredrik@192.168.64.15:/tmp/shot.png .
```

For Hyprland's red config-error overlay, run `hyprctl configerrors` first — it
prints the current messages and is empty when the config is clean. The
compositor's per-instance log is
`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log` (also
available through `hyprctl rollinglog`), but neither it nor the journal gets
that overlay's message. A screenshot is still required for an app's own dialog
(such as Ghostty's) and to verify visual work, but not as the first diagnostic
for a Hyprland config failure.

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

**Never hand-link a new stow file with `ln -sfn`.** stow only recognises
*relative* links as its own, so an absolute one becomes *"Ignoring an absolute
symlink"* followed by *"existing target is not owned by stow"* — and stow
aborts the entire run, failing `home-manager-fredrik.service` on every rebuild
from then on. Three such links once made the whole thing look unfixable; the
rest of `$HOME` was stow's own relative links all along.

Editing an already-linked file needs nothing — rsync writes through the link. A
**new** file under `stow/` just needs stow re-run, which is the same command
home-manager activation runs:

```sh
stow --dir=$HOME/.dotfiles/stow --target=$HOME --restow --no-folding --adopt \
  shared Linux
```

If it ever reports the conflict above, `rm` the offending links (they are
symlinks into the repo, so nothing real is lost) and run it again.

## Split of responsibilities

- **Nix** (`desktop.nix`) declares packages and the session: `programs.hyprland`
  with `withUWSM`, greetd autologin, and Quickshell as a systemd **user**
  service bound to `graphical-session.target`. It also owns polkit, the
  pre-suspend delay-inhibitor unit and the small `wily-lock` PAM entry. greetd
  refuses to start unless `default_session` is set, even when only
  `initial_session` is wanted. `environment.PATH = lib.mkForce null` on the
  Quickshell unit is what makes the menu able to start anything: NixOS otherwise
  pins a sparse PATH on user units, and unsetting it is the only way to inherit
  the session PATH uwsm imports into the user manager. Both hops need it —
  finding `uwsm-app`, and then the bare command name in each app's `Exec`.
  Nothing reports the failure: `Quickshell.execDetached` is silent, and
  `systemd-run` inherits the same broken PATH, so a launch just does nothing.
- **stow** (`stow/Linux/.config/{hypr,quickshell}/`) carries the config and
  QML. Deliberate: the Quickshell tree gets edited constantly and stow
  symlinks take effect with no rebuild. Do not move QML into the Nix store.
  Under `--no-folding` that immediacy covers **edits** only — stow links each
  file individually, so a *new* file needs stow re-run (see above).
- **Cursor** — the small `macOS-hypr` v0.1 Hyprcursor data tree is stowed at
  `stow/Linux/.local/share/icons/macOS-hypr/`, so it needs no Nix package
  build. Download updates from [the upstream releases](https://github.com/6ooker/apple_hyprcursor/releases);
  its [source code](https://github.com/6ooker/apple_hyprcursor) is in the same
  project. The cursor manager reads `HYPRCURSOR_*` only at compositor startup:
  `hl.env` records the choice but a reload cannot replace the loaded theme, so
  its `environment.sessionVariables` in `desktop.nix` need a reboot to apply.

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
- **`hyprctl keyword` no longer works at all**: it answers *"keyword can't work
  with non-legacy parsers. Use eval."* Runtime config changes go through
  `hyprctl eval "hl.<...>"` instead, which is the same Lua the config file uses.
- **`hyprctl dispatch` takes Lua now**: `hyprctl dispatch 'hl.dsp.exec_cmd("ghostty")'`.
  A hyprlang-shaped dispatch is a *parse* error, and it is reported only on
  hyprctl's own stdout — nothing logs it. A caller that does not read that
  output, such as Quickshell's `Process`, sees a silent no-op: the lock
  screen's `hyprctl dispatch dpms off` never blanked anything, and looked
  exactly like a timer that was not firing. The DPMS one is
  `hl.dsp.dpms("on")` / `hl.dsp.dpms("off")`.
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

**The modifiers are layers, and a new bind belongs in the right one.** Derived
from their whole keymap, not stated anywhere upstream:

| Chord | Layer |
| --- | --- |
| `SUPER + <key>` | window and workspace management — close, split, float, fullscreen, focus, group, scratchpad |
| `SUPER + SHIFT + <letter>` | launch an application — nearly all of their `applications.lua` |
| `SUPER + CTRL + <letter>` | system toggle or panel — lock, idle, nightlight, audio, bluetooth, display, network, power |
| `+ ALT` | not a layer: the variant of the chord without it |

`+ ALT` is the one that reads wrong at first. `SUPER + F` is full screen and
`SUPER + ALT + F` full width; `SUPER + S` toggles the scratchpad and
`SUPER + ALT + S` moves a window to it; `SUPER + CTRL + R` sets a reminder and
`SUPER + CTRL + ALT + R` shows them. So the per-window form of a system toggle
is that toggle's chord plus ALT — which is how `SUPER + CTRL + ALT + I` (keep
*this* window awake) sits next to `SUPER + CTRL + I` (idle locking for the
session).

Ours is nearly empty in the application layer — `SUPER + RETURN` and
`SUPER + SHIFT + N`, against their ~25. Most of theirs are webapps launched
through `omarchy-launch-webapp`, which is not ported.

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

## Losing the lock surface, and getting out of it

**Quickshell hot-reloads on any change to a file it has loaded**, which
includes an `rsync` from the laptop. Do that while the session is locked and
the lock client dies under a compositor lock that stays up: Hyprland replaces
the screen with *"Oopsie daisy, it looks like you locked your screen but the
lockscreen app died"*. `qs ipc call lock status` then reports
`locked:false, secure:true` — the shell no longer owns the lock it cannot
release. Editing QML while locked is the easy way to hit this; so is
`systemctl --user restart quickshell`.

That screen names its own way out, and it works over SSH with the usual
session exports — no tty switch, no reboot:

```sh
hyprctl eval "hl.clear_crashed_lockscreen()"
```

The screen suggests `hyprctl --instance 0` and a `killall` of the lock
process; neither is needed when `HYPRLAND_INSTANCE_SIGNATURE` is exported and
the client is already gone. Verified live.

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
- **User units** — a unit whose definition changed **is** stopped and started,
  and the switch names it: *"stopping … starting the following user units:
  wily-sleep-lock.service"*. Verified when a one-line edit to that script gave
  it a new store path. (This entry used to claim user units are only
  *reloaded*; that was wrong. Anything on the unit, `QT_PLUGIN_PATH` included,
  is part of its definition, so a change to it restarts the unit.) Read the
  switch output — it is authoritative about what was touched.
- **The Quickshell unit** — restarts with everything else when its definition
  changes, which is usually what you want. **Do not restart it while the native
  lock is active:** `ext-session-lock` outlives its client, so this lean
  first version cannot recover the stranded compositor lock; see the ThinkPad
  deferrals below.
- **The compositor** — keeps running its old binary out of the store, which
  stays alive because the old generation is still referenced. A rebuild that
  bumps the hyprland package therefore does nothing until logout or reboot, and
  in the meantime the new `hyprctl` is talking to an older compositor. Compare
  `pgrep -af "bin/Hyprland"` against
  `readlink -f /run/current-system/sw/bin/Hyprland` to see whether they have
  drifted apart. (Not yet exercised here — no package bump has landed.)
- **greetd / the session itself** — reboot; see the uwsm section above for why
  restarting it is not an option.

## The clock stops when the Mac sleeps

UTM pauses the VM with the host, and the guest clock simply stops — a night's
sleep leaves it hours behind. `systemd-timesyncd` does not recover from that:
it steps only on its *first* sync and slews afterwards, so it reports
`System clock synchronized: yes` while sitting hours out, with a huge
`Frequency` in `timedatectl show-timesync`. `configuration.nix` therefore runs
chrony with `makestep 1.0 -1` instead, which steps at any poll. Check with
`chronyc tracking`.

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

**Staying diffable against upstream is a design constraint, not a nicety.**
The point of vendoring is to pull their bugfixes later, and that only works if
a ported piece still resembles its origin. So, when writing or changing
anything that has an Omarchy counterpart:

- **Read their version first.** Find it in the clone before designing ours —
  `grep -rl` over `bin/`, `shell/` and `etc/` — even when the mechanism seems
  obvious. Theirs usually encodes a failure this VM has not hit yet.
- **Keep their file paths, IPC target names and function names** where the
  concept is the same, so `diff` lines up. This is why the Quickshell services
  live under matching `plugins/…` paths and answer the same `qs ipc` targets.
- **Prune deliberately, and say so here.** A simplification we chose is fine;
  a divergence nobody remembers making is what makes the next upstream diff
  unreadable. Record what was dropped and why, in this file.
- **Where we diverge in shape rather than in behaviour, note the counterpart**
  so the next person knows where to look upstream.

Known divergences in the sleep path — ours is `wily-sleep-lock.service` running
an inline `writeShellApplication` in `desktop.nix`; theirs is
`bin/omarchy-system-sleep-lock` plus `bin/omarchy-system-sleep-monitor`, with
tests in `test/shell.d/sleep-lock-test.sh`. Same mechanism (a logind delay
inhibitor that locks on `PrepareForSleep` and waits for `secure`), but they
also:

- ship `etc/systemd/logind.conf.d/20-inhibit-delay.conf` raising
  `InhibitDelayMaxSec` to 15, because logind's 5s default is not enough when a
  lid close reconfigures displays first. Our fixed 3s poll fits inside the
  default; that stops being true on a laptop.
- derive the wait budget from logind's actual `InhibitDelayMaxUSec` rather than
  hardcoding it, and clamp every IPC call to what is left of it.
- **send a critical notification when the lock did not go secure.** logind
  suspends regardless, so this is the only way anyone learns the machine slept
  with the session exposed. Ours only writes to stderr, where nobody looks.
- handle a `missing-pam` refusal and re-request a lock that never landed.

The first is a lid consequence and cannot matter here — no lid, one scanout.
The third is wanted regardless and was simply not built: a stderr line nobody
reads is a poor way to learn the machine slept unlocked.

## Reaching Quickshell from a keybind

`qs ipc call menu toggle` — the `IpcHandler { target = "menu" }` in
`shell.qml`. No config selection is needed: `~/.config/quickshell/shell.qml`
registers as the `default` config and `qs ipc` picks the instance on the
current display. Every future panel reuses this; the bar icon instead calls
`menu.toggle()` directly, being the same process.

The Omarchy-shaped services use their upstream-compatible targets too:
`notifications` (`showHistory`, `toggleDnd`, `dismissOne`, `dismissAll`,
`invokeLast`), `lock` (`lock`, `status`, `isLocked`) and `idle`
(`enable`, `disable`, `toggle`, `status`). From SSH they need the live-session
`XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY` export from "Driving it over SSH".

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

## Notifications, lock, idle and polkit

Quickshell 0.3.0 on this VM supplies `NotificationServer`, `PolkitAgent`,
`PamContext`, `WlSessionLock` and `IdleMonitor`, so this deliberately follows
Omarchy Quattro's native architecture rather than installing `hyprlock`,
`hypridle` or `hyprpolkitagent`. The files live under the matching
`stow/Linux/.config/quickshell/plugins/{notifications,lock,polkit,services/idle}`
paths, but `shell.qml` loads them directly — we do not carry Omarchy's general
plugin registry or `qs.Commons` framework. That makes upstream diffs useful
without coupling the VM to their whole shell.

- **Notifications** own `org.freedesktop.Notifications`, show top-right toast
  cards (low: 5s, normal: 8s, critical: until dismissed), expose standard
  actions, and keep the newest ten non-transient entries plus DND state in
  `~/.local/state/wily-notifications.json`. The bar bell and System ›
  Notifications open the history panel; `libnotify` supplies `notify-send` for
  smoke tests and CLI callers. History records the display data only — it does
  not retain an action after the sender has gone away. A critical notification
  still toasts under DND; everything else is recorded silently. Clicking a
  card's body, and `invokeLast`, fire only an action registered under the
  canonical identifier `default` — any other identifier is reachable from its
  own button and nothing else. (Omarchy falls back to focusing the sending app
  by class, which needs one of their scripts.)

  **Nothing couples notifications to the lock**, here or in Omarchy, and it
  works out anyway — verified live. `ext-session-lock` renders above the
  overlay layer, so a toast arriving while locked is hidden rather than leaked;
  the `wily-notifications` layer is still listed in `hyprctl -j layers`, just
  covered. What differs is what survives the lock, and it falls out of
  `addHistory` being reachable only from `finish()`: a normal toast runs its 8s
  timer unseen behind the lock, expires, and is findable only in history,
  while a critical one has no timeout, never finishes, and is still on screen
  at unlock. So urgency already decides what waits for you — do not "fix" this
  by suppressing toasts while locked without replacing that property.
- **Lock / idle** use `WlSessionLock` plus `PamContext` against
  `/etc/pam.d/wily-lock`, a conventional `auth include login` entry.
  `WlSessionLock` has **no `unlock()`** — clearing its `locked` property is the
  unlock. Calling the method that does not exist throws *after* the PAM success
  has already reset the service's own state, which strands the lock surface
  with its input disabled and no way back in. Its `WlSessionLockSurface` is a
  per-screen component, so an `id` declared inside it is not addressable from
  the enclosing service. **Do not drive DPMS while the lock is being
  acquired** — a `dpms on` dispatched from `beginLock` churns the output
  underneath the surface and takes the whole shell down with
  *"Tried to show lockscreen surfaces without active lock"* (the last line in
  `~/.cache/quickshell/crashes/*/log.qslog.log`, which is where a crash is
  actually explained; the journal only carries the stack trace). Nor
  redundantly: `wake()` runs on every keystroke, and dispatching `dpms on` to
  an output that is already on forces a modeset that flashes the lock screen
  black between characters. The service therefore tracks its own `blanked`
  flag and dispatches only on a change — which assumes nothing else drives
  DPMS, since an outside `dpms off` would desync the flag and leave a
  keystroke unable to bring the screen back. Do not
  replace it with `security.pam.services`: on this aarch64 nixpkgs revision the
  PAM renderer evaluates disabled Howdy/Kanidm module paths and fails before it
  can render a custom service. `IdleMonitor` honours inhibitors, locks at five
  minutes and the lock surface requests DPMS off five minutes later; input
  wakes it. `wily-sleep-lock.service` holds a logind delay inhibitor, requests
  the lock on `PrepareForSleep`, and waits up to three seconds for its `secure`
  state.
- **Polkit** is Quickshell's `PolkitAgent`, registered at
  `/org/wily/PolkitAgent`; NixOS runs the authority. It is a password dialog in
  the existing palette, so privileged desktop requests have an agent rather
  than failing without a prompt. `security.polkit.enable` does not imply the
  setuid `pkexec` wrapper — `enablePkexecWrapper` is its own option, and
  without it `pkexec` aborts with "must be setuid root" before reaching any
  agent. D-Bus callers such as `systemctl` prompt either way, which makes
  `systemctl restart <unit>` from inside the session the way to test the
  dialog; `pkexec` from an SSH shell is the wrong subject anyway.

The matching Omarchy keybinds are `SUPER + comma` (dismiss latest),
`SUPER + SHIFT + comma` (dismiss all), `SUPER + CTRL + comma` (DND),
`SUPER + ALT + comma` (invoke latest), `SUPER + SHIFT + ALT + comma` (history),
`SUPER + CTRL + I` (toggle idle locking), and `SUPER + CTRL + L` (lock).

## Deferred for the ThinkPad

- Fingerprint unlock, including its separate PAM stack and reader indicator.
- Lid close, which is the laptop's actual sleep and lock trigger and has no
  equivalent here — one scanout, no lid. Omarchy carries a whole
  `bin/omarchy-system-lid-close` plus `test/shell.d/lid-close-test.sh` for it,
  and its sleep-lock script calls `omarchy-hyprland-monitor-clamshell` inside
  the delay window, which is also why they need the longer inhibitor budget.
  Settle the `loginctl lock-session` question as part of this — see "Known, not
  yet done"; the choice of `HandleLidSwitch` is what decides it.
- Reacquiring an orphaned `ext-session-lock` from inside the shell. Omarchy
  detects Hyprland's `solitaryBlockedBy: LOCK` state and takes the surface
  back; here the compositor-side escape below is the recovery instead, so the
  port only becomes worth it if the shell should heal itself silently.
- Full notification durability: on-screen toast restoration across a shell
  restart, persistent image copies and cleanup, rich body markup/image
  sanitization, inline replies, and preserving trusted actions in history.
- Omarchy's 150-second screensaver stage before the five-minute lock, its
  stay-awake indicator/control, and hardware validation of DPMS plus the
  pre-suspend delay budget.
- Unlock after a real resume, and the two sleep-path pieces the VM cannot
  justify: the `InhibitDelayMaxSec=15` logind drop-in and a critical
  notification when the pre-suspend lock fails. See the sleep divergences under
  "Reference".

## Next steps

The plumbing is in place — portals (`xdg-desktop-portal` + `-hyprland` +
`-gtk`), pipewire/wireplumber and NetworkManager are all running, and the menu
now covers apps, wallpaper, theme, screenshots, power, notifications and the
keybinding sheet. The dim rows in it are the shortest list of what is still
missing.

1. **A display panel**, ported from Omarchy's
   `shell/plugins/panels/monitor/` (resolution, scaling, text size). Light/dark
   and nightlight belong in there rather than as their own bar buttons — so
   the  /  button is a placeholder, not a design.
2. **Nightlight**, the equivalent of macOS Night Shift: `hyprsunset` shifts
   colour temperature, and Omarchy drives it with a toggle plus a restart
   script. Wants a schedule; composes with light/dark rather than replacing
   it.

Half of Omarchy's tree cannot port: Install / Remove / Update are `pacman`
operations, and on NixOS that is a rebuild. The root menu here is necessarily
smaller than theirs.

## Known, not yet done

- The notification, lock and polkit services are verified live on the VM
  (toasts and their timeout bar, DND with critical breaking through, dismiss
  one/all, history and its `Clear`, `default`-action invoke, the lock surface
  with a wrong-password counter, a real PAM unlock, toasts staying hidden
  behind the lock surface while a critical one survives to unlock, the polkit
  dialog through both `pkexec` and a D-Bus caller, `IdleMonitor` taking the
  lock on its own after the idle timeout, and the lock surface blanking the
  output 301s after locking). Testing either timer means leaving the VM
  genuinely untouched for over five minutes: SSH polling does not reset them,
  but any use of the UTM window does, and a run interrupted that way looks
  exactly like a broken timer.
- `wily-sleep-lock` is verified as far as this VM allows. On a real
  `systemctl suspend` it locked inside the delay window: logind logged
  *suspend requested* and *The system will suspend now!* in the same second —
  a monitor that missed `PrepareForSleep` would instead have made logind burn
  the whole inhibitor window — and the script's failure line, *"session lock
  was not secure before suspend"*, is absent from that boot. The unit exits
  after each `PrepareForSleep` by design, so every suspend after the first
  depends on `Restart=always`; verified separately with `systemctl --user kill
  wily-sleep-lock`, after which it returns within 2s, `NRestarts` increments,
  and the delay inhibitor is re-acquired. Resume-specific timing is covered by
  none of this.
- **Suspend is a one-way trip on this VM, so plan for a forced power cycle.**
  The only clock is `rtc-efi`, which exposes no `wakealarm`, so `rtcwake`
  cannot arm a timed wake; virtio input and `utmctl stop --request` both leave
  the vCPUs halted while UTM still reports the VM as `started`. Recover with
  `utmctl stop --force` and a restart, and read the evidence from
  `journalctl -b -1`, which survives it. Unlock-after-resume waits for the
  ThinkPad.
- `wily-sleep-lock` logs *"dbus-monitor: unable to enable new-style monitoring:
  AccessDenied … Falling back to eavesdropping"* on every boot. It is noise: the
  match is on a broadcast signal, which needs no eavesdropping, and the suspend
  test above proves the monitor receives it.
- **`loginctl lock-session` reports success and does nothing.** Nothing listens
  for logind's `Lock`/`Unlock` signals — verified: the call returns cleanly and
  `lock status` still reports `locked:false`. Omarchy is the same (`grep -rniE
  "login1|loginctl" shell/` is empty; their entry point is
  `bin/omarchy-system-lock`, which calls `omarchy-shell lock lock`, the same IPC
  path as ours), so this is left alone deliberately rather than fixed into a
  divergence. Nothing here emits the signal: greetd autologins, and idle locking
  is `IdleMonitor` rather than logind's `IdleAction=lock`.

  **Read this before touching lid handling on the ThinkPad.** The lid is safe
  under `HandleLidSwitch=suspend`, which is what logind actually reports here
  (`busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitch` → `s "suspend"`) — the lid
  suspends, which raises `PrepareForSleep`, which `wily-sleep-lock` already
  handles. Setting
  `HandleLidSwitch=lock` instead — lid shut, machine awake, clamshell on an
  external monitor — is the one configuration that breaks: logind emits `Lock`,
  nobody listens, and the machine sits unlocked with the lid closed. Omarchy
  covers that case with `bin/omarchy-system-lid-close`, not by subscribing to
  the signal.
- **`IdleMonitor` honours a real Wayland idle inhibitor — verified.** With
  `nix run nixpkgs#wlinhibit` holding a `zwp_idle_inhibit_manager_v1`
  inhibitor, the session sat 400s past its 300s timeout still reporting
  `idle:false, locked:false`. Unaided it then locked at the timeout in the
  same session, so the inhibitor is what changed the outcome. Hyprland's own
  `idle_inhibit` window rule does the same, tested first and superseded by
  this. `wlinhibit` is not installed — `nix run` it, there is nothing to add
  to `desktop.nix`.

  Three ways a re-run passes or fails for the wrong reason, all hit here:
  `qs ipc call idle status` must read `enabled:true` **before** the wait, or
  `idle:false` means only that the monitor is off. Any host-side input
  restarts the timer, so check `pmset -g log` on the Mac afterwards for a
  `UserIsActive` HID assertion inside the window — a locked Mac is fine and
  actually helps, since nothing then reaches UTM. And a host *sleep* pauses
  the VM: run `caffeinate -i` on the Mac for the duration, use a guest-side
  `sleep` (monotonic, so a pause and chrony's catch-up step do not shorten
  it) and ignore the wall-clock delta — a 400s wait spanning a step reads as
  827s of `date`.

  `hyprctl -j clients` reports **`inhibitingIdle`** per client, which is the
  way to tell an inhibitor that never took from one that is not honoured.
  Nothing in `hyprctl --help` mentions it — it was found in Omarchy's
  `bin/omarchy-debug-idle`, which is worth reading before debugging this
  again. Whether a client like `wlinhibit`, which has no ordinary window,
  shows up there at all is untested; the tag rule below does.
- Omarchy's idle service uses the same `IdleMonitor` with the same
  `respectInhibitors: true` (`shell/plugins/services/idle/Service.qml:250`),
  so this result carries to their code — and their `test/shell.d/idle-test.sh`
  does not cover it either (Node unit tests over `IdleModel.js` plus the
  stay-awake toggle's state file; no compositor, no Wayland), so there is no
  test upstream to port. Where they differ is the policy on top: two timers
  staging a screensaver before the lock, and a "stay awake" toggle that gates
  the monitor rather than taking an inhibitor.

  Their `o.window({ tag = "noidle" }, { idle_inhibit = "always" })`
  (`default/hypr/apps/system.lua:57`) **is** ported — tag a window and the
  whole session stays awake. Upstream leaves applying the tag to the user;
  `SUPER + CTRL + ALT + I` here toggles it on the active window and reports
  which way it landed, since their affordance for this is a bar indicator we
  have not ported. The chord is the per-window variant of `SUPER + CTRL + I`
  under the modifier scheme in "The keymap is Omarchy's", and is unused
  upstream. The readback is `inhibitingIdle` rather than the tag, so the
  message says the rule fired, not merely that the tag exists.
  `hl.dsp.window.tag({ tag = "noidle" })` with no `action` toggles; the
  argument must be a table, and a bare string raises.

  **Reach for it last.** Firefox and Chromium take a
  `zwp_idle_inhibit_manager_v1` inhibitor themselves while a video plays, which
  is the protocol verified above, so video should need no tag and no keypress.
  Neither is installed here, so that is mechanism, not a test — it is a
  30-second check on the ThinkPad and worth doing before assuming otherwise.
  An app that turns out not to inhibit wants a rule matched on its class with
  `idle_inhibit = "fullscreen"`, the way Omarchy ships Steam, Moonlight,
  RetroArch and GeForce NOW in `default/hypr/apps/*.lua` — config, so it
  survives a reboot. The tag is for the case nobody anticipated.
- Keyboard layout is `us`. Swedish is wanted eventually as a second layout,
  but not yet — `kb_layout = "us,se"` with a `grp:` toggle in `kb_options`
  when the time comes.
- No OSD yet.
- Three packages the Omarchy keymap and menu assume are not installed in
  `desktop.nix`: `wl-clipboard` (clipboard history, share), `slurp` (region
  select, so `grim` can only take the whole screen) and `hyprsunset`
  (nightlight). Menu rows and binds for these stay dim until they land.
  `hyprlock`, `hypridle` and `hyprpolkitagent` are deliberate omissions: the
  equivalents here are native Quickshell services.
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
