{ config, pkgs, lib, ... }: {
  # Main configuration file for rpi5-homelab Raspberry Pi 5 system
  # This file orchestrates the modular configuration by importing specialized modules
  
  imports = [
    ./modules/networking.nix  # Network configuration, WiFi, mDNS
    ./modules/services.nix    # System services (SSH, Docker, time sync)
    ./modules/users.nix       # User accounts and permissions
    ./modules/packages.nix    # System-level package installations
  ];

  # System identification tags for the Raspberry Pi
  # These tags help identify the system variant and configuration
  # Following the nixos-raspberrypi project conventions
  system.nixos.tags =
    let
      cfg = config.boot.loader.raspberryPi;
    in
    [
      "raspberry-pi-${cfg.variant}"  # e.g., "raspberry-pi-5"
      cfg.bootloader                 # Bootloader type
      config.boot.kernelPackages.kernel.version  # Kernel version
    ];

  # Enable modern Nix features for flake support and improved CLI
  # Required for this flake-based configuration to function properly
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # NixOS state version - determines the default versions of packages and services
  # This should match the NixOS release used when the system was first installed
  # Required for nixos-anywhere deployment tool compatibility
  system.stateVersion = "25.05";

  # System timezone configuration
  time.timeZone = "Europe/Stockholm";
}
