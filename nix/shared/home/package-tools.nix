# Package-managed CLI tools module
# Handles installation of tools managed by deno (npm) and uv (Python).
#
# Unlike self-managed CLIs (which install once and self-update), these tools
# require explicit upgrades via rebuild.sh --update-unstable or --update.
#
# npm tools (deno):
#   - Declared via packageTools.npmPackages option (mergeable per-host/platform)
#   - Each package installed globally via `deno install --global npm:<pkg>`
#     (isolated in ~/.deno/)
#   - Shims placed in ~/.deno/bin/ (added to PATH by this module)
#   - macOS only for now (Linux support pending validation)
#   - Upgrade: rebuild.sh --update-unstable or --update (runs the generated
#     npm-tools-upgrade script)
#
# Python tools (uv):
#   - Declared via packageTools.uvTools option (mergeable per-host/platform)
#   - Each tool gets its own isolated venv (managed by uv tool)
#   - Binaries symlinked to ~/.local/bin/ (already on PATH)
#   - Upgrade: rebuild.sh --update-unstable or --update (runs uv tool upgrade --all)
#
# Usage:
#   # In any config level (common.nix, darwin.nix, host/users/user.nix):
#   packageTools.npmPackages = [
#     { package = "@google/gemini-cli"; bin = "gemini"; }
#     { package = "@openai/codex"; bin = "codex"; }
#   ];
#   packageTools.uvTools = [
#     { package = "sqlit-tui"; }
#     { package = "sqlit-tui"; inject = ["google-cloud-bigquery"]; }
#     { package = "some-tool"; extras = "ssh,cloud"; }
#   ];
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Generate deno install commands from the merged npm packages option
  npmInstallScript = lib.concatMapStringsSep "\n" (tool: ''
    if [[ -f "$HOME/.deno/bin/${tool.bin}" ]]; then
      echo "Already installed: ${tool.package}"
    else
      echo "Installing ${tool.package}..."
      ${unstable.deno}/bin/deno install --global --allow-all --force \
        --name "${tool.bin}" "npm:${tool.package}" \
        || echo "Warning: Failed to install ${tool.package}"
    fi
  '') config.packageTools.npmPackages;

  # Upgrade helper for rebuild.sh --update-unstable/--update: deno has no
  # equivalent of `bun update -g`, so force-reinstall every declared package
  # at its latest version (--reload bypasses the cached registry response).
  npmUpgradeScript = pkgs.writeShellScriptBin "npm-tools-upgrade" (
    lib.concatMapStringsSep "\n" (tool: ''
      echo "Upgrading ${tool.package}..."
      ${unstable.deno}/bin/deno install --global --allow-all --force --reload \
        --name "${tool.bin}" "npm:${tool.package}"
    '') config.packageTools.npmPackages
  );

  # Generate uv tool install commands from the merged uv tools option
  uvToolInstallScript = lib.concatMapStringsSep "\n" (
    tool:
    let
      spec = if tool.extras != "" then "${tool.package}[${tool.extras}]" else tool.package;
      installCmd = ''
        if ${pkgs.uv}/bin/uv tool list 2>/dev/null | grep -q "^${tool.package} "; then
          echo "Already installed: ${tool.package}"
        else
          echo "Installing ${tool.package}..."
          ${pkgs.uv}/bin/uv tool install "${spec}"
        fi
      '';
      injectCmds = lib.concatMapStringsSep "\n" (dep: ''
        echo "Injecting ${dep} into ${tool.package}..."
        ${pkgs.uv}/bin/uv tool inject "${tool.package}" "${dep}" 2>/dev/null || true
      '') tool.inject;
    in
    installCmd + injectCmds
  ) config.packageTools.uvTools;
in
{
  options.packageTools = {
    npmPackages = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.str;
              description = "npm package name (e.g., '@google/gemini-cli')";
              example = "@google/gemini-cli";
            };
            bin = lib.mkOption {
              type = lib.types.str;
              description = ''
                Executable name the package provides (its package.json "bin" entry).
                Used to name the deno shim and to detect existing installs.
              '';
              example = "gemini";
            };
          };
        }
      );
      default = [ ];
      description = ''
        npm packages to install globally via deno. Declarations merge across config levels.
        macOS only for now (Linux support pending validation).
      '';
      example = [
        {
          package = "@google/gemini-cli";
          bin = "gemini";
        }
      ];
      apply = lib.unique;
    };

    uvTools = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.str;
              description = "PyPI package name (e.g., 'sqlit-tui')";
              example = "sqlit-tui";
            };
            extras = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Comma-separated extras (e.g., 'ssh,cloud')";
              example = "ssh";
            };
            inject = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Packages to inject into the tool's isolated venv";
              example = [
                "google-cloud-bigquery"
                "psycopg2-binary"
              ];
            };
          };
        }
      );
      default = [ ];
      description = ''
        Python CLI tools to install via uv tool.
        Each tool gets its own isolated venv. Binaries are symlinked to ~/.local/bin/.
        Declarations merge across config levels (common, platform, host).
      '';
    };
  };

  config = {
    # Add deno's global shim directory to PATH (macOS only for now)
    home.sessionPath = lib.optionals pkgs.stdenv.isDarwin [
      "$HOME/.deno/bin"
    ];

    # Upgrade helper invoked by rebuild.sh --update-unstable/--update
    home.packages = lib.optionals (pkgs.stdenv.isDarwin && config.packageTools.npmPackages != [ ]) [
      npmUpgradeScript
    ];

    # Install package-managed tools on activation (install-if-missing, no upgrades)
    # Upgrades are triggered by rebuild.sh --update-unstable/--update
    home.activation.installPackageTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # --- uv tools (Python CLI tools, all platforms) ---
      ${uvToolInstallScript}

      # --- npm tools via deno (macOS only for now) ---
      CURRENT_PLATFORM="$(uname -s)"
      if [[ "$CURRENT_PLATFORM" == "Darwin" ]]; then
        ${npmInstallScript}
      fi
    '';
  };
}
