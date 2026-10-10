# renoir (ThinkPad T14 Gen 1, AMD Renoir)

Personal machine. The niri + Quickshell desktop it runs is shared with `wily`
and documented in `docs/kaizen/README.md`; its Nix modules are
`nix/shared/system/kaizen/default.nix`, the kaizen plugins `configuration.nix`
imports, and `nix/shared/system/thinkpad.nix`.
Machine-specific settings (microcode, VAAPI driver, kernel choice) and
host-only programs belong in `configuration.nix`.

## Sleep

Lid close uses the logind default, plain suspend; there is no hibernate.

## Firmware

The fwupd procedure is in `nix/shared/system/kaizen/default.nix`.

- Secure Boot is disabled: the NixOS installer is unsigned.
- A BIOS update can reset EFI settings; recheck Config → Power → Sleep State.
  "Linux" enables S3 (`deep` in `/sys/power/mem_sleep`).
- The BIOS has no CPPC option, so `amd_pstate` stays disabled and cpufreq
  uses `acpi-cpufreq`.

## Fingerprint reader

The Synaptics reader (`06cb:00bd`) is unused;
`nix/shared/system/thinkpad.nix` has the enabling notes.

- fwupd cannot read the reader's firmware version: it answers with an
  unmapped status `0x315`. libfprint talks to it independently; untested.

## Peripherals

- The keyboard backlight is firmware-driven (Fn+Space); leave it alone.
- Cameras: gpu-screen-recorder composites `v4l2:/dev/video2` in-process; a
  camera held by a recording is unavailable to other applications.
