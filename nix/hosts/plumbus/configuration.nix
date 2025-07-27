{ config, pkgs, lib, inputs, ... }:

let
  # Versions specific to this host
  stateVersions = {
    darwin = 6;
  };
in
{
  # Host-specific configuration for plumbus
  networking.hostName = "plumbus";
  
  # Multi-user configuration
  dotfiles.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true;  # Primary user for Darwin system defaults
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = [ "docker" ];
    };
  };

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



  # Timezone
  time.timeZone = "Europe/Stockholm";
}
