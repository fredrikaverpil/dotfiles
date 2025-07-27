# Centralized user configuration for all platforms
# This module defines the primary user and provides consistent user setup across Darwin and Linux

{ config, pkgs, lib, ... }:

{
  options = {
    users.primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "fredrik";
      description = "Primary user for this system";
    };

    users.primaryUserHome = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isDarwin then "/Users/${config.users.primaryUser}" else "/home/${config.users.primaryUser}";
      description = "Home directory path for the primary user";
    };
  };

  config = {
    # Enable zsh system-wide for consistent shell experience
    programs.zsh.enable = true;

    # Platform-specific user configuration
    users.users.${config.users.primaryUser} = lib.mkMerge [
      # Common user settings across all platforms
      {
        shell = pkgs.zsh;
      }
      
      # Darwin-specific user settings
      (lib.mkIf pkgs.stdenv.isDarwin {
        name = config.users.primaryUser;
        home = config.users.primaryUserHome;
      })
      
      # Linux-specific user settings
      (lib.mkIf pkgs.stdenv.isLinux {
        isNormalUser = true;
        extraGroups = [ 
          "wheel"          # Administrative privileges (sudo access)
          "networkmanager" # Network configuration permissions
          "docker"         # Docker daemon access for container management
        ];
        # Security: Change this password immediately after first login
        initialPassword = "changeme";
        
        # SSH public key authentication (recommended for security)
        # Uncomment and add your SSH public keys for passwordless login
        # openssh.authorizedKeys.keys = [
        #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key-here"
        #   "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... another-key-here"
        # ];
      })
    ];

    # Note: Darwin's system.primaryUser is set by the Darwin system configuration

    # Note: Linux-specific security settings are handled in shared/system/linux.nix
  };
}