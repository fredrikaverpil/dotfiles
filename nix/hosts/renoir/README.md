# renoir (ThinkPad T14 Gen 1, AMD Renoir)

Personal machine. The niri + Quickshell desktop it runs is shared with `wily`
and documented in `nix/shared/system/kaizen/CLAUDE.md`; its Nix modules are
`nix/shared/system/kaizen/desktop.nix` and `nix/shared/system/thinkpad.nix`.
Machine-specific settings (microcode, VAAPI driver, kernel choice) and
host-only programs belong in `configuration.nix`.

## Sleep

Lid close uses the logind default, plain suspend; there is no hibernate.

## Firmware

BIOS and device firmware come from LVFS through fwupd. Updates reboot the
machine, so the user runs them.

```sh
fwupdmgr refresh --force               # stale metadata reports "no updates"
fwupdmgr get-updates                   # lists each device's "Device ID"
cat /sys/class/power_supply/AC/online   # must print 1
fwupdmgr update <device-id>
```

- The BIOS update needs AC power and reboots into a UEFI capsule flash. It
  is staged on the ESP (`/boot`); keep room there.
- Secure Boot is disabled, so the KEK CA, UEFI CA and dbx updates are
  unnecessary. Update only the device you need, by ID.
- After the reboot, confirm `/sys/class/dmi/id/bios_version` and recheck
  `journalctl -b -k -p warning`.
- A BIOS update can reset EFI settings; recheck Config → Power → Sleep State.
  "Linux" enables S3 (`deep` in `/sys/power/mem_sleep`).
- The BIOS has no CPPC option, so `amd_pstate` stays disabled and cpufreq
  uses `acpi-cpufreq`.

## Fingerprint reader

The Synaptics reader (`06cb:00bd`) is unused by choice. To enable it:

```nix
# fprintAuth defaults to on for every PAM service. login (and kaizen-lock,
# which includes it) and sudo stay password-only until tested on hardware.
services.fprintd.enable = true;
security.pam.services.login.fprintAuth = false;
security.pam.services.sudo.fprintAuth = false;
```

Then rebuild, and run `fprintd-enroll` and `fprintd-verify`.

- Check the generated PAM with
  `nix eval --raw .#nixosConfigurations.renoir.config.security.pam.services.<name>.text`;
  `environment.etc."pam.d/<name>".text` is null because it uses `source`.
- The lock screen needs a separate, concurrent fingerprint `PamContext` (see
  the `kaizen-lock` comment in `nix/shared/system/kaizen/desktop.nix`). Test it with a recovery plan
  before enabling it for `login`.
- fwupd cannot read the reader's firmware version: it answers with an
  unmapped status `0x315`. libfprint talks to it independently; untested.

## Peripherals

- The keyboard backlight is firmware-driven (Fn+Space); leave it alone.
- Cameras: gpu-screen-recorder composites `v4l2:/dev/video2` in-process; a
  camera held by a recording is unavailable to other applications.
