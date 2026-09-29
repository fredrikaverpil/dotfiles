{
  config,
  pkgs,
  lib,
  ...
}:
# This file contains home-manager settings specific to Linux systems.
{
  imports = [
    ./common.nix
  ];

  llmAgents = [ ];

  home.packages = with pkgs; [
    btop
    lsof # List open files - essential for debugging file/network issues
  ];

  home.file = {
    # Assert that ~/.nix-profile points at the active per-user profile on
    # every activation. With home-manager.useUserPackages = true, packages
    # land in /etc/profiles/per-user/<user>; shell scripts (shell/sourcing.sh,
    # shell/exports.sh) reference ~/.nix-profile for completions and
    # hm-session-vars, so the symlink must never dangle or go stale. (Pointing
    # it at ~/.local/state/nix/profiles/home-manager/home-path instead would
    # freeze it at an old generation and shadow current packages on PATH.)
    ".nix-profile".source =
      config.lib.file.mkOutOfStoreSymlink "/etc/profiles/per-user/${config.home.username}";
  };

  programs = {
  };

}
