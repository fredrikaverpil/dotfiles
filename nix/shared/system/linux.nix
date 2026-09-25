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

    host.chromiumFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra Chromium --enable-features for this host";
    };

    host.notificationRules = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            match = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              example = {
                app = "^Slack$";
                summary = " in #?alerts$";
              };
              description = "JavaScript regexes keyed by notification field (app, summary, body); the rule applies when all match";
            };
            critical = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Raise to critical, so it sticks and bypasses Do Not Disturb";
            };
            dedup = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    group = lib.mkOption {
                      type = lib.types.str;
                      description = "One event reported by several apps";
                    };
                    keep = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Show this copy and dismiss the group's others; they are held briefly in case it arrives";
                    };
                  };
                }
              );
              default = null;
              description = "Show one copy of an event reported by several apps";
            };
            icon = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression "./github.svg";
              description = "Icon shown in place of the notification's, such as the sender an app relays for; the notification's own moves to a badge on its corner";
            };
          };
        }
      );
      default = [ ];
      description = "Kaizen's notification rules";
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
    environment.systemPackages =
      with pkgs;
      [
        vim # for recovery
      ]
      ++ config.host.extraSystemPackages;

    # Apply additional services configuration
    services = lib.mkMerge [
      { } # Default empty services
      config.host.extraServices
    ];
  };
}
