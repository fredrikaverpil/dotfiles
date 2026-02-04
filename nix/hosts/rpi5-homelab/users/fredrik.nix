{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  # rpi5-homelab-specific package-managed tools
  packageTools.npmPackages = [ ];
  packageTools.uvTools = [ ];

  home.packages = with pkgs; [
    # Host-specific packages go here
  ];

  home.file = {
  };

  programs = {
  };
}
