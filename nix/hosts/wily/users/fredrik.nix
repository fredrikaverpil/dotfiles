{
  config,
  lib,
  pkgs,
  ...
}:
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

  programs = {
    # `?submodules=1` pulls in the private submodule at nix/hosts/wily/einride;
    # `inputs.self.submodules` cannot be used, it makes public clones and CI
    # try to fetch the private repo.
    nh.flake = lib.mkForce "${config.home.homeDirectory}/.dotfiles?submodules=1";
  };
}
