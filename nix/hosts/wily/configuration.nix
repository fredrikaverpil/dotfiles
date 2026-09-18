{ lib, pkgs, ... }:
{
  imports = [
    ./desktop.nix
    ./thinkpad.nix
  ]
  # Work-only config from the private dotfiles-einride submodule; an
  # uninitialised submodule is an empty directory, so public clones and CI
  # evaluate without it.
  ++ lib.optional (builtins.pathExists ./private/default.nix) ./private/default.nix;

  system.stateVersion = "26.05";

  networking.hostName = "wily";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  # Lunar Lake Intel Wi-Fi and Xe2 firmware blobs.
  hardware.enableRedistributableFirmware = true;
  # VA-API for gpu-screen-recorder and mpv; Mesa ships none for Intel.
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  time.timeZone = "Europe/Stockholm";

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # Encrypted swap; the installer keeps it out of hardware-configuration.nix.
  boot.initrd.luks.devices."luks-2bc8d428-9495-4fd8-aaba-9208e0bbaf0f".device =
    "/dev/disk/by-uuid/2bc8d428-9495-4fd8-aaba-9208e0bbaf0f";
  # Hibernate image lives in that swap (33.9 GB for 30 GB RAM); the mapper
  # name is what initrd unlocks, so resume finds it after the passphrase.
  boot.resumeDevice = "/dev/mapper/luks-2bc8d428-9495-4fd8-aaba-9208e0bbaf0f";

  # Lunar Lake has s2idle only, which drains 1-2 %/h; lid close suspends and
  # hibernates after 2 h. Unset, systemd instead hibernates when the battery
  # is predicted to hit 5 %, days away at that drain.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";

  # Caps RAPL power and P-states before the package reaches TjMax, so sustained
  # loads settle at the firmware design power instead of hard-throttling.
  # Thermal only; power-profiles-daemon owns platform_profile.
  services.thermald.enable = true;

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

  services.tailscale.enable = true;

  # CUPS on loopback only; Avahi discovers driverless (IPP Everywhere) printers.
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  programs.system-config-printer.enable = true;

  host.extraServices.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # Host-only system packages; shared ones live in nix/shared/system/.
  host.extraSystemPackages = with pkgs; [ ];
}
