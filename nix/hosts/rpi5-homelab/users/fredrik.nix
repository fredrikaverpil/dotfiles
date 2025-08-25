{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  imports = [
    ../../../shared/home/linux.nix # Import shared Linux home-manager configuration
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    unstable.opencode
  ];

  home.file = {
  };

  programs = {
  };

  # NOTE: npmTools will not work when home-manager.useUserPackages is set to true,
  # and errors such as "Could not start dynamically linked executable" will occur.
  #
  # To enable, uncomment:
  # npmTools = lib.mkAfter [
  # ];
  #
  # Currently, disabled:
  npmTools = [ ];

}
