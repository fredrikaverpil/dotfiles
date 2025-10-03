{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  options = {
    npmTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of npm packages to install globally";
      apply = lib.unique;
    };
  };

  # Only enable npm-based global tool installation on macOS (Darwin)
  # NixOS/Linux generic npm binaries are not runnable without wrapping.
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.sessionPath = [ "$HOME/.nix-npm-tools/bin" ];

    home.activation.installNpmTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -e
      export NPM_CONFIG_PREFIX="$HOME/.nix-npm-tools"
      export PATH="$HOME/.nix-npm-tools/bin:$PATH"

      mkdir -p "$HOME/.nix-npm-tools"

      NPM_TOOLS=(${lib.concatStringsSep " " (map (pkg: "\"${pkg}\"") config.npmTools)})

      echo "Installing/updating npm-based CLI tools..."
      export PATH="${pkgs.nodejs}/bin:$PATH"

      for tool in "''${NPM_TOOLS[@]}"; do
        echo "Processing $tool..."
        
        package_name=$(echo "$tool" | sed 's/@latest$//')
        
        # Check if package is outdated using the correct npm prefix
        if NPM_CONFIG_PREFIX="$HOME/.nix-npm-tools" npm outdated -g "$package_name" 2>/dev/null | grep -q "$package_name"; then
          echo "Updating $tool (outdated)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to update $tool"
          fi
        else
          # Try to install/update - npm will handle if it's already installed
          if ! $DRY_RUN_CMD npm install -g "$tool" >/dev/null 2>&1; then
            echo "Warning: Failed to install/update $tool"
          else
            echo "$tool ready"
          fi
        fi
      done

      echo "npm tools installation complete"
    '';
  };
}
