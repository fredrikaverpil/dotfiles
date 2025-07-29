{ config, pkgs, lib, inputs, ... }:

let
  stateVersions = {
    darwin = 6;
  };
in
{
  # Darwin state version 6 - defines system configuration schema/compatibility
  # See flake.nix for actual package channel selection (stable vs unstable)
  # Reference: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix
  system.stateVersion = stateVersions.darwin;

  networking.hostName = "zap";

  nixpkgs.hostPlatform = "aarch64-darwin";


  time.timeZone = "Europe/Stockholm";
  
  dotfiles.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true;
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
    };
  };

  dotfiles.extraPackages = with pkgs; [
  ];

  dotfiles.extraBrews = [
  ];

  dotfiles.extraCasks = [
    "podman-desktop"
    "pgadmin4"
  ];

}
