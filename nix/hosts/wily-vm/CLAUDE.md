# wily-vm

Throwaway NixOS VM used to build up a Quickshell desktop before it lands on the
real machine (ThinkPad T14 G6, Core Ultra 7 258V / Lunar Lake, x86_64). Keep
the config portable — nothing VM-specific outside the notes below.

**Two compositors are installed, Hyprland and niri, and one shell runs under
either.** `hypr` and `niri` at the console start them; they are alternatives,
never concurrent. Hyprland is the one with history here, so anything below that
does not say otherwise was established under it. See "Running under niri".

This file is worked on as the setup grows — update it in the same commit as
the change it describes. Worth writing down: a fact that cost time to
establish (an API shape, a hardware limit, why a mechanism was chosen over the
obvious one), and anything that will bite the next person the same way. Not
worth writing down: what the code already says.

**Delete entries as they stop being true.** A stale line here is worse than a
missing one, because it gets believed and acted on.

## Prior art to steal from

Three other Quickshell setups cover the same ground; read theirs before
designing ours. All are cloned locally (each within days of upstream as of
2026-09-04 — `git -C <clone> pull` before relying on one):

- **Omarchy 4 "Quattro"**, `~/code/public/github.com/omarchy` — one level
  shallower than the rest of that tree. The model for this setup; "Reference"
  below has the vendor-and-prune rules, which apply to this one only.
- **caelestia**, `~/code/public/github.com/caelestia-dots/shell` — ~280 QML
  files, a widget per directory under `modules/` and a singleton per concern
  under `services/`. The closest thing to a second opinion on any QML we write.
