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

  packageTools.npmPackages = [ ];
  packageTools.uvTools = [ ];

  home.packages = with pkgs; [ ];

  home.file = {
  };

  programs = {
  };
}
