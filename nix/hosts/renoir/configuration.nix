{ pkgs, ... }:
{
  imports = [
    ../../shared/system/kaizen/desktop.nix
    ../../shared/system/thinkpad.nix
    ./personal.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "renoir";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  # Unset so timedated owns /etc/localtime and `timedatectl set-timezone`
  # persists across rebuilds; this laptop travels. UTC until first set.
  time.timeZone = null;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Encrypted swap; the installer keeps it out of hardware-configuration.nix.
  boot.initrd.luks.devices."luks-7389e541-9360-4c4e-b4cf-13a7b66e771a".device =
    "/dev/disk/by-uuid/7389e541-9360-4c4e-b4cf-13a7b66e771a";

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
