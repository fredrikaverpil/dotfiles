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
  ];

  home.file = {
  };

  programs = {
  };

}
