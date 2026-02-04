{
  config,
  pkgs,
  lib,
  ...
}@args:
# This file contains home-manager settings specific to Linux systems.
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
  ];

  home.file = {
  };

  programs = {
  };

}
