{
  config,
  pkgs,
  lib,
  ...
} @ args:
# This file contains home-manager settings specific to Linux systems.
{
  imports = [
    ./common.nix
  ];

  home.packages = with pkgs; [
    lsof # List open files - essential for debugging file/network issues
    strace # System call tracer - useful for debugging application behavior
  ];

  # Additional packages are added in individual user configurations

  home.file = {
  };

  programs = {
  };
}
