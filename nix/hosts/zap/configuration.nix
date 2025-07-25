{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../shared/darwin-system.nix
    ../../shared/home-manager-darwin.nix
    inputs.home-manager-unstable.darwinModules.home-manager
  ];

  # Host-specific configuration for zap
  networking.hostName = "zap";

  # Host-specific packages for zap
  dotfiles.extraPackages = with pkgs; [
    # Container tools (zap only - podman setup)
    podman
    podman-compose
  ];

  dotfiles.extraBrews = [
    # Add zap-specific homebrew packages here
  ];

  dotfiles.extraCasks = [
    "podman-desktop"
    "fujifilm-x-raw-studio"
    "obs"
	"pgadmin4"
  ];

  # Set system platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # System state version - set once when host was first installed, never change
  # Use `darwin-rebuild changelog` to see version-specific changes
  system.stateVersion = 6;  # Installed in 2025

  # Timezone
  time.timeZone = "Europe/Stockholm";
}
