{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  # Add host-specific npm tools
  npmTools = config.npmTools ++ [
  ];

  home.packages = with pkgs; [
    # example:
    # unstable.opencode
  ];

  home.file = {
  };

  programs = {
  };
}
