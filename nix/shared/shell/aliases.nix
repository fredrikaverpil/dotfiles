{ pkgs, ... }:

# Shell aliases are managed by dotbot, not Nix.
# See shell/aliases.sh which is symlinked by dotbot and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, dotbot for dotfiles.

{
  home-manager.users.fredrik = {
    home.shellAliases = {
      # Aliases are handled by dotbot - see shell/aliases.sh
    };
  };
}
