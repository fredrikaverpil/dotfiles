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
    unstable.jira-cli-go
  ];

  home.file = {
  };

  programs = {
  };

  # NOTE: npmTools will not work when home-manager.useUserPackages is set to true,
  # and errors such as "Could not start dynamically linked executable" will occur.
  npmTools = lib.mkAfter [
  ];
}
