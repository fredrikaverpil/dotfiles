{ inputs, ... }:
{
  imports = [
    ../../../shared/home/linux.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.stateVersion = "26.05";

  # Zen's normal release channel is called Beta upstream; Twilight is nightly.
  # The module also keeps Zen as the XDG and $BROWSER default for this user.
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
  };

  packageTools.llmAgents = [ ];
}
