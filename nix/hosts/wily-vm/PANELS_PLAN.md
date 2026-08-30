# Plan: network and display panels, and a scheduled nightlight

Scaffolding, not a durable record. Facts that outlive the work move into
`CLAUDE.md` in the commit that establishes them; this file is deleted in the
final commit of the series.

Upstream model: Omarchy Quattro at `~/code/public/github.com/omacom/omarchy`.

## Decisions taken up front

- **Build the Wi-Fi half blind.** The VM has `enp0s1:ethernet` and no radio, so
  scanning, signal, passphrase entry and forget are unverifiable here. They get
  written anyway and marked untested in `CLAUDE.md`; ethernet state is the only
  part that can be exercised.
- **Anything the hardware cannot back becomes a dim row**, using the menu's
  existing `enabled: false` convention and `palette.off`. No third "unavailable"
  state. That covers brightness (no backlight device) and per-monitor
  enable/disable (one scanout).
- **IPC targets stay bare** — `display`, `network`, `nightlight` — matching our
  `menu`/`theme`/`lock`/`idle`, not upstream's dotted `omarchy.monitor` /
  `omarchy.network`. A deliberate divergence: file paths line up for diffing,
  target names follow the local convention. Record it in `CLAUDE.md`.
- **File paths mirror upstream** so `diff` stays useful:
  `plugins/panels/{monitor,network}/{Panel.qml,Model.js}`,
  `plugins/services/nightlight/{Service.qml,NightlightModel.js}`,
  `plugins/bar/Bar.qml`, `plugins/menu/Menu.qml`,
  `plugins/background/Background.qml`, `Ui/Panel.qml`.
- **Solar times are ours.** hyprsunset only takes fixed clock times.
- **Location comes from the system timezone**, not a hardcoded default and not
  geoclue2.

## Facts established while planning

- `Quickshell.Networking` **is** present in 0.3.0 on the VM
  (`.../qml/Quickshell/Networking`), so the Wi-Fi list, scan and connect come
  from the singleton. Upstream's `nmcli` shelling is only for the extras.
  Its `NetworkDevice.address` is the MAC address, not an IP, so the panel maps
  each device to its global IPv4 address with `ip -j -4 address`.
- **hyprsunset has no sunrise/sunset support.** From
  `hyprwm/hyprsunset` `src/ConfigManager.cpp`, the whole config surface is
  `max-gamma` plus `profile { time = HH:MM, temperature, gamma, identity }`;
  IPC is `temperature|gamma|identity|profile|reset|get`. No geolocation, no
  solar keyword.
- **A profile will clobber a runtime temperature.** Omarchy ships
  `profile { time = 07:00; identity = true }` to keep hyprsunset inert at
  startup, and that profile fires every morning. Our schedule tick re-asserts
  the desired temperature on the same timer it already needs to cross the
  sunset boundary, so the clobber heals itself; no extra mechanism.
- **A fresh hyprsunset overwrites the temperature at the end of its boot.**
  `bin/omarchy-toggle-nightlight` retries ten times at 0.2s for this. Keep the
  retry.
- **Upstream's scaling script is already Lua-era**:
  `bin/omarchy-hyprland-monitor-scaling` calls
  `hyprctl eval "hl.monitor({ ... })"`. The dead `hyprctl keyword` at
  `panels/monitor/Panel.qml:303` is only on the monitor enable/disable path,
  which is dim here anyway.
- **Scale persistence is a config rewrite.** `hyprctl eval` is reverted by the
  next `hyprland.lua` auto-reload, so upstream `sed`s
  `local omarchy_monitor_scale = ...` in `monitors.lua`. `sed -i` writes a temp
  file and `rename()`s it, which is atomic — unlike git's unlink-then-create,
  it does not trip the missing-file overlay. Verified on the VM: a `sed -i`
  insert and its revert on the live `hyprland.lua` both left
  `hyprctl configerrors` empty.
