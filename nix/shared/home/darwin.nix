{ config, pkgs, lib, ... }:

# This file contains home-manager settings specific to macOS.

{
  options = {
    dotfiles.extraBrews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew packages for this host";
    };

    dotfiles.extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional homebrew casks for this host";
    };
  };
  imports = [
    ./common.nix
    ./homebrew.nix
    ../shell/aliases.nix
    ../shell/aliases-darwin.nix
    ../shell/exports.nix
  ];

  config = {

  home-manager.users.fredrik = { config, lib, ... }: {
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
    };
  };
}
