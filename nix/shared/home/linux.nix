{
  config,
  pkgs,
  lib,
  ...
}@args:
# This file contains home-manager settings specific to Linux systems.
let
  # The stable-pin nixpkgs (nixos-raspberrypi) ships a uv too old for the
  # relative-date `exclude-newer = "3d"` syntax in
  # stow/shared/.config/uv/uv.toml. Use the unstable input instead — it is
  # pinned in flake.lock and only changes on `rebuild.sh --update-unstable`.
  unstable = args.inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./common.nix
  ];

  # Linux-specific package-managed tools
  packageTools.npmPackages = [ ];
  packageTools.uvTools = [ ];

  home.packages = with pkgs; [
    lsof # List open files - essential for debugging file/network issues
    strace # System call tracer - useful for debugging application behavior
    unstable.uv # see let-block note above
    # Neovim from nixpkgs: bob (used on macOS) downloads prebuilt glibc
    # binaries which cannot run on NixOS (stub-ld). The shell/bin/nvim
    # wrapper falls back to the Nix profile binary automatically.
    unstable.neovim
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
