{
  config,
  pkgs,
  lib,
  ...
}:
# This file contains home-manager settings specific to macOS.
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    pngpaste # for obsidian, macOS-only
  ];

  programs = {
  };
}
