{ inputs, pkgs, ... }:
{
  imports = [
    ../../../shared/home/linux.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [ ];

  home.sessionVariables = { };

  llmAgents = [ ];

  home.file = { };

  programs = {
    # Not in desktop.nix: zen-browser ships only a home-manager module.
    zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };
  };
}
