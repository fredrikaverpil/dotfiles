# ThinkPad hardware integration (thinkpad_acpi, built-in keyboard, firmware).
{ ... }:
{
  # BIOS and device firmware from LVFS (fwupdmgr); see README.md.
  services.fwupd.enable = true;

  # BlueZ does not persist Powered; the shell's panel only toggles power and
  # connects paired devices, pairing belongs to bluetui.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

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
