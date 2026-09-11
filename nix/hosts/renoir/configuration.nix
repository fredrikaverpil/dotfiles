{ pkgs, ... }:
{
  imports = [ ./desktop.nix ];

  system.stateVersion = "26.05";

  networking.hostName = "renoir";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Stockholm";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Encrypted swap; the installer keeps it out of hardware-configuration.nix.
  boot.initrd.luks.devices."luks-7389e541-9360-4c4e-b4cf-13a7b66e771a".device =
    "/dev/disk/by-uuid/7389e541-9360-4c4e-b4cf-13a7b66e771a";

  services.fwupd.enable = true;

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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  host.users = {
    fredrik = {
      isAdmin = true;
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = [ "networkmanager" ];
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIutqzZ2V93KOXtPpkdVSxCJwnjhNf/jENvBayDDhAP2"
      ];
    };
  };

  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  host.extraServices.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  host.extraSystemPackages = with pkgs; [
    curl
    git
    wget
  ];
}
