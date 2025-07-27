{ config, pkgs, lib, ... }:

{
  imports = [
    ../../shared/home-manager-darwin.nix
  ];

  home-manager.users.fredrik = {
    home.packages = with pkgs; [
    ];
    
    home.file = {
    };
    
    programs = {
    };
  };
}
