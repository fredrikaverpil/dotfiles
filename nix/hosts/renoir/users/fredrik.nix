{ pkgs, ... }:
{
  imports = [
    ../../../shared/home/linux.nix
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [ ];

  home.sessionVariables = { };

  llmAgents = [ ];

  home.file = { };

  programs = { };
}
