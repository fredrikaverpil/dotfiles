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
    host.chromiumFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra Chromium --enable-features for this host";
    };
  };

  config = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Required for flake.nix's nixConfig.extra-substituters to be honored —
    # untrusted users get them silently dropped, and everything from
    # cache.numtide.com (llm-agents) then builds from source.
    nix.settings.trusted-users = [ "fredrik" ]; # merges with the "root" default

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
    };

    # Wheel users authenticate before privilege escalation. A fresh login
    # session therefore has no ambient root-equivalent access.
    security.sudo.wheelNeedsPassword = true;

    # Note: User configuration is handled by lib/users.nix

    # System-level packages
    environment.systemPackages = with pkgs; [
      vim # for recovery
    ];
  };
}
