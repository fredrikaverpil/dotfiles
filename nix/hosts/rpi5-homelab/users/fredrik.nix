{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    opencode-ai
  ];

  home.file = {
  };

  programs = {
  };
}
