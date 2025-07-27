# This file contains system-level settings specific to Linux/NixOS systems.

{ config, pkgs, lib, inputs, ... }:

{
  options = {
    dotfiles.extraSystemPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional system packages for this host";
    };

    dotfiles.extraServices = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional services configuration for this host";
    };
  };

  config = {
    # Basic NixOS system settings
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };

  # Linux-specific security settings
  security.sudo.wheelNeedsPassword = false;
  
  # Note: User configuration is now handled by shared/users/default.nix

  # System-level packages (very few)
  environment.systemPackages = with pkgs; [
    vim # for recovery
  ] ++ config.dotfiles.extraSystemPackages;

  # Nix registry for easy access to stable and unstable packages
  # Note: This would require inputs to be passed as specialArgs
  # nix.registry = {
  #   n.to = {
  #     type = "path";
  #     path = inputs.nixpkgs;
  #   };
  #   u.to = {
  #     type = "path";
  #     path = inputs.nixos-unstable;
  #   };
  # };

  # Font management
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    maple-mono.NF
    noto-fonts-emoji
    nerd-fonts.symbols-only
  ];

  # Apply additional services configuration
  services = lib.mkMerge [ 
    { } # Default empty services
    config.dotfiles.extraServices
  ];
  };
}
