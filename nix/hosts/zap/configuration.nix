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
  # Host-specific configuration for zap
  networking.hostName = "zap";

  # Host-specific packages for zap
  dotfiles.extraPackages = with pkgs; [
    # Add zap-specific system packages here
  ];

  dotfiles.extraBrews = [
    # Add zap-specific homebrew packages here
  ];

  dotfiles.extraCasks = [
    "podman-desktop"
    "pgadmin4"
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
