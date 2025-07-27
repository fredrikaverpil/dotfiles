{ config, pkgs, lib, inputs, ... }:

let
  # Versions specific to this host
  stateVersions = {
    darwin = 6;
  };
in
{
  # Host-specific configuration for zap
  networking.hostName = "zap";
  
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



  # Timezone
  time.timeZone = "Europe/Stockholm";
}
