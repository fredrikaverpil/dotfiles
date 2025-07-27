{ config, pkgs, lib, inputs, ... }:

let
  # Versions specific to this host
  stateVersions = {
    darwin = 6;
    homeManager = "25.05";
  };
in
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

  # System state version
  system.stateVersion = stateVersions.darwin;

  # Home Manager state version
  home.stateVersion = stateVersions.homeManager;

  # Timezone
  time.timeZone = "Europe/Stockholm";
}
