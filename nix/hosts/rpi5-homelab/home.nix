{ config, pkgs, lib, ... }:

# Home-manager configuration specific to rpi5-homelab
# This file defines user-level packages and configurations for the Raspberry Pi

{
  imports = [
    ../../shared/home-manager-linux.nix  # Import shared Linux home-manager configuration
  ];

  # Host-specific home-manager configuration for rpi5-homelab
  home-manager.users.fredrik = {
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
  };
}
