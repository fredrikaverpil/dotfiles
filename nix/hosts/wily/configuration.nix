{ lib, pkgs, ... }:
{
  imports = [
    ../../shared/system/kaizen/desktop.nix
    ../../shared/system/thinkpad.nix
  ]
  # Work-only config from the private dotfiles-einride submodule; an
  # uninitialised submodule is an empty directory, so public clones and CI
  # evaluate without it.
  ++ lib.optional (builtins.pathExists ./einride/default.nix) ./einride/default.nix;

  system.stateVersion = "26.05";

  networking.hostName = "wily";
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  # Lunar Lake Intel Wi-Fi and Xe2 firmware blobs.
  hardware.enableRedistributableFirmware = true;
  # VA-API for gpu-screen-recorder and mpv; Mesa ships none for Intel.
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  # VA-API decode is on by default; encode (video calls) needs AcceleratedVideoEncoder.
  host.chromiumFeatures = [ "AcceleratedVideoEncoder" ];

  # Unset so timedated owns /etc/localtime and `timedatectl set-timezone`
  # persists across rebuilds; this laptop travels. UTC until first set.
  time.timeZone = null;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  # Encrypted swap; the installer keeps it out of hardware-configuration.nix.
  boot.initrd.luks.devices."luks-2bc8d428-9495-4fd8-aaba-9208e0bbaf0f".device =
    "/dev/disk/by-uuid/2bc8d428-9495-4fd8-aaba-9208e0bbaf0f";

  # Bluetooth devices with BlueZ WakeAllowed can wake from suspend. The HHKB
  # reconnects right after suspend, waking it at once, so its WakeAllowed is
  # set false in BlueZ; the MX mouse wakes on click.
  services.udev.extraRules = ''
    ACTION=="add|bind", SUBSYSTEM=="pci", DRIVER=="btintel_pcie", ATTR{power/wakeup}="enabled"
  '';

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

  # Work-issued machine: 1Password holds the work vaults.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "fredrik" ];
  };

  # Host-only system packages; shared ones live in nix/shared/system/.
  host.extraSystemPackages = with pkgs; [ ];
}
