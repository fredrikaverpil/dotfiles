{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in {
  imports = [
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    unstable.podman
    unstable.podman-compose
  ];

  home.file = {
  };

  programs = {
  };
}
