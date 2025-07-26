{ pkgs, ... }:

# Shell exports and PATH configuration are managed by stow, not Nix.
# See shell/exports.sh which is symlinked by stow and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, stow for dotfiles.

{
  home-manager.users.fredrik = {
    home.sessionVariables = {
      # Environment variables are handled by stow - see shell/exports.sh
    };

    home.sessionPath = [
      # PATH configuration is handled by stow - see shell/exports.sh
    ];
  };
}
