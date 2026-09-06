{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ ./desktop.nix ];

  system.stateVersion = "26.05";

  networking.hostName = "wily-vm";
  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Stockholm";

  # UTM pauses the guest with the Mac; chrony must step the resulting time gap.
  services.timesyncd.enable = false;
  services.chrony = {
    enable = true;
    extraConfig = "makestep 1.0 -1";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;
  nix.settings = {
    min-free = 3 * 1024 * 1024 * 1024;
    max-free = 8 * 1024 * 1024 * 1024;
  };

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
