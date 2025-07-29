{ config, pkgs, lib, inputs, ... }:

let
  stateVersions = {
    darwin = 6;
  };
in
{
  system.stateVersion = stateVersions.darwin;

  networking.hostName = "plumbus";

  nixpkgs.hostPlatform = "aarch64-darwin";

  time.timeZone = "Europe/Stockholm";
  
  dotfiles.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true;
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
      groups = [ "docker" ];
    };
  };

  dotfiles.extraPackages = with pkgs; [
  ];

  dotfiles.extraBrews = [
  ];

  dotfiles.extraCasks = [
    "orbstack"
    "raycast"
  ];

}
