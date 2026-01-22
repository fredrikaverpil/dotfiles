# Self-managed CLI tools module
# Allows declaring CLI tools that install themselves and manage their own updates.
# Each config level (common, platform-specific, user-specific) can add to the list.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.selfManagedCLIs = lib.mkOption {
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

  config = {
    home.activation.installSelfManagedCLIs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Provide comprehensive PATH for installer scripts (they may need various tools)
      export PATH="${pkgs.curl}/bin:${pkgs.wget}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.gawk}/bin:${pkgs.perl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.which}/bin:$PATH"

      ${lib.concatMapStringsSep "\n" (
        cli: ''
          # Check common installation locations directly (PATH may not be set during activation)
          if [[ ! -f "$HOME/.local/bin/${cli.name}" ]] && ! command -v ${cli.name} &>/dev/null; then
            echo "Installing ${if cli.description != "" then cli.description else cli.name}..."
            $DRY_RUN_CMD ${cli.installScript}
          fi
        ''
      ) config.selfManagedCLIs}
    '';
  };
}
