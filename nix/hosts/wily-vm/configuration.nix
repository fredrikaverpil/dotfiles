{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ ./desktop.nix ];

  # Install-time compatibility marker, not the nixpkgs channel — see flake.nix
  # for the channel (this host tracks nixpkgs-unstable via mkNixos).
  system.stateVersion = "26.05";

  networking.hostName = "wily-vm";
  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Stockholm";

  # When the Mac host sleeps, UTM pauses the VM and its clock simply stops, so
  # the guest wakes hours behind. systemd-timesyncd steps only on its first
  # sync and slews after that, which never closes a gap that large. chrony
  # with an unlimited makestep corrects it on the next poll instead.
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    extraConfig = "makestep 1.0 -1";
  };

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
