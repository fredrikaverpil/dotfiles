{ config, pkgs, lib, ... }:

{
  imports = [
    ../../shared/home/darwin.nix
  ];

  home-manager.users.fredrik = {
    home.stateVersion = "25.05";
    
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
