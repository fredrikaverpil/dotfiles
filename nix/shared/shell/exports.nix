{ pkgs, ... }:

# Shell exports and PATH configuration are managed by dotbot, not Nix.
# See shell/exports.sh which is symlinked by dotbot and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, dotbot for dotfiles.

{
  home-manager.users.fredrik = {
    home.sessionVariables = {
      # Environment variables are handled by dotbot - see shell/exports.sh
    };

    home.sessionPath = [
      # PATH configuration is handled by dotbot - see shell/exports.sh
    ];
  };
}
