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

  config = {
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
        binary_name=$(basename "$package_name")
        binary_path="$HOME/.nix-npm-tools/bin/$binary_name"
        
        if [[ ! -f "$binary_path" ]]; then
          echo "Installing $tool (not found)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to install $tool"
          fi
        else
          # Check if package is outdated using the correct npm prefix
          if NPM_CONFIG_PREFIX="$HOME/.nix-npm-tools" npm outdated -g "$package_name" 2>/dev/null | grep -q "$package_name"; then
            echo "Updating $tool (outdated)..."
            if ! $DRY_RUN_CMD npm install -g "$tool"; then
              echo "Warning: Failed to update $tool"
            fi
          else
            echo "Skipping $tool (up to date)..."
          fi
        fi
      done

      echo "npm tools installation complete"
    '';
  };
}
