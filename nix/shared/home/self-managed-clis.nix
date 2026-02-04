# Self-managed CLI tools module
# Allows declaring CLI tools that install themselves and manage their own updates.
# Each config level (common, platform-specific, user-specific) can add to the list.
#
# Usage:
#   1. Add helpers to your let binding:
#      inherit (config.selfManagedCLIs.helpers) mkCurlInstaller mkWgetInstaller mkCustomInstaller;
#
#   2. Use helpers to declare CLIs:
#      selfManagedCLIs.clis = [
#        (mkCurlInstaller "claude" "Claude Code" "https://claude.ai/install.sh" "$HOME/.local/bin/claude")
#        (mkCurlInstaller "opencode" "OpenCode AI" "https://opencode.ai/install" "$HOME/.opencode/bin/opencode")
#      ];
#
# Available helpers:
#   - mkCurlInstaller name description url installPath
#       name:        The CLI command name (what you type in terminal, e.g., "claude", "opencode")
#       description: Human-readable description for logging (e.g., "Claude Code", "OpenCode AI")
#       url:         Download URL for the installer script
#       installPath: Full path where binary is installed (usually "$HOME/.local/bin/<name>", check installer docs)
#   - mkWgetInstaller: Same as mkCurlInstaller but uses wget
#   - mkCustomInstaller: Provide your own installation script
#
# IMPORTANT: Use the actual command name, not the product name!
#   Good: (mkCurlInstaller "agent" "Cursor Agent" "https://cursor.com/install" null)
#   Bad:  (mkCurlInstaller "cursor" "Cursor Agent" "https://cursor.com/install" null)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Helper functions for common installation patterns
  helpers = {
    # Most common: curl script and pipe to bash
    mkCurlInstaller = name: description: url: installPath: {
      inherit name description installPath;
      installScript = ''
        ${pkgs.curl}/bin/curl -fsSL ${url} | ${pkgs.bash}/bin/bash
      '';
    };

    # Alternative: wget script and pipe to bash
    mkWgetInstaller = name: description: url: installPath: {
      inherit name description installPath;
      installScript = ''
        ${pkgs.wget}/bin/wget -qO- ${url} | ${pkgs.bash}/bin/bash
      '';
    };

    # Custom installer script
    mkCustomInstaller = name: description: script: installPath: {
      inherit name description installPath;
      installScript = script;
    };

  };
in
{
  options.selfManagedCLIs = {
    helpers = lib.mkOption {
      type = lib.types.unspecified;
      default = helpers;
      internal = true;
      description = "Helper functions for creating self-managed CLI declarations";
    };

    clis = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "CLI command name to check (e.g., 'claude')";
              example = "claude";
            };
            installScript = lib.mkOption {
              type = lib.types.str;
              description = "Shell script to install the CLI if missing";
              example = "\${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | \${pkgs.bash}/bin/bash";
            };
            description = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Optional human-readable description for logging";
              example = "Claude Code";
            };
            installPath = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Full path where the binary is installed. If null, always runs installScript.";
              example = "\$HOME/.local/bin/claude";
            };
            platform = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Platform restriction (e.g., 'darwin', 'linux'). If null, runs on all platforms.";
              example = "darwin";
            };
          };
        }
      );
      default = [ ];
      description = ''
        List of self-managed CLI tools to install if not already present.
        These tools handle their own updates after initial installation.
        Useful for tools with native installers that auto-update (e.g., Claude Code).
      '';
    };
  };

  config = {
    home.activation.installSelfManagedCLIs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Provide comprehensive PATH for installer scripts (they may need various tools)
      export PATH="${pkgs.curl}/bin:${pkgs.wget}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.perl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.unzip}/bin:${pkgs.which}/bin:$PATH"

      ${lib.concatMapStringsSep "\n" (
        cli:
        if cli.platform != null then
          ''
            # Platform check for ${if cli.description != "" then cli.description else cli.name}
            CURRENT_PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"
            if [[ "$CURRENT_PLATFORM" == "${cli.platform}" ]]; then
              ${
                if cli.installPath == null then
                  ''
                    echo "Installing ${if cli.description != "" then cli.description else cli.name}..."
                    ${cli.installScript}
                  ''
                else
                  ''
                    if [[ ! -f "${cli.installPath}" ]]; then
                      echo "Installing ${if cli.description != "" then cli.description else cli.name}..."
                      ${cli.installScript}
                    fi
                  ''
              }
            else
              echo "⏭️  Skipping ${
                if cli.description != "" then cli.description else cli.name
              } (${cli.platform} only)"
            fi
          ''
        else
          # No platform restriction
          (
            if cli.installPath == null then
              ''
                echo "Installing ${if cli.description != "" then cli.description else cli.name}..."
                ${cli.installScript}
              ''
            else
              ''
                if [[ ! -f "${cli.installPath}" ]]; then
                  echo "Installing ${if cli.description != "" then cli.description else cli.name}..."
                  ${cli.installScript}
                fi
              ''
          )
      ) config.selfManagedCLIs.clis}
    '';
  };
}
