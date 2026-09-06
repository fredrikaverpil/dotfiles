{ inputs, ... }:
{
  imports = [
    ../../../shared/home/linux.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.stateVersion = "26.05";

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  packageTools.llmAgents = [ ];
}
