{ pkgs, ... }:
{
  imports = [
    ../../shared/system/kaizen/desktop.nix
    ../../shared/system/thinkpad.nix
  ];

  system.stateVersion = "26.05";

  networking.hostName = "renoir";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  # ente-desktop pins EOL electron; drop once nixpkgs bumps it.
  nixpkgs.config.permittedInsecurePackages = [ "electron-41.10.6" ];

  # 0.8.2 closes Steam menus instantly (Supreeeme/xwayland-satellite#468, fixed
  # on main by #494); drop this pin once a newer release lands in nixpkgs.
  nixpkgs.overlays = [
    (_: prev: {
      xwayland-satellite = prev.xwayland-satellite.overrideAttrs (
        finalAttrs: _: {
          version = "0.8.1";
          src = prev.fetchFromGitHub {
            owner = "Supreeeme";
            repo = "xwayland-satellite";
            tag = "v${finalAttrs.version}";
            hash = "sha256-BUE41HjLIGPjq3U8VXPjf8asH8GaMI7FYdgrIHKFMXA=";
          };
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            hash = "sha256-16L6gsvze+m7XCJlOA1lsPNELE3D364ef2FTdkh0rVY=";
          };
        }
      );
    })
  ];

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

  # S3 resume needs the USB Bluetooth adapter (MediaTek) armed to wake, or the
  # wireless mouse cannot wake the laptop.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0489", ATTR{idProduct}=="e0cd", ATTR{power/wakeup}="enabled"
  '';

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

  programs.steam = {
    # Also enables 32-bit graphics; Proton versions are picked in Steam.
    enable = true;
    # steam-gamescope: Big Picture in standalone gamescope, run from a TTY.
    gamescopeSession.enable = true;
  };

  # Host-only system packages; shared ones live in nix/shared/system/.
  host.extraSystemPackages = with pkgs; [
    (withGnomeLibsecret ente-desktop)
    lutris # Battle.net and other non-Steam launchers.
  ];
}
