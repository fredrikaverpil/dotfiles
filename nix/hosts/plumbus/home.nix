{ config, pkgs, lib, ... }:

let
  # Use the same version as defined in configuration.nix
  homeManagerVersion = "25.05";
in
{
  imports = [
    ../../shared/home/darwin.nix
  ];

  home-manager.users.fredrik = {
    home.stateVersion = homeManagerVersion;
    
    home.packages = with pkgs; [
    ];
    
    home.file = {
    };
    
    programs = {
    };
  };
}
