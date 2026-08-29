{ ... }:
{
  imports = [
    ../../../shared/home/linux.nix
  ];

  home.stateVersion = "26.05";

  packageTools.llmAgents = [ ];
}
