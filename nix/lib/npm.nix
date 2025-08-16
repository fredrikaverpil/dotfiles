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
        
        if ! command -v "$binary_name" &> /dev/null; then
          echo "Installing $tool (not found)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to install $tool"
          fi
        elif npm outdated -g "$package_name" 2>/dev/null | grep -q "$package_name"; then
          echo "Updating $tool (outdated)..."
          if ! $DRY_RUN_CMD npm install -g "$tool"; then
            echo "Warning: Failed to update $tool"
          fi
        fi
      done

      echo "npm tools installation complete"
    '';
  };
}
