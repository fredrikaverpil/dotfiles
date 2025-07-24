{ pkgs, ... }:

# macOS-specific shell aliases are managed by dotbot, not Nix.
# See shell/aliases.sh (platform-specific section) which is symlinked by dotbot and sourced by zshrc.
# This maintains the hybrid approach: Nix for packages, dotbot for dotfiles.

{
  home-manager.users.fredrik = {
    home.shellAliases = {
      # macOS-specific aliases are handled by dotbot - see shell/aliases.sh
    };
  };
}