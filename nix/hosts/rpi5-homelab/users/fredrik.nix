{ config, pkgs, lib, ... }:

# Home-manager configuration for Fredrik on rpi5-homelab
# This file defines user-level packages and configurations for the Raspberry Pi

{
  imports = [
    ../../../shared/home/linux.nix  # Import shared Linux home-manager configuration
  ];

  # Set the state version for home-manager
  home.stateVersion = "25.05";
  
  # Raspberry Pi specific packages for homelab use
  home.packages = with pkgs; [
  ];
  
  # Pi-specific configurations
  # Add any Raspberry Pi specific dotfiles or configurations here
  home.file = {
  };
  
  # Pi-specific program configurations
  programs = {
  };
}