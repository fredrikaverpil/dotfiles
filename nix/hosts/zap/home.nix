{ config, pkgs, lib, ... }:

{
  imports = [
    ../../shared/home-manager-darwin.nix
  ];

  home-manager.users.fredrik = {
    home.packages = with pkgs; [
      # Container CLI tools for development
      podman
      podman-compose
    ];
    
    home.file = {
    };
    
    programs = {
    };
  };
}
