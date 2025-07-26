{ pkgs, ... }:

# Shell aliases are managed by stow, not Nix.
# See shell/aliases.sh which is symlinked by stow and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, stow for dotfiles.

{
  home-manager.users.fredrik = {
    home.shellAliases = {
      # Aliases are handled by stow - see shell/aliases.sh
    };
  };
}
