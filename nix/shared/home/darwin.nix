{ config, pkgs, lib, ... }:

# This file contains home-manager settings specific to macOS.

{
  imports = [
    ./common.nix
  ];
  
  # Darwin-specific home-manager configuration
  # This gets imported by individual user configurations on Darwin systems
  
  # Darwin-specific packages
  home.packages = with pkgs; [
    # macOS-specific tools
    pngpaste  # for obsidian, macOS-only
  ];

  # macOS defaults
  home.keyboard = {
    enableKeyRepeat = true;
    keyRepeat = 1;
    initialKeyRepeat = 15;
  };

  # Darwin-specific program configurations
  programs = {
  };
}
