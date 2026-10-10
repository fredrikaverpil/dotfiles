{ pkgs, inputs, ... }:
{
  imports = [
    ../../shared/system/linux-desktop.nix
    ../../shared/system/kaizen/session.nix
    ../../shared/system/kaizen/plugins/calendar
    ./kaizen-plugins/hello-tray
    ../../shared/system/thinkpad.nix
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

  networking.firewall.allowedTCPPorts = [ 22 ];

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  programs.steam = {
    # Also enables 32-bit graphics; Proton versions are picked in Steam.
    enable = true;
    # steam-gamescope: Big Picture in standalone gamescope, run from a TTY.
    gamescopeSession.enable = true;
  };

  # Host-only system packages; shared ones live in nix/shared/system/.
  environment.systemPackages = with pkgs; [
    (withGnomeLibsecret ente-desktop)
    (withGnomeLibsecret obsidian)
    lutris # Battle.net and other non-Steam launchers.
    inputs.delta.packages.${pkgs.stdenv.hostPlatform.system}.delta
  ];
}