- **DankMaterialShell**, `~/code/public/github.com/AvengeMedia/DankMaterialShell`
  — the QML is under `quickshell/`, laid out as `Modules/<Surface>/Widgets/`
  with singletons in `Common/`. Its widgets run large (the tray is 2268 lines
  across `SystemTrayBar.qml` and `Common/TrayMenuManager.qml`, against
  caelestia's 388 in three files), so it is the one to read for what a
  feature's full surface looks like, not for how to shape one.

Where the three disagree, the disagreement is usually the interesting part:
caelestia is the minimal expression, Omarchy the considered one, Dank the
exhaustive one. Reading the same widget in all three costs ten minutes and has
so far been worth it every time.

## Reaching it

- The VM's IP is DHCP-assigned and changes across reboots — never hard-code it.
  Look it up on the Mac each session and reuse it:

  ```sh
  VM=$(awk -F= '/name=wily-vm/{f=1} f&&/ip_address/{print $2; exit}' /var/db/dhcpd_leases)
  ```

  Then `ssh fredrik@"$VM"` (key auth; password auth also on). Shell state does
  not persist between tool calls, so prefix each command with that `VM=…`
  assignment, or substitute the address you looked up.
- Rebuild: `sudo nixos-rebuild switch --flake ~/.dotfiles#wily-vm`. sudo now
  requires the user's password, and the permission layer also refuses it over
  SSH along with `sudo reboot` — hand both to the user rather than retrying.
  Every other host stays ask-first regardless. If
  `home-manager-fredrik.service` fails at the end, read the stow section
  below: that step runs after activation, so it is not a failed rebuild.
- `~/.dotfiles` on the VM is a clone of the GitHub repo; see the next section
  for pushing uncommitted work to it.

## Driving it over SSH

### Deployment gate

**Before asking the user to rebuild, or treating a live-VM check as validation
of a local change, rsync the laptop checkout to the VM.** `nixos-rebuild`
evaluates `~/.dotfiles` *on the VM*, never this checkout; skipping that transfer
therefore cleanly rebuilds stale configuration and leaves new packages, desktop
entries and binds absent. The first two commands below are mandatory together
before every rebuild after a local edit. Re-run them after every later local
edit before another VM test or rebuild, and only then tell the user the VM is
ready to switch. If the result looks unchanged, verify this gate before
debugging the feature.

`--delete` also overwrites `hardware-configuration.nix`, so that file must
never name anything the VM mints at install time. It uses `/dev/disk/by-label/`
(`nixos`, `boot`) rather than the by-uuid `nixos-generate-config` emits: a
reimage gives the disk fresh UUIDs, and the committed stale ones then ride back
over the VM's regenerated copy on the next rsync. The result is a generation
whose `/boot` and `/` do not exist — local-fs.target fails and the boot lands in
**emergency mode**. Recover by picking the previous generation at the boot menu.

These get used constantly. `HYPRLAND_INSTANCE_SIGNATURE` must be the
**newest** directory — stale ones accumulate under `/run/user/1000/hypr/`.

```sh
# push uncommitted work from the laptop (--delete matters: without it, files
# deleted locally linger on the VM and keep getting stowed). The git add -AN is
# not optional: flakes ignore untracked files, and a new file that is not at
# least intent-to-added fails evaluation with "Path ... is not tracked by Git".
# unlock the session first: this reloads Quickshell, and a reload under a lock
# strands it (see "Losing the lock surface" below).
rsync -a --delete --exclude .git --exclude result ~/.dotfiles/ fredrik@"$VM":~/.dotfiles/
ssh fredrik@"$VM" 'cd ~/.dotfiles && git add -AN .'   # flakes ignore untracked files

# run something inside the live session (hyprctl, grim, an app)
ssh fredrik@"$VM" "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 \
  HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t /run/user/1000/hypr | head -1); <cmd>"

# Screenshot only the affected UI at native resolution — this 100×32px crop
# is the right end of the current 1280×800 top bar. It is still pixel-accurate
# for measuring. `hyprctl -j monitors` gives the geometry when it changes.
… 'grim -g "1180,0 100x32" -l 9 /tmp/shot.png'; scp fredrik@"$VM":/tmp/shot.png .

# Capture the whole desktop only when composition matters; halve it first.
… 'grim -s 0.5 -t jpeg -q 75 /tmp/shot.jpg'; scp fredrik@"$VM":/tmp/shot.jpg .
```

**Do not default to full-resolution screenshots.** Cropping with `grim -g`
reduces the image dimensions, and therefore the visual context sent to the
agent; changing compression alone does not. Use a native-scale crop when
counting pixels or checking a local visual change, and `-s 0.5` only when the
whole screen is needed. For small, flat UI crops, lossless PNG is usually
smaller than JPEG; JPEG is for a photo-heavy whole desktop. Grim 1.5 supports
PNG, JPEG and PPM, but not WebP, so no extra image tool is warranted.

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

**Any git operation that rewrites `hyprland.lua` costs a `hyprctl reload`**,
not just `clean`: `checkout`, `reset --hard`, `pull` and `stash pop` all
materialize a file by `unlink()` then create, so the path vanishes for an
instant and Hyprland's re-parse records *"cannot open … No such file or
directory"* — the red overlay, with every bind still registered. `rsync` and
`scp` write in place with `O_TRUNC` and never do this; verified both ways.
Note that git rewrites the file whenever the **index** disagrees with the
target commit, so a worktree whose bytes already match is no protection: work
pushed here with `rsync` and never committed *on the VM* leaves the index
stale, and the next `pull` touches the file anyway.

**Never hand-link a new stow file with `ln -sfn`.** stow only recognises
*relative* links as its own, so an absolute one becomes *"Ignoring an absolute
symlink"* followed by *"existing target is not owned by stow"* — and stow
aborts the entire run, failing `home-manager-fredrik.service` on every rebuild
from then on. Three such links once made the whole thing look unfixable; the
rest of `$HOME` was stow's own relative links all along.

Editing an already-linked file needs nothing — rsync writes through the link. A
**new** file under `stow/` just needs stow re-run, which is the same command
home-manager activation runs:

```bash
cd "$HOME/.dotfiles"
stow --dir=stow --target="$HOME" --restow --no-folding --adopt shared
stow --dir=stow/platform --target="$HOME" --restow --no-folding --adopt Linux
host="$(hostname -s)"
[ -d "stow/host/$host" ] && \
  stow --dir=stow/host --target="$HOME" --restow --no-folding --adopt "$host"
```

If it ever reports the conflict above, `rm` the offending links (they are
symlinks into the repo, so nothing real is lost) and run it again.

## Split of responsibilities

- **Nix** (`desktop.nix`, plus `users/fredrik.nix` for user-owned browser
  configuration) declares packages and the session: `programs.hyprland` with
  `withUWSM`, but deliberately no display manager. It retains
  `programs.hyprland`'s `graphical.target` default: with no display manager,
  agetty still supplies the password-authenticated console, while UWSM's
  `check may-start` requires `graphical.target` to be active. The `hypr` shell
  function from `shell/sourcing.sh` starts Hyprland through UWSM. Quickshell is
  a systemd **user** service bound to `graphical-session.target`. Nix also owns
  polkit, the pre-suspend delay-inhibitor unit and the small `wily-lock` PAM
  entry. `fredrik` remains a wheel user, but sudo requires their password.
  `environment.PATH = lib.mkForce null` on the Quickshell unit is what makes the
  menu able to start anything: NixOS otherwise pins a sparse PATH on user units,
  and unsetting it is the only way to inherit the session PATH uwsm imports into
  the user manager. Both hops need it — finding `uwsm-app`, and then the bare
  command name in each app's `Exec`. Nothing reports the failure:
  `Quickshell.execDetached` is silent, and `systemd-run` inherits the same
  broken PATH, so a launch just does nothing.
- **Browsers** — Chromium and Firefox are `desktop.nix` packages. Zen comes
  from the `zen-browser` Home Manager module in `users/fredrik.nix`, which
  also makes it the user's XDG and `$BROWSER` default. Its `beta` branch
  packages Zen's normal upstream releases — Zen has no separate stable
  channel — while `twilight` is nightly. `NIXOS_OZONE_WL=1` selects
  Chromium's native Wayland backend; the Firefox and Zen wrappers already
  set `MOZ_ENABLE_WAYLAND=1` themselves.
- **Chromium ignores the light/dark switch until `--no-first-run`.** Its
  profile sits in a first-run state that pins the UI light and makes it ignore
  the portal's `color-scheme`, so the package is overridden with
  `commandLineArgs = "--no-first-run"`. Verified on the real profile: launched
  normally under `prefer-dark` it stayed light and logged *"Requested load of
  chrome://newtab/ for incorrect profile type"*; with the flag it came up dark
  and then followed live toggles with no restart. Everything else was ruled out
  first — the portal answers correctly (`busctl --user call
  org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop
  org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance
  color-scheme` returns 1 for dark, 2 for light), Firefox and Zen follow it, and
  writing `browser.theme.color_scheme = 0` into the profile changed nothing.
  Omarchy fixes the same thing with `{"distribution":{"require_eula":false}}` in
  `/usr/lib/chromium/initial_preferences` (`install/config/theme-system.sh`);
  that path is read-only in the Nix store, and it would only cover new profiles
  anyway.
  That flag is necessary but not sufficient: Chromium follows GTK, and the
  toggle writes `gtk-theme = "Adwaita-dark"` — a name GTK3 cannot resolve
  without `gnome-themes-extra`, since only `Adwaita` is compiled into the
  library. An unresolvable name falls back to the default light theme, and
  Chromium goes light no matter what `color-scheme` says. Holding
  `color-scheme` at `prefer-dark` and writing `gtk-theme = "Adwaita"` turns
  Chromium dark, which is what isolates it. Firefox and Zen read `color-scheme`
  directly and ignore `gtk-theme`, so nothing else on the VM showed the fault.
- **A GUI that edits a stowed file replaces the symlink with a copy.** Seen
  with a settings app appending an include to `hyprland.lua`: the live config
  silently detaches from the repo, and because the documented restow runs
  `--adopt`, the next restow adopts the copy *into* `stow/` instead of
  restoring the link. After letting any such tool touch `.config/hypr` or
  `.config/quickshell`, check with `stat -c %F` before restowing.
- **stow** — the `stow/host/wily-vm/` package carries both compositor configs
  and the Quickshell QML (`.config/{hypr,niri,quickshell}/`) plus the vendored fonts and
  icons (`.local/share/{fonts,icons}/`); wily-vm is the only desktop Linux host.
  `hypr/monitors.lua` supplies the monitor and GDK scales which the display
  panel updates. `shell.qml` owns the palette, menu entry table, instantiations
  and the small panel coordinator; the surfaces live in
  `plugins/{bar,menu,background}/` and share `Ui/Panel.qml`, which is the
  overlay chrome (transparent layer-shell surface, keyboard focus while modal,
  click-outside dismissal and a centred card). The coordinator closes any other
  open surface when one opens; the notification history registers with it too.
  **Panel's full-screen input mask cuts out the top-bar strip.** Without that
  cutout, a modal panel consumes a repeat click before its bar button can toggle
  it or open another panel. It must also settle from a brief `Exclusive` focus
  prime to `OnDemand`: Hyprland routes pointer input to an exclusive surface
  despite that cutout. **Pinning was built and then removed** — a pinned card
  kept its surface up with input masked to itself alone. It cost its keyboard
  focus to do that, and a layer-shell surface with no `wl_keyboard.enter` is
  never told which modifiers are held: a pinned panel could not be
  keyboard-navigated, could not be unpinned by any key, and no modifier-gated
  gesture (a SUPER+drag to move it) could be detected inside it. That left it
  mouse-only in a shell that is otherwise keyboard-first, for one panel. Do not
  reintroduce it without an answer to the focus problem — the readout it existed
  for (Network's live ping and transfer rates) is better served by a bar widget,
  which never takes focus in the first place. `keyNavigation` opts a panel into
  keyboard control: buttons set `activeFocusOnTab` and draw their border from
  `activeFocus`, and **Qt's own focus chain does the walking** —
  `nextItemInFocusChain` in document order, so no panel keeps a cursor of its
  own. It is deliberately one linear chain rather than a grid: `l`/`j` step
  forward and wrap from a row's last option into the next row's first, `h`/`k`
  step back. The handler sits on the card, the buttons' common ancestor; keys
  bubble to it from whichever holds focus.
  **Chain membership is never conditioned on a button's `available`**, only on
  its visibility: a button that goes unavailable while its own action runs —
  every scale preset during `scaleChanging`, every Wi-Fi control during `busy` —
  would otherwise drop out of the chain under the cursor and strand the focus.
  It stays reachable and its Enter handler refuses instead. Menu leaves the flag
  off — its search field owns the keyboard instead. Omarchy's shared
  `PanelKeyCatcher` plus a per-panel section/selection cursor was the
  alternative, and it is why their Display panel is 929 lines to this one's
  ~340. **Panel aliases its default property to the card's column**, so its own
  fixed children are assigned through `data` — an ordinary child there would be
  reparented into the column. A consumer's non-visual objects (`FileView`,
  `IpcHandler`) land in that column too, which is harmless: `Column` lays out
  `Item`s and ignores the rest. `Variants` takes exactly one child as its
  delegate, so anything else a surface needs — `Bar.qml`'s `SystemClock`,
  `Background.qml`'s state files — sits beside it under a `Scope`, not inside
  it. Putting it inside costs a `ReferenceError` at runtime, not a load failure.
  Deliberate: the Quickshell tree gets edited constantly and stow symlinks take
  effect with no rebuild. Do not move QML into the Nix store. Under
  `--no-folding` that immediacy covers **edits** only — stow links each file
  individually, so a *new* file needs stow re-run (see above).
- **Cursor** — the small `macOS-hypr` v0.1 Hyprcursor data tree is stowed at
  `stow/host/wily-vm/.local/share/icons/macOS-hypr/`, so it needs no Nix package
  build. Download updates from
  [the upstream releases](https://github.com/6ooker/apple_hyprcursor/releases);
  its [source code](https://github.com/6ooker/apple_hyprcursor) is in the same
  project. The cursor manager reads `HYPRCURSOR_*` only at compositor startup:
  `hl.env` records the choice but a reload cannot replace the loaded theme, so
  its `environment.sessionVariables` in `desktop.nix` need a reboot to apply.

## The shell is replaceable; the compositor config is not

Hyprland has no concept of a bar, a lock screen or a notification popup. Each
is an ordinary Wayland client using `wlr-layer-shell` for its surfaces and
`ext-session-lock-v1` for the lock, so a whole shell swaps by stopping one
process and starting another. Verified live: `systemctl --user stop quickshell`
then `nix run nixpkgs#noctalia` brought up a complete rival desktop in this
session, no compositor change and no rebuild.

- **The compositor config is the durable asset.** `hyprland.lua`,
  `monitors.lua` and the keymap belong to Hyprland and outlive any shell.
  The one coupled part is every bind that calls `qs ipc call …`.
- **The converse holds too, and is now exercised**: the shell survives a
  change of compositor. Adding niri needed five command sites changed, all of
  them now in `Ui/Compositor.qml`; the lock, polkit, notification and idle
  services were untouched, because each is a Wayland protocol or a D-Bus name
  rather than a Hyprland feature.
- **Wholesale swap yes, cherry-picking one panel no.** Noctalia v5 installs
  exactly one binary, `bin/noctalia`, and its C++ rewrite dropped Qt and QML
  entirely — so there is neither a component to run on its own nor source to
  lift into a Quickshell config. nixpkgs carries both generations under
  confusingly close names: `noctalia` is v5 (5.0.0-beta.8 on 2026-08-31),
  `noctalia-shell` is the old QML v4 (4.7.7).
- **Several desktop roles are singletons**, so "run both, keep the better
  half" is not on offer: `ext-session-lock-v1` allows one lock client per
  session, `org.freedesktop.Notifications` is a single D-Bus name held by
  whichever daemon claims it first, and polkit registers one agent per
  session. Idle is worse rather than better — several watchers coexist happily
  on `ext-idle-notify-v1`, so two lockers race instead of colliding loudly.
  Bars are the genuine exception: two layer-shell bars stack, each reserving
  its own exclusive zone. Read from the protocols, not measured here; only the
  wholesale swap above was exercised.

So the two shapes are a choice, not a spectrum. This host takes the first: one
shell owning every surface, which is why `hyprlock`, `hypridle` and
`hyprpolkitagent` are omitted in favour of native Quickshell services. The
second is a compositor plus single-purpose daemons — a notification daemon, a
locker, an idle daemon, a tray — stitched together, and that is what filling a
Quickshell gap from outside actually costs, since no piece of a rival shell can
be borrowed on its own.

## Running under niri

`niri` at the console starts it, from the same `shell/sourcing.sh` block as
`hypr`. Both go through uwsm, so the shell's systemd unit, its inherited PATH,
`uwsm-app` launching and `uwsm stop` logout all work identically. Two details
that are not interchangeable:

- **The bare binary is started, not `niri.desktop`.** That entry execs
  `niri-session`, which builds a systemd session of its own and would collide
  with the one uwsm is building. The instance name follows from the executable,
  so the units are `wayland-wm@niri.service` and `wayland-session@niri.target`
  — both named in `desktop.nix` alongside their `hyprland.desktop` twins. The
  shell function forwards arguments to the real binary, so `niri msg …` from an
  interactive shell still reaches it rather than starting a session.
- **`uwsm finalize` has to name `NIRI_SOCKET`.** It exports `WAYLAND_DISPLAY`
  on its own, but the shell runs as a separate unit and gets nothing else from
  the compositor. Without that export `niri msg` fails inside the shell *and*
  `Ui/Compositor.qml` decides it is on Hyprland, so every compositor call goes
  to `hyprctl` and silently does nothing.

**`Ui/Compositor.qml` is the whole coupling** — a Quickshell singleton keyed on
`NIRI_SOCKET`, holding the five commands that differ and nothing else. Adding a
compositor means editing that file, not the services:

| What | Hyprland | niri |
| --- | --- | --- |
| DPMS | `hyprctl dispatch hl.dsp.dpms(…)` | `niri msg action power-{on,off}-monitors` |
| Close window | `hl.dsp.window.close()` | `niri msg action close-window` |
| Focus workspace | `hl.dsp.focus{workspace=…}` | `niri msg action focus-workspace N` |
| Monitor query | `hyprctl -j monitors` | `niri msg -j focused-output` |
| Scale | `hyprctl eval hl.monitor{}` | `niri msg output <name> scale <s>` |
| Nightlight | hyprsunset | wl-gammarelay-rs |

`Model.focusedMonitor()` folds the two monitor shapes together; niri answers
with the focused output directly rather than a list with a flag on it, and
reports refresh rate in millihertz.

**Panel keyboard focus does not demote under niri.** `Ui/Panel.qml` opens every
overlay `Exclusive` and then settles on `OnDemand`, because Hyprland otherwise
routes pointer input to the panel despite the bar-strip cutout. niri drops the
keyboard the instant that demotion lands — `niri msg -j layers` shows the
Overlay surface at `OnDemand` while `niri msg -j focused-window` still names the
window underneath — so the launcher opens with its search field unable to
receive a keystroke. The prime is therefore Hyprland-only; under niri the
surface stays `Exclusive` for as long as it is shown, and `focused-window` goes
`null`. niri routes the pointer by the input region regardless of
keyboard-interactivity, so the cutout is unaffected.

**The workspaces widget is the one thing that could not be a branch.**
Quickshell has no niri module, so `WorkspacesNiri.qml` reads
`niri msg -j event-stream` itself. `Workspaces.qml` loads one of the two
sources **by URL**, not by type: naming `WorkspacesHyprland` in QML would
compile it, and `import Quickshell.Hyprland` connects at import against a
socket that is not there. niri's workspace objects carry no window count, so
occupancy is counted from the window events, and any window event that cannot
be applied incrementally re-asks `niri msg -j windows` instead.

**niri workspaces carry two numbers and only one of them is the key you
press.** `id` is a global counter that is never reused and never renumbers;
`idx` is the 1-based position on the output, which is what `focus-workspace N`
takes and what the bar draws. They agree until a workspace is dropped, after
which `{id: 2, idx: 1}` is ordinary — and a widget reading `id` then outlines
"2" while you are on 1. `WorkspacesNiri.qml` therefore exposes `idx`
throughout and keeps an id→idx map, because `WorkspaceActivated` and a window's
`workspace_id` both name the workspace by `id`.

**Workspaces are dynamic under niri: `SUPER + 2` on an empty session does
nothing, and that is niri, not a bug.** Each output keeps its populated
workspaces plus exactly one trailing empty one, so with no windows open only
workspace 1 exists and `niri msg action focus-workspace 2` exits 0 having
moved nothing. Open a window first and workspace 2 appears. Hyprland's static
1–10 do not behave this way.

**Nightlight is two daemons, not one with a flag.** Hyprland dropped
`wlr-gamma-control-unstable-v1` in favour of its own `hyprland-ctm-control-v1`,
which is what hyprsunset speaks; niri implements the wlr protocol and not the
CTM one. So neither tool works on the other compositor. Everything above the
daemon is shared: `NightlightModel.js`, the solar schedule, the one-minute
tick, the override expiry and the serialize-and-retry apply are all unchanged,
because the backend is three shell fragments (`running`, `launch`, `set`,
`get`) in `Ui/Compositor.qml`. `pgrep -f`, not `-x`, for wl-gammarelay-rs:
`/proc` truncates `comm` to 15 characters, so the name reads
`wl-gammarelay-r` and an exact match never hits.

**The cheatsheet reads `~/.local/state/wm-binds.tsv` under both.**
`hyprland.lua` writes it as it registers each bind; niri's config is
declarative, so `config.kdl` sed's the two columns out of itself at startup —
which is why every bind there carries a `hotkey-overlay-title`. The extractor
deletes `^spawn-at-startup` lines first, or the line holding the sed script
matches its own pattern.

**The display panel writes `config.kdl` in place.** niri reloads on save, so
writing the file is also applying it; the apply-then-persist pair is kept
anyway because `niri msg output` is explicitly temporary. Both rewritten values
— `scale` and `GDK_SCALE` — are alone on their line and appear exactly once in
the file, which is what makes the `sed -E` safe. **The `output` block's
connector name must match `niri msg -j outputs`** (`Virtual-1` for this VM's
virtio-gpu) or the block is inert and a chosen scale lasts only until restart.

**Portals need `xdg.portal.config.niri.default`.** Nothing declares a backend
for `XDG_CURRENT_DESKTOP=niri`, and with no implementation every portal call
fails — including the Settings one carrying `org.freedesktop.appearance`, which
is what drives the light/dark toggle. xdph is Hyprland-only, so gtk is the
whole answer; screencast under niri would want xdg-desktop-portal-gnome.

### Two ways niri is worse here, both upstream

- **A locker restart under an active lock strands the screen**
  ([niri#2986](https://github.com/YaLTeR/niri/issues/2986)). niri keeps the
  session locked and paints its fallback — a solid dark red fill, no bar, no
  windows, which reads as a dead VM rather than a lock. There is no equivalent
  of Hyprland's `hyprctl eval "hl.clear_crashed_lockscreen()"`, but **exiting
  the session is not the only way out**: niri accepts a new `ext-session-lock`
  client, so `qs ipc call lock lock` on the restarted Quickshell takes the lock
  back, `status` reports `secure:true`, and the real lock surface returns, to
  be unlocked with the password as usual. Verified live under niri.
- **Locking is refused while the outputs are powered off**
  ([niri#205](https://github.com/YaLTeR/niri/issues/205)): niri cannot submit
  the blank frame the lock waits for. That is the mirror of Hyprland's "do not
  drive DPMS while the lock is being acquired" rule rather than a relief from
  it — the ordering constraint inverts, it does not go away. Neither has been
  reproduced here yet.

### Dropped from the keymap

niri is scrollable-tiling, so a chunk of Omarchy's SUPER layer has no target
and is simply absent from `config.kdl`: the scratchpad pair (`SUPER + S`,
`SUPER + grave` and their move variants), `SUPER + J` toggle split, `SUPER + P`
pseudo, workspace 10 (niri indexes from 1 with no tenth key bound), the
per-group window index binds, and the `SUPER + drag` move/resize mouse binds —
niri has no configurable pointer drag. `SUPER + CTRL + ALT + I` (keep this
window awake) goes too: it rides on Hyprland window tags and an
`idle_inhibit` window rule, neither of which niri has. Groups map onto columns
approximately — `SUPER + G` is `toggle-column-tabbed-display` and
`SUPER + ALT + LEFT/RIGHT` are consume/expel — which is close enough to keep
the chord and the wording, not close enough to call it the same feature.

**The cursor is niri's default.** The stowed `macOS-hypr` theme is Hyprcursor
data, and niri reads XCursor only.

### Not yet verified

Nothing in this section has run: niri needs a rebuild first. Static checks that
did pass — `niri validate` on `config.kdl` (from `nix shell nixpkgs#niri`), the
bind extractor against the real file (71 rows, no self-match),
`node Model.js`, and evaluation of the whole host. Everything else, starting
with whether the shell comes up at all under `wayland-session@niri.target`, is
open.

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
- **`hyprctl dispatch` takes Lua now**:
  `hyprctl dispatch 'hl.dsp.exec_cmd("ghostty")'`. A hyprlang-shaped dispatch is
  a *parse* error, and it is reported only on hyprctl's own stdout — nothing
  logs it. A caller that does not read that output, such as Quickshell's
  `Process`, sees a silent no-op: the lock screen's `hyprctl dispatch dpms off`
  never blanked anything, and looked exactly like a timer that was not firing.
  The DPMS one is `hl.dsp.dpms("on")` / `hl.dsp.dpms("off")`.
- **`hl.bind()` understands keysym names only — `code:NN` silently never
  fires.** Given `"SUPER + SHIFT + code:12"` it parses the modifiers and then
  stores the whole chord string as the key name, so `hyprctl binds` shows
  `modmask: 65`, `key: SUPER + SHIFT + code:12`, `keycode: 0`, the bind appears
  in the cheatsheet, and no key ever matches it. A `keycode` option on the bind
  is ignored too. Chords therefore follow the keyboard layout; there is no
  layout-independent form.
- Every Lua bind lists as `dispatcher: __lua` with an opaque registry index for
  `arg`, so hyprctl can tell you a bind's description and not its action.
  `hyprland.lua` therefore records its own chords to
  `~/.local/state/wm-binds.tsv` as it registers them, and the cheatsheet reads
  that. A bare `hl.bind()` that skips the local `bind()` helper registers fine
  and is invisible in the cheatsheet. (Omarchy solves the same problem by
  re-evaluating `hyprland.lua` in a fake-`hl` Lua sandbox —
  `omarchy-menu-keybindings`, ~500 lines — because their menu also
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

Ours keeps Omarchy's terminal, both Browser aliases (`SUPER + SHIFT + RETURN`
and `SUPER + SHIFT + B`), and editor, against their ~25 application binds. Most
of theirs are webapps launched through `omarchy-launch-webapp`, which is not
ported.

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
is authoritative. `hl.dsp.send_key_state` injects into the focused surface; it
can exercise a panel's navigation but does **not** invoke the compositor's own
keybinds, so it cannot bypass macOS to test a SUPER chord. None of this exists
on the ThinkPad, where SUPER is a real Super key.

This is also why the bar carries a menu icon at all, rather than leaving
`SUPER + SPACE` as the only way in.

## Losing the lock surface, and getting out of it

**Quickshell hot-reloads on any change to a file it has loaded** — but *not*
on an `rsync` from the laptop: rsync writes a temp file and renames it over the
target, and the watcher does not fire, so a deploy needs an explicit
`systemctl --user restart quickshell` (measured 2026-09-02). Editing a loaded
file in place on the VM does reload. Reload or restart the shell while the
session is locked and the lock client dies under a compositor lock that stays
up: Hyprland replaces
the screen with *"Oopsie daisy, it looks like you locked your screen but the
lockscreen app died"*. `qs ipc call lock status` then reports
`locked:false, secure:true` — the shell no longer owns the lock it cannot
release. Editing QML while locked is the easy way to hit this; so is
`systemctl --user restart quickshell`.

**Stop the lock happening at all while working on the shell.** The idle
service's own switch is enough, and it persists in
`~/.local/state/wily-idle.json`, so it holds across the Quickshell restarts
that this work is made of:

```sh
qs ipc call idle disable   # … and `enable` when done — it will not come back on its own
```

Do that first, then `qs ipc call lock isLocked` before any restart or rsync:
`false` is the only safe answer, and it costs one round trip against a
recovery that the user has to drive from the keyboard.

That screen names its own way out, and it works over SSH with the usual
session exports — no tty switch, no reboot:

```sh
hyprctl eval "hl.clear_crashed_lockscreen()"
```

The screen suggests `hyprctl --instance 0` and a `killall` of the lock
process; neither is needed when `HYPRLAND_INSTANCE_SIGNATURE` is exported and
the client is already gone. Verified live.

## A dark screen is DPMS, not a freeze

Hyprland ships `misc:key_press_enables_dpms` and `misc:mouse_move_enables_dpms`
**off**. With those defaults a blanked output has no way back from the
keyboard, and every path that blanks one strands the session: the idle
service's post-lock blank, a shell restart that drops the only client that
would restore it, and a fresh session inheriting a connector the previous one
left off.

It presents as a hung VM rather than a dark one. UTM reports *"Display output
is not available"*, and **`grim` never returns**, because a compositor with no
output produces no frames — that wedged `grim` then blocks Quickshell's IPC, so
the session looks doubly dead.

`hyprland.lua` turns both on, so the compositor itself wakes the output on any
input. Being compositor-side, that also covers the case Quickshell cannot: a
blank that outlives the shell that caused it. Synthetic keys do not exercise
it — `hl.dsp.send_key_state` bypasses the libinput path that arms the wake, so
this is only testable with real input at the machine.

Over SSH there is no input to give, so the manual path still matters:

```sh
pkill -x grim                             # if a screenshot is already hanging
hyprctl -j monitors | grep dpmsStatus     # false means blanked, not crashed
hyprctl dispatch 'hl.dsp.dpms("on")'
```

`hyprctl`, `qs ipc` and the clock all keep answering throughout — check them
before concluding the VM is gone.

## Starting and stopping the graphical session

The machine boots to a password-authenticated text console: it reaches
`graphical.target`, but without a display manager it has no graphical login.
From zsh, run `hypr`: the function in `shell/sourcing.sh` checks that UWSM may
start, then runs `uwsm start -e -D Hyprland hyprland.desktop`. The check stops
an accidental start from SSH or from an already graphical session, and requires
`graphical.target`; do not force `multi-user.target` to make the console appear.
Verified live: `hypr` enters Hyprland, and the System > Logout action runs
`uwsm stop` and returns to the same console rather than a greeter.

The Quickshell and `wily-sleep-lock` units are `wantedBy`
`wayland-session@hyprland.desktop.target` rather than `graphical-session.target`,
so they follow the compositor they belong to. Any second desktop reaching
`graphical-session.target` would otherwise stack a second bar, lock surface and
polkit agent on top of the one that session brings. Plasma 6 was that second
desktop until it was dropped; `shell/sourcing.sh` still defines a `plasma`
function, guarded on `command -v startplasma-wayland`, so it disables itself
while nothing installs Plasma.

**Those units must not be `After` `graphical-session.target`.** systemd orders
a target after every unit that is `wantedBy` it, and `graphical-session.target`
is itself ordered after `wayland-session@hyprland.desktop.target` — so an
`After` on it closes a cycle. systemd breaks the cycle by deleting the
*service's* start job, and the session then comes up with no bar, no lock and
no sleep inhibitor while `hyprctl configerrors` stays clean and the binds all
register. The only trace is in the user journal, logged against the target
rather than the unit:

```sh
journalctl --user -b -u graphical-session.target | grep -i "ordering cycle"
```

The same cycle breaks **logout**, and there it is fatal rather than silent:
`uwsm stop` — what the menu's System > Logout runs — fails with
`org.freedesktop.systemd1.TransactionOrderIsCyclic` and the session stays up,
because systemd reports `Unable to break cycle` on the stop transaction instead
of dropping a job from it. A session whose bar was revived by hand therefore
cannot be logged out of the normal way. `systemctl --user stop quickshell &&
uwsm stop` gets out of one: with the unit already stopped it is no longer part
of the transaction.

Order against `wayland-wm@hyprland.desktop.service` instead — the compositor
service both targets already follow. `systemctl --user start quickshell` by
hand still works, because with the target already active there is no cycle left
to resolve; that revives a running session but does not fix the next login.

Apply login or session-launcher changes with a boot generation and reboot rather
than restarting services in place. Quickshell remains safe to restart on its own
(`systemctl --user restart quickshell`) while iterating on QML, without touching
the compositor.

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
- **The console / session itself** — reboot after changing login or
  session-launcher configuration; see "Starting and stopping the graphical
  session" above.

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

Concretely, **`grim` sometimes never returns**, and a wedged `grim` blocks
Quickshell's IPC as well — `qs ipc call menu close` hangs behind it, which
looks like a broken shell. Always run it under `timeout`, and `pkill -9 grim`
before concluding anything about the QML. A `grim` left running also survives
to blank-screen debugging later, so check `pgrep -a grim` first.
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

Omarchy 4 "Quattro" is the model: `github.com/omacom/omarchy` (the org renamed
from `basecamp`), branch `quattro`, cloned at
`~/code/public/github.com/omarchy` — one level shallower than the rest of that
tree, so the usual `<org>/<repo>` guess misses it. Its
Quickshell tree is `shell/` (`shell.qml`, `Ui/`, `plugins/`), Hyprland config
in `config/hypr/`, and package list in `install/omarchy-base.packages`.
Approach is vendor-and-prune: port pieces across on request rather than
rewriting from scratch.

**Upstream has moved on since these pieces were ported.** Its shell is now
plugin-manifest driven: every bar widget and panel carries a `manifest.json`
under `shell/plugins/`, and the bar layout is data in
`config/omarchy/shell.json` rather than QML. Expect a wider diff than the
matching file paths suggest.

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

## How the Quickshell tree is split

Directories mirror Omarchy's `plugins/…` paths so diffs line up. What goes in
which *file* follows caelestia
(`~/code/public/github.com/caelestia-dots/shell`), which is the more useful
model here because it is far bigger than ours: 282 QML files against our 20.
Their *wiring* we do not copy — 16 of their 17 services are
`pragma Singleton`, ours are plain `Item`s instantiated in `shell.qml` and
reached through `readonly property alias`es on the root, which is what every
service here already did.

**A panel is a view. Everything that talks to a daemon or spawns a process
lives in a service.** caelestia keeps `services/Nmcli.qml` (1841 lines) and
`services/VPN.qml` (961) entirely apart from the popouts that display them.
Ours are `plugins/services/<name>/Service.qml` with a sibling
`<Name>Model.js` for pure functions, and `plugins/panels/<name>/Panel.qml` for
the view. shell.qml wires the two and both are `readonly property alias`es on
the root, so the bar reads the service directly.

Why it is worth the extra file:

- **The bar needs the state whether or not the panel exists.** `Bar.qml` binds
  `shell.networkService.icon`; before the split it reached into the panel for
  it, which only worked because shell.qml happens to instantiate every panel at
  startup.
- **Polling is gated on display, not on the panel.** A service exposes
  `property bool active` and the panel drives it with a `Binding`. The
  Processes and poll timers run only while something shows their output; the
  properties Quickshell keeps current stay live regardless. It is a plain bool
  with exactly one writer; a second consumer of the same metrics would need it
  to become a refcount.
- Panels stay readable. `plugins/panels/network/Panel.qml` went from 843 lines
  to 449.

Two rules that keep the split from eroding:

- **The `Quickshell.Networking` (or equivalent daemon) import belongs to the
  service only.** A view that reaches the daemon singleton directly is back to
  the old shape one property at a time. Where the view needs an enum name, the
  service exposes a function — `deviceTypeName(device)`, not
  `Model.deviceType(device.type, DeviceType)` in a delegate.
- **The `<Name>Model.js` beside the service is shared with the view**, and is
  the only file both import: parsing on the service side, `format*` on the
  view side, no QML types in either. It is plain enough to run under node, and
  `node NetworkModel.js` executes its `demo()` self-check — the only automated
  test any of this has.

**Where we differ from caelestia: we are keyboard-first and they are not.**
Their components carry hover states and cursor shapes; ours carry
`activeFocusOnTab`, `Keys.on*Pressed` and a border that tracks `activeFocus`
(see `Ui/Panel.qml`, which owns the focus chain and the h/j/k/l stepping). Do
not port their interaction model along with their structure — a control that
is only reachable by pointer is a bug here.

Two mechanical gotchas when adding a directory under `stow/`:

- **A new directory needs stow re-run on the VM**, not just an rsync — the
  tree is stowed with `--no-folding`, so `~/.config/quickshell/plugins/...` is
  a directory of symlinks and a path stow has never seen does not exist. It
  fails as `Ignoring unresolvable import` plus `Type X unavailable`, which
  reads like a QML error and is not one.
- **rsync does not trigger Quickshell's file watcher** (see "Losing the lock
  surface"), so a deploy needs `systemctl --user restart quickshell`.

## Linting QML and getting the LSP to attach

`qmlls`, `qmllint` and `qmltestrunner` come from the repo's devshell
(`flake.nix` `devShells.default`, entered via the root `.envrc`), on both the
Mac and the VM. `qml-lint`, `qml-test-js` and `qml-test-qml` are on that PATH;
Neovim launched from a shell in the repo gets `qmlls` on `.qml` buffers —
verified headless, `nvim-lspconfig`'s `lsp/qmlls.lua` supplying the filetypes
and `nvim-fredrik/after/lsp/qmlls.lua` the `-E`. Setup and the version story
live beside the tree they apply to, in
`stow/host/wily-vm/.config/quickshell/README.md`; the three things worth
knowing from here:

- **direnv is what delivers it, not the `nvim` and `claude` shims.** Those
  inject `~/.config/nvim-deps-path` (`nix/shared/toolchain.nix`), which has no
  Qt and sets no env; `qmlls` and `QML_IMPORT_PATH` come from
  `devShells.default` via `.envrc`, so both shims get them by inheritance when
  launched from a shell inside this repo and not otherwise. Editing the
  **stowed** `~/.config/quickshell/` path instead of the repo is therefore
  unserved — no `qmlls`, no import path. Deliberate: the Qt closure has no
  business on every host's Neovim, and the workflow is to edit in the repo and
  rsync to the VM.
- **`Ui/qmldir` exists for the tooling only.** Neither tool can resolve a
  `pragma Singleton` reached through `import "Ui" as Ui` without it, and the
  failure looks like every member of `Compositor` having vanished. A qmldir
  hides what it does not list, so a new file under `Ui/` needs a line in it.
- **Both import paths come from the flake, never from the VM and never from
  the qmlls binary's prefix.** The devshell's `QML_IMPORT_PATH` names the exact
  aarch64-linux quickshell store path the VM runs (both track the same
  `nixpkgs-unstable` input), which substitutes onto Darwin from cache.nixos.org.
  Copying `lib/qt-6/qml` off the VM by hand would work today and be silently
  stale after the next `nix flake update`. Taking Qt's builtins from
  `exepath("qmlls")` is the other trap: Mason's `qmlls` is a standalone binary
  with no Qt module directory, so `import QtQuick` fails whenever it wins the
  PATH.

## Reaching Quickshell from a keybind

`qs ipc call menu toggle` — the `IpcHandler { target = "menu" }` in
`shell.qml`. No config selection is needed: `~/.config/quickshell/shell.qml`
registers as the `default` config and `qs ipc` picks the instance on the
current display. Every future panel reuses this; the bar icon instead calls
`menu.toggle()` directly, being the same process.

The Omarchy-shaped services use their upstream-compatible targets too:
`notifications` (`showHistory`, `toggleHistory`, `toggleDnd`, `dismissOne`,
`dismissAll`, `invokeLast`), `lock` (`lock`, `status`, `isLocked`) and `idle`
(`enable`, `disable`, `toggle`, `status`). The local panels are `display`,
`network` and `audio` (each `open`, `close`, `toggle`, `status`, and audio also
`up`, `down`, `mute`, `setVolume`), deliberately bare like the other local targets rather than upstream's `omarchy.monitor` and
`omarchy.network`. From SSH they need the live-session `XDG_RUNTIME_DIR` and
`WAYLAND_DISPLAY` export from "Driving it over SSH".

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
opens gives an empty list on the first open after a restart. Like Omarchy's
`AppLibrary`, it watches that model: an installed app with a conventional
`.desktop` entry needs no launcher-menu change. Add a direct app keybind only
when it has a counterpart in Omarchy's `default/hypr/bindings/applications.lua`;
retain the chord and label, and launch it with `uwsm-app -- <desktop-id>` so it
gets its own app scope.

## The bar: every slot is a button

There is no separate "indicator" kind. A bar slot is a `BarButton`, its glyph
carries its own state, and clicking it changes that state or opens the panel
that owns it. The bell is the pattern: DND does not add an icon, it turns
`󰂚` into `󰂛`. That costs no extra slot, and the thing that
shows you the state is also the thing that changes it.

A state whose owner has no bar button gets a button that is **only visible
while the state is non-default** — `BarButton` gives its 28px slot back when
`visible` is false, so it costs nothing while it is off. It stays clickable,
and clicking it restores the default. The idle-lock coffee (`󰅶`) is
the first of these.

- **A slot is earned by a state that persists and is otherwise invisible.**
  Idle-disable lives in `~/.local/state/wily-idle.json` and survives reboots;
  DND persists the same way. Both are things you can leave on for days without
  a reason to remember. A state that is transient, or already visible in the
  panel performing it (`busy` during a Wi-Fi action, `scaleChanging`), does not
  get one.
- **Conditional buttons grow inward, off the innermost fixed button's `left`.**
  The always-visible buttons stay pinned to the right edge, so nothing moves
  under the pointer when an indicator appears or goes away. Putting them
  outboard instead shifts every icon each time one toggles, which defeats the
  fixed 28px slot the buttons already go to some trouble to keep.
- **Two navigation models, and the panel picks one.** `keyNavigation: true`
  walks Qt's focus chain and is right for a panel that is rows of buttons
  (display, network, notifications). A panel with a continuous control keeps
  its own cursor instead — the audio panel holds `cursor`, `-1` being the
  slider row, takes the keys on a focused `Item` of its own the way the
  wallpaper picker does, and needs no change to `Ui/Panel.qml`. Hover moves
  that cursor and the visuals read the cursor, never `containsMouse`, so only
  one highlight is ever on screen. `h`/`l` adjusts on the slider row and is a
  deliberate no-op on a device row: moving the output volume from a row that
  is not the slider surprises people (Omarchy's `adjustVolume` says the same).
- **Every bar action is also a launcher entry**, and the launcher is the
  canonical one. The bar is a shortcut to it, never the only way in — this
  shell is keyboard-first, and a mouse-only affordance is a missing feature.
  Panels reached from the bar set `keyNavigation` for the same reason.
  **Upstream is no help here** — their toast stack is `keyboardFocus: None` and
  they have no history panel at all, so there is nothing of theirs to diff
  against.
- **A button whose actions are already a launcher level opens that level**
  rather than growing a panel. The power button is `menu.toggleLevel("system")`
  — the level already holds lock, keep-awake, suspend, logout, reboot and
  shutdown, `SUPER + ESCAPE` already goes there, and the menu already has
  search and list navigation. A panel is for state a list cannot show: a
  toggle grid, live readouts, per-row controls. Upstream agrees on where those
  actions live: their `system` level is aliased `power-menu` in
  `default/omarchy/omarchy-menu.jsonc`. They just have no bar button for it.

  **`omarchy.power` is not that.** Their power *widget* is battery and power
  profile — charge, cycles, time left, `omarchy-powerprofiles-set` — in a
  536-line panel worth porting when the ThinkPad arrives with a battery. It
  will want the far-right slot, which is where our power button now is; decide
  then which of the two moves.

### How Omarchy does the same thing

Compared after ours was built; it converges more than it diverges.

- **`shell/plugins/bar/indicators/StayAwake.qml` is our coffee**, down to the
  `󰅶` glyph and click-to-restore. `Dnd.qml` is the same shape. Their
  `Ui/BarIndicator.qml` is a `BarIconButton` with `active`, `activeText` /
  `inactiveText` and `onPressed` — an indicator is a button there too.
- **They hit the same shifting problem and solved it the same direction.**
  `Indicators.qml:145` — *"The active block sits closest to the clock, so
  newcomers go on the far side of it. Appending would shove everything already
  showing sideways."*
- **They reveal inactive indicators instead of hiding them.** Ours vanish;
  theirs go to opacity 0, then 0.45 on hovering the cluster (`concealed`,
  `dimmed`, `revealInactiveIndicators`), with an `alwaysShow` setting. So their
  bar can turn Stay Awake *on*, and ours can only turn it off — discovery lives
  in the launcher here. Deliberate: a hover-reveal is invisible to the keyboard,
  and the launcher already lists every one of these.
- **Their indicators sit in the centre section, left of the clock**
  (`config/omarchy/shell.json`), because their bar layout is data and the right
  side is full of widgets. Ours is one anchored chain, so inward off the
  innermost fixed button is the same position by a different route.
- **There is no bell in their bar at all** — DND is only an indicator, and both
  its states draw `󰂛`, separated by opacity. Ours puts the state on the
  bell that opens the history, so one slot does both jobs and reads without a
  hover. Theirs is the more uniform: every state lives in the one cluster.

## The menu

One panel with a level stack, in Omarchy's `omarchy-menu.jsonc` shape: dotted
ids imply the hierarchy, so `style.theme.dark` is a child of `style.theme` and
no nesting syntax is needed. Kind is inferred — an entry with an `action`
fires, one with children descends, one with a `provider` fills its level from
elsewhere (only `apps` so far, from `DesktopEntries`). Their `Menu.qml` plus
`MenuModel.js` is ~2000 lines of jsonc parsing, plugin manifests and provider
indirection; this is ~25 entries in a QML object literal and needs none of it.

Menu rows carry a Nerd Font glyph; app rows carry the desktop entry's icon,
resolved with `Quickshell.iconPath(name, true)` and drawn as an `Image` whose
`sourceSize` is multiplied by `Screen.devicePixelRatio` — a logical-size decode
leaves PNG icons blurry. **Only `hicolor` resolves here.** No Qt platform theme
is loaded, so `QIcon` has no theme name and any themed lookup
(`applications-system`, `application-x-executable`) comes back empty no matter
what the dconf or GTK `icon-theme` says — that setting was a stale `breeze` from
Plasma, now `Adwaita`, and it changed nothing. `QT_QPA_PLATFORMTHEME=gnome` does
make Qt read gsettings and resolve them, at the price of Qt also taking its
fonts and dialogs from GNOME; the glyph fallback on an unresolved row costs
nothing and also covers icons no theme will ever have. Omarchy instead keeps a
bash-built index of every `apps/`+`devices/` icon, rescanned on a debounce
(`services/AppLibrary.qml:122`), because Qt's icon cache never re-scans after a
post-start install and an unconstrained lookup can resolve "zoom" to an action
icon. Not ported: here a new app arrives with a rebuild, which restarts the
shell anyway.

`enabled: false` lists a row with nothing behind it yet: dim, skipped by the
arrow keys and inert on Enter, rather than absent — so what is still missing
stays visible while browsing. Those are the rows to edit when the feature lands.
They are not the record of what is missing, though: this file is, so that a row
can be deleted without losing the note. Still dim: Learn › Hyprland and NixOS,
and Trigger › Emoji / Color picker / Share.

Typing filters the whole subtree below the current level, not just the rows on
screen, which is what Omarchy's `rebuildDisplay` does — so `ghostty` or `lock`
from the root reaches the action without walking down to it. A hit deeper than
one level carries its path (`Style › Theme`) and sorts after the direct
children. Pruned from theirs: the divider between the two groups and the
`searchScore` tier system, ~20 lines that mostly re-rank app rows against menu
rows. Apps are ordinary tree items upstream; here they are the one provider
joined into a root search — the keybinding sheet's ~100 chord rows would swamp
it, and upstream never faces that because their Keybindings row is an external
`omarchy-menu-keybindings` action rather than tree items. Dim rows drop out of
search results, as they do upstream: there is nothing behind them to reach.

**System › Close window** is a deliberate UTM accessibility divergence:
macOS consumes the upstream `SUPER + W` and `SUPER + Q` chords before the VM
sees them. Omarchy has only those direct binds; this row runs the same
`hl.dsp.window.close()` dispatcher after the menu hides.

Reachable as `qs ipc call menu toggle|open|close` and `level <id>`; bound to
`SUPER + SPACE`, with `SUPER + ALT + SPACE` (apps), `SUPER + ESCAPE` (system),
`SUPER + K` (keybindings) and `SUPER + SHIFT + CTRL + SPACE` (theme) opening a
level directly.

The keybinding sheet is the `binds` provider, reading
`~/.local/state/wm-binds.tsv` through a `FileView` with `watchChanges`, so a
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

## The tray

`Quickshell.Services.SystemTray` supplies the items; `plugins/bar/widgets/`
holds `Tray.qml` and a `TrayModel.js` for the string handling, and
`plugins/panels/tray/Panel.qml` draws an item's own menu. The app owns every
row — label, nesting, what a click does — and we own only how it is drawn.

- **The rows are drawn here, not through `QsMenuEntry.display()`.** That
  renders a *platform* menu, which Quickshell refuses unless the shell root
  sets `//@ pragma UseQApplication`; `shell.qml` does not, so `display()` is a
  silent no-op and an app whose whole UI is submenus would be unusable.
  Omarchy hit this and documents it at `widgets/Tray.qml:36`. Drawing them
  also means they get the palette and `Ui/Panel`'s keyboard chain for free.
- **One live `QsMenuOpener` per level.** A child entry is owned by its parent
  opener's children model, so collapsing the stack to a single opener destroys
  the entry being displayed and the submenu comes up empty. Tear down deepest
  first, and clear the reactive stack before destroying anything.
- **Never hand a theme name to the `image://icon/` provider.** It looks the
  theme up at the exact pixel size asked for and does not scale: nm-applet's
  `nm-device-wired` exists at 16 and not at 20, so the same icon rendered in
  the 16px bar slot and failed in the launcher's 20px one. **It answers a miss
  with a magenta placeholder at `Image.Ready`, not `Image.Error`**, so
  `visible: status === Image.Ready` — which Omarchy, caelestia and Dank all
  use — cannot tell a missing icon from a real one, and the failure is a
  magenta checkerboard in the bar rather than a fallback. Resolve the name with
  `Quickshell.iconPath(name, true)` and let `Image` scale the file; an
  unresolvable name returns `""`, which falls back to the glyph.
  `TrayModel.themeIconName()` is what decides a url is a plain theme lookup —
  a `?path=` query means the app ships its icon outside any theme and
  Quickshell searches that directory, so the name alone would not resolve and
  must be left alone.
- **Sorted by `id`, growing inward from the coffee.** Registration order is a
  startup race between apps, so an unsorted tray puts a given icon in a
  different slot on each boot. Growing inward keeps the fixed right-edge
  buttons still when an app registers or exits.
- **`status` is the only state the protocol maintains for us.** `Passive` and
  `Active` both show — most apps set `Passive` once and never touch it again,
  so hiding those would hide Signal permanently. `NeedsAttention` takes
  `palette.sel`, which should be the unread-badge behaviour without a second
  slot. **Unverified** — nm-applet never sets it, and Signal ships
  `"system-tray-setting": "DoNotUseSystemTray"` in
  `~/.config/Signal/ephemeral.json`, so it has never registered a tray item on
  this VM at all. Flip that (Settings → General → minimize to system tray) and
  restart Signal before trusting the sentence above.
- **`qs ipc call tray list` / `menu <id>` / `close`.** The bar icon is a
  mouse-only affordance; this is the path the launcher's Tray level uses, and
  the only way to drive the menu from a script or a test.

Not ported, all of it deliberate: pin/hide buckets and their persisted config,
the hover-reveal drawer, and per-app icon overrides. Omarchy's `TrayModel.js`
exists only to hide LocalSend and Dropbox items it replaces with its own
widgets, neither of which is installed here.

**Our submenu handling is not the one caelestia uses, and that was checked.**
Theirs is a `StackView` of `SubMenu` items
(`modules/bar/popouts/TrayMenu.qml`), ours an array of openers with explicit
`destroy()`. Both enforce the same one-opener-per-level invariant; theirs gets
it from `StackView.onRemoved`, and is about ten lines shorter for it. It is not
the simpler file overall — 228 lines against our 241, and those 228 render no
checkboxes or radio buttons (`checkState` and `buttonType` appear nowhere in
their tray) and bind no keys. The one thing worth taking is their **Back row**,
a `chevron_left` at the foot of a submenu; ours has Backspace and nothing
visible.

**Icon recolouring is the one thing all three upstreams have and we do not.**
caelestia has `Config.bar.tray.recolour` over a `ColouredIcon`, Dank has
`trayIconTintEnabled` over a `MultiEffect` with saturation and colorization.
Ours renders app icons at their own colours, which is the only place the bar
is not monochrome. Deferred rather than rejected — worth revisiting once
there are several real icons side by side to judge.

**A tray producer for testing, with nothing to install:**

```sh
nix run nixpkgs#networkmanagerapplet -- --indicator
```

That is the whole recipe — no `XDG_DATA_DIRS` juggling. The nixpkgs wrapper
already puts the applet's own `share` at the front of `XDG_DATA_DIRS`, so
`nm-device-wired` resolves and the bar icon renders. (Verified 2026-09-05 by
reading `/proc/<pid>/environ` of a plainly-`nix run` applet.)

Kill it with `pkill -x nm-applet` — **not** `pkill -f`, which also matches the
SSH command string carrying the pattern and kills the invoking shell. `pgrep
-x nm-applet` is unreliable here for reasons not chased down; `ps -eo pid,args
| awk '/[n]m-applet --indicator/{print $1}'` is what actually finds it.

## Wallpapers

Images live in `~/Pictures/wallpapers` — deliberately outside the repo, so no
binaries get committed. The shell scans it recursively (`find`,
png/jpg/jpeg/webp), so subfolders are for tidiness only, not meaning. The pick
is **per mode**: `~/.local/state/wallpaper-dark` and `-light`, each a plain
path, so flipping light/dark also swaps the picture and each side remembers its
own. A mode with no pick yet shows the gradient. `SUPER + CTRL + SPACE` (or the
menu's Style › Background) opens the picker; `qs ipc call wallpaper` also takes
`open/close/toggle`, `set <path>`, and `rescan` after adding files.

webp works, but only because `desktop.nix` sets `QT_PLUGIN_PATH` to
`qt6.qtimageformats` on the Quickshell unit — the package ships no webp
decoder, and without it a webp wallpaper silently falls back to the gradient.
The wrapper prefixes its own plugin paths, so setting the variable does not
displace them.

## Workspaces

The top bar's `plugins/bar/widgets/Workspaces.qml` is a pared-down port of
Omarchy's file at the same path. It shows 1–5 even when empty, adds existing
normal workspaces through 10, dims empty ones, and outlines the focused one (the
digit stays visible, unlike Omarchy's glyph substitution). Clicking an indicator
dispatches the same action as `SUPER + 1` through `SUPER + 0`.

The data source is per compositor and lives beside it —
`WorkspacesHyprland.qml` reads Quickshell's `Hyprland` singleton rather than
polling `hyprctl`, `WorkspacesNiri.qml` reads niri's event stream. See "Running
under niri" for why the choice is a URL and not a type.

`hl.animation({ leaf = "workspaces", enabled = false })` is Omarchy's exact
setting for instant workspace changes. It is deliberately a workspace leaf,
not global animation disablement, so window open/close animations stay on.

New tiled clients use `dwindle.force_split = 2`, Hyprland's right/bottom
insertion direction and the same setting Omarchy uses. Its `preserve_split =
true` is deliberately not ported: it controls manual split resizing, not new
client placement.

The launcher mark is Omarchy's private `omarchy` font at U+E900, vendored with
its upstream MIT licence under `stow/host/wily-vm/.local/share/fonts/omarchy/`.
Nerd Fonts do not carry it. After a fresh stow run, call `fc-cache -f` and
restart Quickshell to make a new user font available to the running shell.

## Display

`plugins/panels/monitor/Panel.qml` is the one-scanout subset of Omarchy's
panel: light/dark, nightlight, the focused output's clean scale presets and
text size work; Brightness and Displays are visibly dim because this VM has no
backlight and one scanout. It opens from the `󰍹` bar button, Setup › Display,
or `SUPER + CTRL + D` / `qs ipc call display toggle`. The bar's theme button is
gone, so theme and nightlight now live together with their display-adjacent
controls.

Scale applies the output's current mode with `hyprctl eval`, then persists to
the Stow-linked `~/.config/hypr/monitors.lua` (under niri:
`niri msg output` and `~/.config/niri/config.kdl`). **Use
`sed -i --follow-symlinks` there.** Plain GNU `sed -i` replaces the link with a
regular file, which Stow cannot own on the next activation; following it keeps
the relative link and updates its repository target. Shared `hyprland.lua`
loads the optional file and otherwise defaults to 1, so rpi5-homelab remains
safe without a host package. `GDK_SCALE` is persisted beside the compositor
scale but takes effect only on the next compositor start.

Text size writes dconf's `text-scaling-factor`, which GTK consumes directly;
the bar (buttons, clock and workspaces) watches the same key and scales with
it. The panel offers 80–150%. It deliberately leaves Ghostty alone: its config
is shared with macOS through `stow/shared`, so rewriting it would dirty the
repo and make a Linux setting follow the user to the Mac.

Verified live under Hyprland: `qs ipc call display open` identifies Virtual-1
at 1280×800;
the text-scale watch reports a 1.25 dconf write immediately; and applying 1.6,
rewriting the host file, then `hyprctl reload` retains 1.6. The test resets the
VM and host file to scale/GDK scale 1 afterwards.

## Network

`plugins/services/network/Service.qml` plus `plugins/panels/network/Panel.qml`
are the NixOS-sized port of Omarchy's network panel — data and view, per "How
the Quickshell tree is split". Together they list NetworkManager devices,
their state and global IPv4 address; scan Wi-Fi; connect (with a passphrase
prompt), disconnect and forget saved networks; and toggle the radio.
`NetworkDevice.address` is the MAC address, not an IP, so the service obtains
addresses from `ip -j -4 address`.
Wi-Fi objects are reduced to plain rows before delegates receive them, because
the scan model is live and its objects can disappear during a refresh.

The Connection grid matches Omarchy's visible metrics: internet latency and
packet loss, receive/send rates, transferred totals, IP and gateway. Every
1.5s while open, `ip route get 1.1.1.1` selects the active interface and
source/gateway, `ip -s link` supplies its 64-bit byte counters, and a
`ping -I <interface> 1.1.1.1` supplies one sample. Rates are counter deltas;
the last 24 ping samples are kept and the displayed latency averages the most
recent five. `iproute2` and `iputils` are explicit `desktop.nix` dependencies,
not accidental base-system tools.

It opens from its right-side bar icon (the order is audio, network, display,
bell, power, with conditional indicators inboard of audio), Setup › Network, or
`SUPER + CTRL + W` / `qs ipc call network toggle`.
The scanner and the metric polling run only while the panel is open, through
the service's `active` property; the bar icon reads the service directly and
needs neither. Ping shows Timeout on this VM and always will — UTM's NAT drops
ICMP to 1.1.1.1, which `ping -c 1 -W 1 1.1.1.1` confirms from a plain shell.
The wired icon wins when both transports are connected, matching the default
route. The VM verifies the
wired path end-to-end: `enp0s1` reports Connected with its DHCP address, the
panel renders it, the bar shows the ethernet icon, metrics update, and both IPC
and the menu open the panel. The bind is registered, but its physical
invocation cannot be tested from the Mac; see "From a Mac, macOS eats the
SUPER binds".

Wi-Fi scanning, signal, radio state, passphrase entry, connect, disconnect and
forget are untested until the ThinkPad: the VM has no radio. **Revisit the
remaining Omarchy network functionality on real hardware** before deciding
what else belongs here; its scripts are not a reason to rule out a port.

## Audio

`plugins/panels/audio/Panel.qml` is output volume, mute and the default-sink
pick, on `Quickshell.Services.Pipewire` — no `wpctl` subprocess. It opens from
the `󰕾` bar button, Setup › Audio, or `SUPER + CTRL + A` /
`qs ipc call audio toggle`, and the bar glyph carries mute (`󰝟`) and the
level, so no OSD exists: volume feedback is that you can hear it.

- **`PwObjectTracker` is required.** Node properties are not bound until the
  node is tracked; without it `audio.volume` reads 0 and never updates. The
  tracker binds to the whole sink list unconditionally, so the bar icon and the
  media keys work with the panel closed.
- Volume steps 5% per key or IPC call; `setVolume` takes a percent.
- Media keys are bound in both compositors to the same IPC calls, and both
  reach the shell while the screen is locked (Hyprland `{ locked = true,
  repeating = true }`, niri `allow-when-locked=true`).
- **Deliberately absent:** the per-app stream mixer (the bulk of Omarchy's
  1248-line panel) and the input/mic section. `Pipewire.defaultAudioSource` is
  ~20 lines away when a mic-mute key or a call habit makes it real.

`services.pipewire` with `alsa` and `pulse` is declared in `desktop.nix`,
alongside `security.rtkit`.

Verified on the VM against `wpctl get-volume @DEFAULT_AUDIO_SINK@`: IPC
up/down/mute/setVolume, and `h`/`l`/`m`/`j` from the keyboard. The Hyprland
media binds are written but unexercised — the VM session runs niri, whose own
binds passed `niri validate` and call the IPC verified above.

## Light and dark

One key drives everything: `/org/gnome/desktop/interface/color-scheme` in
dconf. `xdg-desktop-portal-gtk` republishes it as the portal's
`org.freedesktop.appearance color-scheme`, Ghostty switches between the
`zenbones_dark`/`zenbones_light` themes named in its config, and Neovim follows
the terminal over OSC 11 (`OSC11.nvim`). Verified live — no restart of either.
The same mechanism macOS drives from its system appearance, which is why the
Ghostty and Neovim configs need nothing platform-specific.

The Display panel's Light / Dark row writes that key plus `gtk-theme`
(`Adwaita`/`Adwaita-dark`, what Omarchy's `omarchy-theme-set-gnome` does); the
compatibility IPC target still answers `qs ipc call theme toggle|dark|light`.
It *watches* the key with a long-running `dconf watch` rather than trusting its
own writes, so a `dconf write` from anywhere else moves the panel state too.
dconf persists, so the mode survives a reboot for free.

Bar and menu colours are the zenbones palettes, lifted from
`stow/shared/.config/ghostty/themes/zenbones_{dark,light}` so the bar and the
terminal are literally the same colours. `gsettings` is not installed; `dconf`
is, and writes the same database.

`\uf185` renders as a cog in JetBrains Mono Nerd Font, not a sun; `\uf522` is
the one that reads as a sun at 14px. The bar's icon buttons use fixed 28×24px
slots and centre the glyph's tight painted bounds rather than its font advance;
otherwise the narrower moon makes the notification button jump on a theme
toggle. This is the same principle as Omarchy's `BarIconButton` (27px slot,
16px optical canvas, `OpticalGlyph` tight-bound centring).

## Nightlight

`plugins/services/nightlight/` is Omarchy's service at the same path, plus the
one thing they do not have: a solar schedule. **hyprsunset has no
sunrise/sunset support** — from `hyprwm/hyprsunset`'s `ConfigManager.cpp` the
whole config surface is `max-gamma` plus
`profile { time = HH:MM, temperature, gamma, identity }`, and its IPC is
`temperature|gamma|identity|profile|reset|get`. No geolocation, no solar
keyword. So `hyprsunset.conf` carries only Omarchy's inert `identity` profile
(without a profile it applies a tint of its own) and the schedule lives in QML.

`mode` is `auto`, `on` or `off`. A manual toggle pins the temperature until the
next sunrise or sunset and then reverts to `auto`, which is what Night Shift
does; the service records the solar period the override was made in and expires
it when that changes. 4000K/6500K are Omarchy's pair, kept identical so a
temperature set from either side reads back the same on the other.

A **one-minute tick** carries the schedule, and it is deliberately doing three
jobs at once: crossing the solar boundary, expiring a stale override, and
re-asserting the temperature. That last one is why the morning `identity`
profile needs no special handling — it fires at 07:00, clobbers the runtime
temperature, and the next tick puts it back.

**The tick probes before it decides.** Reconciling against the previous
minute's reading makes an outside change take two ticks to correct, which is
long enough to look like the schedule not working at all; caught live. Only a
tick reconciles, though — the probe that follows every apply must not turn a
temperature that will not stick into an apply loop, which is what the
`reconciling` flag is for. Upstream's ten-attempt retry (from
`bin/omarchy-toggle-nightlight`, for the fresh daemon overwriting the
temperature at the end of its boot) is kept, inside the apply command rather
than in QML.

**Applies are serialized, and dropping that guard costs a crash rather than a
race on the temperature.** The apply command starts hyprsunset when none is
running, and `pgrep -x hyprsunset || launch` is not atomic: two applies
overlapping while it comes up each launch one, and the loser exits with
*"A CTM manager is already running"* and a stack trace in the journal. Seen
live. Upstream's `hasPendingTemperature`/`runApply` pair is what prevents it.

Location comes from the **system timezone**, so it follows the laptop with no
network, no geoclue and nothing to configure: `timedatectl show -p Timezone`
gives `Europe/Stockholm` and `/etc/zoneinfo/zone.tab` gives its ISO 6709
coordinates. **Read `zone.tab`, not `zone1970.tab`** — tzdata's 2022
consolidation merged Sweden into `Europe/Berlin`, so the newer table no longer
lists the name `timedatectl` reports. The coordinates are the zone's principal
city, so Malmo is around fifteen minutes off Stockholm's winter sunset;
acceptable for a blue-light filter, and the `latitude`/`longitude` properties
override it. `services.automatic-timezoned` was considered and rejected: it
drives geoclue2, whose Wi-Fi backend depended on the Mozilla Location Service,
retired in 2024.

`NightlightModel.js` holds the NOAA sunrise equation and a `demo()` self-check
runnable as `node NightlightModel.js` — which is how upstream tests its
`*Model.js` files, and which caught a sign error on longitude that put sunrise
2h25m out. Polar day and night have no solution to that equation, so
`solarPeriod` falls back to the hemisphere and the month there.

Under niri the daemon is wl-gammarelay-rs instead, and only the daemon
changes; see "Running under niri".

Reachable as `qs ipc call nightlight toggle|enable|disable|auto|status` and
bound to `SUPER + CTRL + N`. `enable`/`disable` rather than `on`/`off`, which
is what upstream's handler and our idle service both call these.

## Notifications, lock, idle and polkit

Quickshell 0.3.0 on this VM supplies `NotificationServer`, `PolkitAgent`,
`PamContext`, `WlSessionLock` and `IdleMonitor`, so this deliberately follows
Omarchy Quattro's native architecture rather than installing `hyprlock`,
`hypridle` or `hyprpolkitagent`. The files live under the matching
`stow/host/wily-vm/.config/quickshell/plugins/{notifications,lock,polkit,services/idle}`
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
  keystroke unable to bring the screen back.

  **A Quickshell restart while the output is blanked desyncs it the same
  way**, and this is the likely one: the new instance starts with
  `blanked = false` against hardware that is off, so no keystroke ever turns
  the screen back on. It presents as a dead VM — black screen, no lock
  surface, no way to reach the console — and it is not: `hyprctl -j monitors`
  reports `dpmsStatus: false` while `qs ipc call lock status` reports
  `locked:false`. Recover over SSH with `hyprctl dispatch 'hl.dsp.dpms("on")'`.
  Iterating on QML over SSH walks into this, because SSH polling does not
  reset the idle timer that blanked the output in the first place. Do not
  replace it with `security.pam.services`: on this aarch64 nixpkgs revision the
  PAM renderer evaluates disabled Howdy/Kanidm module paths and fails before it
  can render a custom service. Setting options on services that already exist is
  unaffected -- `security.pam.services.login.enableGnomeKeyring` evaluates, and
  `services.gnome.gnome-keyring.enable` renders its own entries into
  `/etc/pam.d/login` -- so the limit is defining a *new* service, not touching
  the option tree. `IdleMonitor` honours inhibitors, locks at five
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
`SUPER + CTRL + I` (toggle idle locking), `SUPER + CTRL + L` (lock), and
`SUPER + CTRL + N` (toggle nightlight).

## System settings we should not build

The long tail — printers, pairing, VPN and 802.1X profiles, GTK theming — is
not worth a panel each. There is also no hub to reach for: GNOME's
control-center and KDE's systemsettings delegate their interesting panels to
Mutter and KWin over D-Bus, so on either compositor here half of them grey out
or crash. The ecosystem answer is one small GUI per domain, launched from the
menu, which is what Omarchy does too.

None of these are installed yet. All exist in nixpkgs on aarch64 (checked, not
run), so adding one is a `host.extraSystemPackages` entry plus a menu row
under a new `System` level.

| Domain | Tool | Notes |
| --- | --- | --- |
| Printers | `services.printing.enable`, CUPS UI at `localhost:631` | no GUI package at all; with avahi, IPP-Everywhere printers self-configure. `system-config-printer` if a GTK dialog is wanted |
| Bluetooth | `blueman` or `overskride` | ships the pairing agent — the single largest thing not worth reimplementing |
| Wi-Fi, VPN, 802.1X | `nm-connection-editor` (`networkmanagerapplet`) | the tail our network panel should not grow into |
| Audio routing | `pwvucontrol` | per-stream sinks, card profiles, ports |
| GTK theme, cursor, font | `nwg-look` | writes the gsettings the portal already reads; see "Light and dark" |
| Display arrangement | `nwg-displays` | Hyprland and sway only, and it writes its own `monitors.conf` — a second writer against `hypr/monitors.lua`. Probably still not worth it |
| Per-monitor hotplug profiles | `shikane` | only if the ThinkPad's dock/undock needs them |
| Keyboard layout, input rules | none exists | compositor config file, by hand |

**The Display panel stays ours regardless.** niri is not a
wlr-output-management server, so `nwg-displays` and `wdisplays` cannot see it
at all, and the panel already writes `config.kdl` and `hypr/monitors.lua` in
place.

The split to hold to: a panel for what gets touched from the bar daily, an
external app for what gets touched twice a year.

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

- **What Plasma 6 was silently supplying.** Its NixOS module enabled
  `services.upower`, `services.power-profiles-daemon`, `services.fwupd`,
  `services.udisks2`, `services.accounts-daemon`, `services.geoclue2` and
  `qt.enable` as defaults, none of them declared here. Dropping the module
  replaced only PipeWire, so all of those are now off — confirmed by
  evaluating the config after the change. A battery widget wants `upower`,
  the power panel's profiles want `power-profiles-daemon`, and firmware
  updates want `fwupd`; declare each when the ThinkPad actually needs it
  rather than restoring the whole set here, where there is no battery and no
  firmware to flash. Portals and XWayland were never Plasma's —
  `programs.hyprland` sets both, and `xdg.portal.extraPortals` still
  evaluates to the hyprland and gtk portals with Plasma gone.

## Next steps

The plumbing is in place — portals (`xdg-desktop-portal` + `-hyprland` +
`-gtk`), pipewire/wireplumber and NetworkManager are all running, and the menu
now covers apps, wallpaper, theme, nightlight, screenshots, power, notifications
and the keybinding sheet. The dim rows in it are the shortest list of what is
still missing.

1. **Validate the network panel's Wi-Fi path on the ThinkPad** — scanning,
   signal strength, radio state, passphrase entry, connect, disconnect and
   forget all need a real radio.
2. **Exercise the network panel's keyboard chain on the ThinkPad** — the VM
   has no Wi-Fi adapter, so its Wi-Fi toggle, Scan and every per-network
   button are hidden. Its focus chain holds nothing but Pin, which comes from
   `Ui/Panel.qml`, so **no line of that panel's own keyboard code has ever
   run** — not the `ActionButton` focus border, not the `focusedItem`
   scroll-into-view block, which has never once been entered. Only the
   Display panel's traversal is verified live.

### Bar widgets not yet ported

Upstream's default bar is data, in `config/omarchy/shell.json`: left `menu`,
`workspaces`; centre `indicators`, `clock`, `keyboard-layout`, `weather`,
`system-update`; right `tray`, `agents`, `bluetooth`, `network`, `audio`,
`monitor`, `power`. Ours is menu, workspaces, clock, tray, audio, network,
display, bell, power.
None of the below is blocked on the two items above — pick freely.

Runnable on the VM today:

- **`omarchy.indicators`** (`widgets/Indicators.qml` plus `indicators/Dnd`,
  `NightLight`, `StayAwake`, `Reminder`, `ScreenRecording`, `Dictation`) —
  `Dnd` and `StayAwake` are covered in our own idiom; see "The bar: every slot
  is a button" for what we took and what we left. What is left here is
  `NightLight` (state exists, no bar affordance), the three we have no service
  for, and their hover-reveal of inactive indicators.
- **`omarchy.audio`'s per-app mixer and input section** — the master slider and
  output-device picker are ported; see "Audio".
- **`omarchy.microphone`** (`widgets/Microphone.qml`) — mute toggle, source
  volume on scroll.
- **`omarchy.media`** (`plugins/services/media/`) — MPRIS track and cover art.
- **`omarchy.keyboard-layout`** — dim until `kb_layout = "us,se"` lands; the
  two are one task.
- **The clock popup** — ours is a bare `Text`. Upstream adds a month grid, ISO
  week numbers, format cycling and a timezone picker.
- **`omarchy.weather`** (`panels/weather/`), **`omarchy.tailscale`**,
  **`omarchy.agents`** — network only, nothing hardware-blocked.
- **The bar's own configurability** — edge position, transparency,
  drag-to-reorder, the `shell.json` layout. Ours is a fixed anchored layout.

Hardware-blocked, so ThinkPad work:

- **`omarchy.bluetooth`** (`panels/bluetooth/Panel.qml`, on
  `Quickshell.Bluetooth`) — UTM passes no radio through, and
  `hardware.bluetooth.enable` is set nowhere in `nix/`, so there is no
  `bluetoothd` to talk to either. Same shape as the Wi-Fi panel: writable
  blind, unverifiable here.
- **`omarchy.power`** (`panels/power/`, `services/battery/`) — no battery.
- **`omarchy.monitor`'s brightness half** — already dim, no backlight device.

`omarchy.system-update` cannot port: it is pacman, same reason as the menu's
Install / Remove / Update rows.

Beyond the bar, also unported: `plugins/osd`, `clipboard` (wants
`wl-clipboard`), `emojis`, `image-picker`, `reminders`, and the `wifiqr`,
`dropbox`, `speedtest` and `disk-speedtest` panels.

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
- **`loginctl lock-session` reported success and did nothing under the former
  greetd setup.** Nothing then listened for logind's `Lock`/`Unlock` signals:
  the call returned cleanly while `lock status` still reported `locked:false`.
  Omarchy is the same (`grep -rniE "login1|loginctl" shell/` is empty; their
  entry point is `bin/omarchy-system-lock`, which calls
  `omarchy-shell lock lock`, the same IPC path as ours), so it was left alone
  deliberately rather than fixed into a divergence. A console login adds no
  listener, but re-verify that observation after the terminal-first session has
  been exercised before relying on it for ThinkPad lid handling.

  **Read this before touching lid handling on the ThinkPad.** The lid is safe
  under `HandleLidSwitch=suspend`, which is what logind actually reports here
  (`busctl get-property org.freedesktop.login1 /org/freedesktop/login1\
  org.freedesktop.login1.Manager HandleLidSwitch` → `s
  "suspend"`) — the lid suspends, which raises `PrepareForSleep`, which `wily-sleep-lock` already handles. Setting `HandleLidSwitch=lock` instead — lid shut, machine awake, clamshell on an external monitor — is the one configuration that breaks: logind emits `Lock`, nobody listens, and the machine sits unlocked with the lid closed. Omarchy covers that case with `bin/omarchy-system-lid-close`,
  not by subscribing to the signal.
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
- **Nightlight is verified live except for two things.** Confirmed on the VM:
  the location resolving to Stockholm from the timezone, `toggle`/`enable`/
  `disable`/`auto` round-tripping through `hyprctl hyprsunset temperature`, a
  manual override surviving the ticks, and an outside `hyprctl hyprsunset
  temperature 4000` being healed back inside one tick. Not covered: the
  override expiring at a real sunrise or sunset (the boundary itself is under
  the `node` self-check, the expiry is not). The auto-launch **is** verified
  since the rebuild: `pkill -x hyprsunset` followed by a toggle brings it back
  in its own `app-Hyprland-hyprsunset` scope, and four applies fired back to
  back leave exactly one process and no crash.
- Keyboard layout is `us`. Swedish is wanted eventually as a second layout,
  but not yet — `kb_layout = "us,se"` with a `grp:` toggle in `kb_options`
  when the time comes.
- No OSD yet.
- Two packages the Omarchy keymap and menu assume are not installed in
  `desktop.nix`: `wl-clipboard` (clipboard history, share) and `slurp` (region
  select, so `grim` can only take the whole screen). Menu rows and binds for
  these stay dim until they land.
  `hyprlock`, `hypridle` and `hyprpolkitagent` are deliberate omissions: the
  equivalents here are native Quickshell services.
- The bar uses JetBrains Mono Nerd Font (`nix/shared/system/linux.nix` installs
  several nerd fonts). Berkeley Mono is wanted as the system font eventually,
  but it is a paid font and needs vendoring before Nix can install it.
- Ghostty's `font-size` is in points converted through display DPI, which is 96
  on Linux/GTK but 72 on macOS, so the shared 14pt renders a third larger here.
  `stow/platform/Linux/.config/ghostty/config-linux` overrides it to 10.5 and
  swaps the (unvendored) Berkeley Mono for JetBrains Mono Nerd Font; the shared
  config pulls it in with `config-file = ?config-linux`, which is silently
  skipped on macOS. Relative includes resolve against the stow *symlink's*
  directory (`~/.config/ghostty`), not the repository target, so both files must
  be stowed. All 17 `macos-*` keys parse fine on the Linux build — no split
  needed beyond these overrides.
- Only one emoji font is installed; `noto-fonts-color-emoji` is commented out
  in `nix/shared/system/linux.nix` as slow to build. Quickshell UI will want it.
- Mason installs prebuilt glibc binaries, which cannot run on NixOS. Neovim
  itself works on the VM (every vim.pack plugin installed cleanly), but the
  Mason-managed language servers are expected to be broken. Untested.
- No LSP for `hyprland.lua`. `hyprls` only understands hyprlang `.conf`, which
  is the format we do not use, so the realistic option is `lua_ls` plus a
  hand-written LuaCATS stub for the `hl` API. Unverified — nobody has tried it.
  QML is covered; see "Linting QML and getting the LSP to attach".

## Disk

30G, and `vda2` (ext4) fills all of it bar the 487M ESP — there are no free
extents to grow into, so more room means enlarging the drive first.
`configuration.nix` collects garbage weekly and sets `min-free`/`max-free` so
a build that runs low collects mid-flight rather than dying. That is the cheap
fix and it is already spent: after a `nix-collect-garbage --delete-older-than
7d` the store still holds ~22G of *live* paths, which is simply what this
desktop plus its build closures weigh.

To grow it, with the VM shut down, raise the drive size in UTM (VM settings ›
the VirtIO drive › Resize). qcow2 only grows, and the image is already fully
allocated on the host — check host free space first, the increase is spent
1:1. Then boot and run, noting where the `sudo` goes and that the last command
takes the *partition*, not the disk:

```sh
echo ',+' | sudo sfdisk -N 2 --force /dev/vda  # partition 2 takes the new space
sudo partx -u /dev/vda                         # re-read while mounted
sudo resize2fs /dev/vda2                       # ext4 grows online, no unmount
```

`sudo echo ',+' | sfdisk …` elevates the `echo` and leaves `sfdisk`
unprivileged — it fails with `cannot open /dev/vda: Permission denied`.
`resize2fs /dev/vda` (the disk) fails with `Device or resource busy` /
`Couldn't find valid filesystem superblock`.

`sfdisk`, `partx` and `resize2fs` are all in the base system — no
`cloud-utils-growpart`, which is not installed. `sfdisk` warns that the GPT
backup header is not at the end of the disk and relocates it; that is the
expected message, not a failure. `lsblk` and `df -h /` confirm.

**Deleting from the guest never shrinks the host image.** virtio-blk here
advertises discard (`lsblk -D` shows a 512B granularity), so `fstrim -av`
after a large GC punches the freed blocks out of the qcow2 and hands the space
back to macOS.
