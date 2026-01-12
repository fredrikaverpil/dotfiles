# This file contains system-level settings specific to Linux/NixOS systems.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  options = {
    host.extraSystemPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional system packages for this host";
    };

    host.extraServices = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional services configuration for this host";
    };
  };

  config = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };

    # TODO: Security considerations:
    # - Consider enabling passwordless sudo only for specific commands
    security.sudo.wheelNeedsPassword = false;

    # Note: User configuration is handled by lib/users.nix

    # System-level packages
    environment.systemPackages =
      with pkgs;
      [
        vim # for recovery
      ]
      ++ config.host.extraSystemPackages;

    # Font management
    # NOTE: Berkeley Mono is installed manually, as it requires a license.
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono
      maple-mono.truetype
      maple-mono.variable
      noto-fonts-color-emoji # NOTE: takes a very long time to build
      nerd-fonts.symbols-only
    ];

    # Apply additional services configuration
    services = lib.mkMerge [
      { } # Default empty services
      config.host.extraServices
    ];
  };
}
