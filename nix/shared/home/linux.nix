{ config, pkgs, lib, ... }@args:

# This file contains home-manager settings specific to Linux systems.
# It imports common configurations and adds Linux-specific packages and settings.

{
  imports = [
    ./common.nix    # Cross-platform home-manager configuration
  ];
  
  # Linux-specific home-manager configuration
  # This gets imported by individual user configurations on Linux systems
    # Linux-specific packages not available or needed on macOS
    home.packages = with pkgs; [
      # System debugging and monitoring tools
      lsof    # List open files - essential for debugging file/network issues
      strace  # System call tracer - useful for debugging application behavior
      
      # Additional Linux-specific tools can be added here as needed
      # Examples: htop, iotop, nethogs, etc.
    ];
    
    # Note: Additional packages are now added in individual user configurations

    # Linux-specific dotfiles and configurations
    home.file = {
    };

  # Linux-specific program configurations
  programs = {
  };
}
