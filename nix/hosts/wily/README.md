# wily (ThinkPad T14 Gen 6 Intel, Core Ultra 7 258V "Lunar Lake")

Work machine (Lenovo 21QG006CMX). The niri + Quickshell desktop it runs is
shared with `renoir` and documented in `nix/shared/system/kaizen/CLAUDE.md`.
Work-only configuration lives in the private
`fredrikaverpil/dotfiles-einride` repo, mounted as the git submodule `einride/`
and imported by `configuration.nix` only when checked out.

## Rebuilding

Flakes copy the tree from `git ls-files`, which lists the submodule pointer
but not its contents, so a plain flake reference sees `private/` as an empty
directory and silently builds the host without the work config. The flake
reference has to ask for submodules:

```sh
nh os switch                                                        # normal
sudo nixos-rebuild switch --flake "$HOME/.dotfiles?submodules=1#wily"   # what nh runs
```

`programs.nh.flake` in `users/fredrik.nix` carries `?submodules=1`;
`inputs.self.submodules` in `flake.nix` is not an option, because it makes
public clones and CI try to fetch the private repo.

After pulling, `git submodule update --init` brings the submodule to the
pinned commit. CI builds the host without the submodule checked out.

## Test-driving Noctalia

Noctalia v5 (nixpkgs `noctalia`, a C++ shell; `noctalia-shell` is the v4
Quickshell config) is evaluated, never installed: both routes below run it
from the host's own nixpkgs and leave its state in `~/.config/noctalia/` and
`~/.local/state/noctalia/`, outside the dotfiles.

A whole session without kaizen: `noctalia` from the TTY, the counterpart to
`kaizen` in `shell/sourcing.sh`. It masks `quickshell`, `dcal` and
`kaizen-sleep-lock` for the session and lets niri start Noctalia instead.
niri's config is kaizen's, so its `qs ipc` binds do nothing and Noctalia's own
binds are absent. Its logs are `journalctl --user -u noctalia-trial -f`,
the same unit name as the swap below. The masks are `--runtime`, so they are gone after a reboot,
and `kaizen` clears them before starting; either command always reaches the
other session.

Swapping shells inside a running kaizen session, keeping its niri and units:

```sh
systemctl --user stop quickshell
systemd-run --user --unit=noctalia-trial --collect -p Slice=app.slice \
  nix run ~/.dotfiles#nixosConfigurations.wily.pkgs.noctalia
journalctl --user -u noctalia-trial -f   # logs

# back
systemctl --user stop noctalia-trial && systemctl --user start quickshell
```

Here `kaizen-sleep-lock` is still running but cannot lock, so do not suspend.

## Hardware

- GPU: Xe2 on the `xe` driver. Mesa has no Intel VA-API, so
  `configuration.nix` adds `intel-media-driver`; without it
  gpu-screen-recorder encodes on the CPU and mpv decodes in software. Xe2
  decodes HEVC 4:2:2 10-bit camera footage in hardware, unlike renoir.
- Display: 14" 1920x1200 (AU Optronics B140UAN02.7), niri auto-scale 1.25.
- CPU frequency: `intel_pstate`; power-profiles-daemon uses
  `platform_profile`. The EC owns thermal throttling (DYTC): thermald exits
  when `dytc_lapmode` exists. Package temperature is `coretemp` `temp1_input`.
- Sleep: `s2idle` only (`/sys/power/mem_sleep`), no S3; it drains 1-2 %/h.
  Lid close uses the logind default, plain suspend. Hibernate is not set up:
  on kernel 6.18 it aborted or hung in the snapshot, with `intel_vpu` (NPU)
  failing to power down (`PWR_D0I3_ENTER ... ret -110`, `returns -16`).
- Wi-Fi: `iwlwifi` (Wi-Fi 7). The boot warning
  `Direct firmware load for iwlwifi-bz-...-c99.ucode failed` is the driver
  probing newer firmware API versions before falling back; harmless.
- Fingerprint reader: Goodix `27c6:6594`, unused. libfprint's `goodixmoc`
  driver lists it; renoir's README has the fprintd enabling notes, untested
  on this reader.
- Camera: `/dev/video0` is the capture node (MJPEG up to 2592x1944@30);
  `video1`-`video3` are metadata and duplicate nodes.
- Battery: Sunwoda 57 Wh, thresholds 75/80 % via
  `nix/shared/system/thinkpad.nix`.
- Built-in keyboard is `0001:0001` (keyd), keyboard backlight is
  `tpacpi::kbd_backlight` (Fn+Space, firmware-driven).

## Firmware

BIOS and device firmware come from LVFS through fwupd; updates reboot, so the
user runs them. BIOS N4HET22W 1.10 (2026-09). `fwupdmgr get-updates` also
lists NVMe (SK hynix HFS001TFM9X179N) and "System Update" bundles.

```sh
fwupdmgr refresh --force
fwupdmgr get-updates
cat /sys/class/power_supply/AC/online   # must print 1
fwupdmgr update <device-id>
```

Secure Boot is disabled (the NixOS installer is unsigned); the KEK/UEFI CA/dbx
updates are unnecessary.
