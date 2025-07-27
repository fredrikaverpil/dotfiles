# Multi-user configuration for all platforms
# This module defines multiple users and provides consistent user setup across Darwin and Linux

{ config, pkgs, lib, ... }:

{
  options = {
    dotfiles.users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          isAdmin = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this user has administrative privileges";
          };
          
          isPrimary = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this is the primary user (for Darwin system defaults)";
          };
          
          shell = lib.mkOption {
            type = lib.types.str;
            default = "zsh";
            description = "Default shell for this user";
          };
          
          homeConfig = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to user-specific home-manager configuration";
          };
          
          groups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional groups for this user";
          };
          
          sshKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "SSH public keys for this user";
          };
        };
      });
      default = {};
      description = "User configurations for this system";
    };
  };

  config = {
    # Enable zsh system-wide for consistent shell experience
    programs.zsh.enable = true;

    # Create system users for each defined user
    users.users = lib.mapAttrs (username: userConfig: lib.mkMerge [
      # Common user settings across all platforms
      {
        shell = pkgs.${userConfig.shell};
      }
      
      # Darwin-specific user settings
      (lib.mkIf pkgs.stdenv.isDarwin {
        name = username;
        home = "/Users/${username}";
      })
      
      # Linux-specific user settings
      (lib.mkIf pkgs.stdenv.isLinux {
        isNormalUser = true;
        extraGroups = userConfig.groups ++ (lib.optional userConfig.isAdmin "wheel");
        # Security: Change this password immediately after first login
        initialPassword = "changeme";
        
        # SSH public key authentication
        openssh.authorizedKeys.keys = userConfig.sshKeys;
      })
    ]) config.dotfiles.users;

    # Home-manager configuration for each user with a homeConfig
    home-manager.users = lib.mapAttrs (username: userConfig: 
      if userConfig.homeConfig != null 
      then import userConfig.homeConfig
      else {}
    ) config.dotfiles.users;

    # Note: Darwin's system.primaryUser is set by the Darwin system configuration
    # Note: Linux-specific security settings are handled in shared/system/linux.nix
  };
}