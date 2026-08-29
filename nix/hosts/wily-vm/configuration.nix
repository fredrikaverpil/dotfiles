{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # Install-time compatibility marker, not the nixpkgs channel — see flake.nix
  # for the channel (this host tracks nixpkgs-unstable via mkNixos).
  system.stateVersion = "26.05";

  networking.hostName = "wily-vm";
  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Stockholm";

  # UEFI. nixos-generate-config emits these into the throwaway
  # /etc/nixos/configuration.nix, which this file replaces — without them the
  # generation has no bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  host.users = {
    fredrik = {
      isAdmin = true;
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = [ "networkmanager" ];
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKte3qmH2qXRfdbVIfl6HgFvhRE6MCCiL9ho7xW3KSZB"
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
