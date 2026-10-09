{ pkgs, inputs, ... }:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/linux.nix
    ../../../shared/home/linux-desktop.nix
  ];

  home.stateVersion = "26.05";

  # Host-only user packages; shared ones live in nix/shared/home/.
  home.packages = with pkgs; [
    unstable.neovim
  ];

  llmAgents = [ ];

  home.file = { };

  programs = { };
}
