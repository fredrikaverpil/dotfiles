{ config, pkgs, lib, ... }: {
  # System-level package configuration for rpi5-homelab
  # Defines packages that need to be available system-wide
  # Most user packages are managed through home-manager in home.nix
  
  environment.systemPackages = with pkgs; [
    # Essential system administration tools
    # These are kept minimal as most tools are managed via home-manager
    
    # System recovery and maintenance tools
    vim             # Essential editor for emergency situations
    curl            # Network tool for downloading/API calls
    wget            # File download utility
    
    # Container tools for homelab services
    docker          # Container runtime
    docker-compose  # Container orchestration
    
    # Hardware-specific utilities for Raspberry Pi
    # These may be provided by nixos-raspberrypi modules
    
  ] ++ (with pkgs.rpi or { }; [
    # Raspberry Pi optimized packages when available
    # The nixos-raspberrypi flake may provide Pi-specific optimizations
    # These packages are conditionally included if available
    
    # Examples of Pi-specific tools that might be available:
    # - GPIO control utilities
    # - Hardware monitoring tools
    # - Pi-specific system utilities
  ]);
}