- **Per-host Stow packages settle the persistence shape.** `e82630a9` makes
  `stow/<hostname>/` optional in both activation and the documented manual
  command. `stow/wily-vm/.config/hypr/monitors.lua` therefore owns
  `wily_monitor_scale` and `wily_gdk_scale`; shared `hyprland.lua` loads it
  when present and otherwise falls back to scale 1. This matches Omarchy's
  separate monitor file without leaking a VM-specific scale to rpi5-homelab or
  the ThinkPad.

  The panel applies a clean scale live through `hyprctl eval`, then updates the
  two variables with `sed -i --follow-symlinks`. The flag is essential: GNU sed
  without it replaces a Stow symlink with a regular file, while the flag edits
  its target and leaves the managed relative link in place.

  `hl.env("GDK_SCALE", ...)` comes along for XWayland sizing and only takes
  effect at compositor startup, as `hl.env` is read once.
- **Hyprland only accepts scales that divide the mode into whole logical
  pixels** (1/120 steps; clean scales divide `gcd(w*120, h*120)`). Port
  `panels/monitor/Model.js`'s `cleanScale` / `availableScales` verbatim.
- Upstream bar order, right group, left to right: tray, agents, bluetooth,
  **network**, audio, **monitor**, power. Ours becomes network, display, bell.
- Upstream binds, all in the `SUPER + CTRL` system layer and consistent with
  the layer table in `CLAUDE.md`: `SUPER + CTRL + W` Network,
  `SUPER + CTRL + D` Display, `SUPER + CTRL + N` Toggle nightlight.
  `SUPER + CTRL + W` is a macOS-capture risk from the Mac host; check
  `hyprctl -j binds` before calling it broken.
- Upstream's nightlight service is `plugins/services/nightlight/` — 115 lines
  of QML plus a 20-line model. Ours is that plus the schedule.
- **The zone table to read is `zone.tab`, not `zone1970.tab`.** tzdata's 2022
  consolidation merged Sweden into `Europe/Berlin`, so `zone1970.tab` no longer
  lists `Europe/Stockholm` at all and only the legacy table still resolves the
  name `timedatectl` reports. Verified on the VM.
- Those coordinates are the zone's *principal city*, so Malmo would be ~15
  minutes off Stockholm's winter sunset. Acceptable for a blue-light filter;
  note the ceiling and keep the override.
- **Automatic geolocation is not worth wiring up.**
  `services.automatic-timezoned` drives geoclue2, whose Wi-Fi backend depended
  on the Mozilla Location Service, retired in 2024. The timezone stays manual.

## Commits

Each one builds, stows and leaves the VM in a working state.

### 1. `refactor(wily-vm): split shell.qml` — landed

`shell.qml` is 780 lines and holds the bar, the menu, the wallpaper picker and
the theme plumbing. Two more panels would double it. Split with no behaviour
change:

- `plugins/bar/Bar.qml` — the bar `Variants`/`PanelWindow` and `BarButton`.
- `plugins/menu/Menu.qml` + `MenuModel.js` — the level stack, search and rows.
- `plugins/background/Background.qml` — wallpaper surface and the picker.
- Theme (`dark`, `palette`, `setDark`, the `dconf watch`, the `theme` IPC
  target) **stays in `shell.qml`**: at ~50 lines it is what every surface
  already reads as `shell.palette`, and a fifth file buys nothing. Divergence
  from the original plan, deliberate.
- `Ui/Panel.qml` — shared panel chrome: layer-shell surface in the palette,
  `open`/`close`/`toggle`, Escape and click-outside to close, keyboard focus.
  The wallpaper picker adopts it here, so it has two users the day it exists.

`shell.qml` ends up as wiring only. Check: the menu, the picker, the theme
toggle and every keybind still work.

### 2. `feat(wily-vm): nightlight on a solar schedule` — landed

- `hyprsunset` into `desktop.nix`; `stow/Linux/.config/hypr/hyprsunset.conf`
  with the single inert `identity` profile.
- `plugins/services/nightlight/Service.qml` — port of upstream's, including the
  boot-race retry loop and the 4000K/6500K pair.
