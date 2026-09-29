# ThinkPad hardware integration (thinkpad_acpi, built-in keyboard, firmware).
{ ... }:
{
  # BIOS and device firmware from LVFS. Updates reboot, so the user runs them:
  #
  #   fwupdmgr refresh --force               # stale metadata reports "no updates"
  #   fwupdmgr get-updates                   # lists each device's "Device ID"
  #   cat /sys/class/power_supply/AC/online  # must print 1
  #   fwupdmgr update <device-id>
  #
  # A BIOS update needs AC power and reboots into a UEFI capsule flash staged on
  # the ESP (/boot); keep room there. It can reset EFI settings. Afterwards,
  # confirm /sys/class/dmi/id/bios_version and recheck
  # `journalctl -b -k -p warning`. Secure Boot is disabled (the NixOS installer
  # is unsigned), so the KEK CA, UEFI CA and dbx updates are unnecessary; update
  # only the device you need, by ID.
  services.fwupd.enable = true;

  # The fingerprint reader is unused by choice. fprintAuth defaults to on for
  # every PAM service; login (and kaizen-lock, which includes it) and sudo stay
  # password-only until tested on hardware. To enable it:
  #
  #   services.fprintd.enable = true;
  #   security.pam.services.login.fprintAuth = false;
  #   security.pam.services.sudo.fprintAuth = false;
  #
  # Then rebuild, and run fprintd-enroll and fprintd-verify. Check the generated
  # PAM with
  # `nix eval --raw .#nixosConfigurations.<host>.config.security.pam.services.<name>.text`;
  # environment.etc."pam.d/<name>".text is null because it uses `source`. The
  # lock screen needs a separate, concurrent fingerprint PamContext (see the
  # kaizen-lock comment in kaizen/session.nix). Test it with a recovery plan
  # before enabling it for login.

  # Swaps Super and left Alt and makes Caps Lock Ctrl on the built-in keyboard;
  # other keyboards are untouched.
  services.keyd = {
    enable = true;
    keyboards.laptop = {
      ids = [ "0001:0001" ];
      settings.main = {
        leftmeta = "leftalt";
        leftalt = "leftmeta";
        capslock = "leftcontrol";
      };
    };
  };

  # The kernel's audio-micmute trigger follows only the built-in ALSA capture
  # switch. The shell mutes every PipeWire source and writes the LED itself via
  # logind, so the trigger is cleared here.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", ATTR{trigger}="none"
  '';

  # The battery panel only displays these and never writes sysfs.
  # thinkpad_acpi rejects a start above the end threshold and an end below the
  # start threshold, so the first end write may fail until start is lowered.
  systemd.services.battery-charge-thresholds = {
    description = "Set battery charge thresholds";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/sys/class/power_supply/BAT0/charge_control_end_threshold";
    serviceConfig.Type = "oneshot";
    script = ''
      bat=/sys/class/power_supply/BAT0
      echo 80 > "$bat/charge_control_end_threshold" || true
      echo 75 > "$bat/charge_control_start_threshold"
      echo 80 > "$bat/charge_control_end_threshold"
    '';
  };
}
