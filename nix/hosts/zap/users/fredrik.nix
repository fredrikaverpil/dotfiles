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
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    unstable.podman
    unstable.podman-compose
    unstable.jira-cli-go
  ];

  home.file = {
  };

  programs = {
  };

  npmTools = lib.mkAfter [
    # "@google/gemini-cli@latest"
  ];
}