- `NightlightModel.js` — upstream's `isNightlight`, plus `solarTimes(date, lat,
  lon)`: the NOAA sunrise equation, ~25 lines, no network and no dependency.
  Leaves a `demo()` self-check runnable under `node`, which is how upstream
  tests its `*Model.js` files.
- Latitude/longitude are derived from the system timezone: `timedatectl show
  -p Timezone` gives `Europe/Stockholm`, and `/etc/zoneinfo/zone.tab` gives
  `SE	+5920+01803	Europe/Stockholm` — ISO 6709, so 59.33 N, 18.05 E. No
  network, no service, and it follows the laptop when the timezone changes. A
  property overrides it.
- Mode: `auto` (solar), `on`, `off`. A manual toggle overrides until the next
  boundary, which is what Night Shift does.
- IPC `nightlight`: `toggle`, `enable`, `disable`, `auto`, `status`.
- Bind `SUPER + CTRL + N`, and the menu's dim Nightlight row wired up.

Check: `hyprctl hyprsunset temperature` reports 4000 after a toggle; a forced
boundary (feed the model a fake clock in the `node` check) flips it; the
morning `identity` profile does not leave it stuck.

### 3. `feat(wily-vm): display panel` — landed

`plugins/panels/monitor/{Panel.qml,Model.js}` on the shared `Ui/Panel`.

Live rows:

- **Light / dark** — moved off the bar, calling `shell.setDark` directly. The
  sun/moon bar button is replaced by a display icon (`󰍹`) that opens this panel.
- **Nightlight** — off / auto / on, plus the current temperature.
- **Scale** — upstream's preset list (1, 1.25, 1.6, 2, 3, 4) filtered through
  the ported `availableScales`, applied with
  `hyprctl eval "hl.monitor({...})"`, persisted by rewriting the
  host-owned `stow/wily-vm/.config/hypr/monitors.lua`.
- **Text size** — GTK `text-scaling-factor` via `dconf`, plus the bar's own
  font size. A compact preset row (80–150%) fits the smaller local panel rather
  than upstream's slider. **Not** the terminal: upstream `sed`s
  `~/.config/ghostty/config`, which for us is `stow/shared/` and shared with
  macOS, so a slider would dirty the repo and follow the user to the Mac.
  Noted as deferred rather than done differently.

Dim rows: **Brightness** (no backlight device on the VM) and **Displays**
(one scanout). Both ThinkPad work.

Bar order becomes network, display, bell. Bind `SUPER + CTRL + D`; menu's dim
Setup › Display row wired up.

Check: scale change applies live, survives `hyprctl reload`, and
`hyprctl -j monitors` agrees; light/dark still flips Ghostty and Neovim; the
bar no longer carries a theme button.

### 4. `feat(wily-vm): network panel` — wired path validated; Wi-Fi untested

`plugins/panels/network/{Panel.qml,Model.js}`, from `Quickshell.Networking`.

In: device list with type and state; current connection with IP; live internet
latency, packet loss, transfer rate and total bytes; Wi-Fi scan and list sorted
by signal; connect with a passphrase prompt; disconnect; forget; Wi-Fi radio
toggle. Bar icon reflecting state (wired / signal strength / disconnected).

Revisit the remainder of Omarchy's network functionality once actual hardware
is available; its separate scripts are not, on their own, a reason to rule out
a NixOS port.

Bind `SUPER + CTRL + W`; menu's Setup › Network row wired up.

Check: ethernet state, global IPv4, default gateway, totals, rates, latency and
packet loss are correct on the VM; the bar shows the wired icon, and the panel
opens through IPC. Everything Wi-Fi is **untested until the ThinkPad** and says
so in `CLAUDE.md`.

### 5. `docs(wily-vm): delete this file`

Fold anything still true into `CLAUDE.md`.

## Deliberately not in this series

**Trimming `CLAUDE.md`.** It is ~890 lines and wants splitting into referenced
files, but bundling a restructure into a feature series makes both diffs
unreadable, and until these four commits land we do not know which sections
grew. Own commit, afterwards.
