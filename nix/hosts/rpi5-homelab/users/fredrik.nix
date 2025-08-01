{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # Use opencode from unstable nixpkgs
    inputs.nixpkgs-unstable.legacyPackages.aarch64-linux.opencode
  ];

  home.file = {
  };

  programs = {
  };
}
