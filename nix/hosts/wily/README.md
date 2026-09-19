# wily (ThinkPad T14 Gen 6 Intel, Core Ultra 7 258V "Lunar Lake")

Work machine (Lenovo 21QG006CMX). The desktop is promoted here from `renoir` by
copying files; see `CLAUDE.md`. Work-only configuration lives in the private
`fredrikaverpil/dotfiles-einride` repo, mounted as the git submodule `private/`
and imported by `configuration.nix` only when checked out.

> [!NOTE]
>
> Awaiting the Proton Pass v1.40+ SSH agent, so per-usage PIN can be used.

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

## Hardware

- GPU: Xe2 on the `xe` driver. Mesa has no Intel VA-API, so
  `configuration.nix` adds `intel-media-driver`; without it
  gpu-screen-recorder encodes on the CPU and mpv decodes in software. Xe2
  decodes HEVC 4:2:2 10-bit camera footage in hardware, unlike renoir.
- Display: 14" 1920x1200 (AU Optronics B140UAN02.7), niri auto-scale 1.25.
- CPU frequency: `intel_pstate`; power-profiles-daemon uses
  `platform_profile`. The EC owns thermal throttling (DYTC): thermald exits
  when `dytc_lapmode` exists. Package temperature is `coretemp` `temp1_input`.
- Sleep: `s2idle` only (`/sys/power/mem_sleep`), no S3. Lid close is
  `suspend-then-hibernate`: suspend, then after `HibernateDelaySec=2h` a
  hibernate to the encrypted swap (`boot.resumeDevice`, 33.9 GB for 30 GB
  RAM). Waking from hibernate asks for the LUKS passphrase, then restores
  the session. Verified with `systemctl hibernate`; the kernel log shows
  `hibernation entry`/`exit` under the same boot ID.
- Wi-Fi: `iwlwifi` (Wi-Fi 7). The boot warning
  `Direct firmware load for iwlwifi-bz-...-c99.ucode failed` is the driver
  probing newer firmware API versions before falling back; harmless.
- Fingerprint reader: Goodix `27c6:6594`, unused. libfprint's `goodixmoc`
  driver lists it; renoir's README has the fprintd enabling notes, untested
  on this reader.
- Camera: `/dev/video0` is the capture node (MJPEG up to 2592x1944@30);
  `video1`-`video3` are metadata and duplicate nodes.
- Battery: Sunwoda 57 Wh, thresholds 75/80 % via `thinkpad.nix`.
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
