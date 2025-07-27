{ config, pkgs, lib, inputs, ... }:

{
   imports = [
     ../../shared/system/darwin.nix
   ];
  # Host-specific configuration for plumbus
  networking.hostName = "plumbus";

  # Host-specific packages for plumbus
  dotfiles.extraPackages = with pkgs; [
    # Add plumbus-specific packages here
  ];

  dotfiles.extraBrews = [
    # Add plumbus-specific homebrew packages here
  ];

  dotfiles.extraCasks = [
    "orbstack"
    "raycast"
  ];

  # Set system platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # System state version - set once when host was first installed, never change
  # Use `darwin-rebuild changelog` to see version-specific changes
  system.stateVersion = 6;  # Installed in 2025

  # Timezone
  time.timeZone = "Europe/Stockholm";
}
