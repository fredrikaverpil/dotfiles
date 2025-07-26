{ pkgs, ... }:

# macOS-specific shell aliases are managed by stow, not Nix.
# See shell/aliases.sh (platform-specific section) which is symlinked by stow and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, stow for dotfiles.

{
  home-manager.users.fredrik = {
    home.shellAliases = {
      # macOS-specific aliases are handled by stow - see shell/aliases.sh
    };
  };
}