{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    npmTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of npm packages to install globally (via bun)";
      apply = lib.unique;
    };
  };

  # Only enable bun-based global tool installation on macOS (Darwin)
  # NixOS/Linux generic npm binaries are not runnable without wrapping.
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.sessionPath = [ "$HOME/.bun/bin" ];

    home.activation.installNpmTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -e
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$HOME/.bun/bin:$PATH"

      mkdir -p "$HOME/.bun/bin"

      NPM_TOOLS=(${lib.concatStringsSep " " (map (pkg: "\"${pkg}\"") config.npmTools)})

      echo "Installing/updating npm-based CLI tools (using bun)..."
      export PATH="${pkgs.bun}/bin:$PATH"

      for tool in "''${NPM_TOOLS[@]}"; do
        echo "Processing $tool..."
        if ! $DRY_RUN_CMD bun install -g "$tool" 2>/dev/null; then
          echo "Warning: Failed to install/update $tool"
        else
          echo "$tool ready"
        fi
      done

      echo "npm tools installation complete"
    '';
  };
}
