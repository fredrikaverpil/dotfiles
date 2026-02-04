# Package-managed CLI tools module
# Handles installation of tools managed by bun (npm) and uv (Python).
#
# Unlike self-managed CLIs (which install once and self-update), these tools
# require explicit upgrades via rebuild.sh --update-unstable or --update.
#
# npm tools (bun):
#   - Declared via packageTools.npmPackages option (mergeable per-host/platform)
#   - Each package installed globally via `bun install -g` (isolated in ~/.bun/)
#   - Binaries symlinked to ~/.bun/bin/ (added to PATH by this module)
#   - macOS only (npm binaries have dynamic linking issues on NixOS)
#   - Upgrade: npm-tools/install.sh --upgrade (runs bun update -g)
#
# Python tools (uv):
#   - Declared via packageTools.uvTools option (mergeable per-host/platform)
#   - Each tool gets its own isolated venv (managed by uv tool)
#   - Binaries symlinked to ~/.local/bin/ (already on PATH)
#   - Upgrade: uv-tools/install.sh --upgrade (runs uv tool upgrade --all)
#
# Usage:
#   # In any config level (common.nix, darwin.nix, host/users/user.nix):
#   packageTools.npmPackages = [
#     "@google/gemini-cli"
#     "@openai/codex"
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

  # Generate bun install -g commands from the merged npm packages option
  npmInstallScript = lib.concatMapStringsSep "\n" (pkg: ''
    if ${unstable.bun}/bin/bun pm bin -g &>/dev/null && \
       [[ -f "$(${unstable.bun}/bin/bun pm bin -g)/${lib.last (lib.splitString "/" pkg)}" ]]; then
      echo "Already installed: ${pkg}"
    else
      echo "Installing ${pkg}..."
      ${unstable.bun}/bin/bun install -g "${pkg}" || echo "Warning: Failed to install ${pkg}"
    fi
  '') config.packageTools.npmPackages;

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
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        npm packages to install globally via bun. Declarations merge across config levels.
        macOS only (npm binaries have dynamic linking issues on NixOS).
      '';
      example = [
        "@google/gemini-cli"
        "@openai/codex"
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
    # Add global bun bin directory to PATH (macOS only)
    # Linux/NixOS: npm binaries have dynamic linking issues and won't run
    home.sessionPath = lib.optionals pkgs.stdenv.isDarwin [
      "$HOME/.bun/bin"
    ];

    # Install package-managed tools on activation (install-if-missing, no upgrades)
    # Upgrades are triggered by rebuild.sh --update-unstable/--update
    home.activation.installPackageTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # --- uv tools (Python CLI tools, all platforms) ---
      ${uvToolInstallScript}

      # --- npm tools via bun (macOS only) ---
      CURRENT_PLATFORM="$(uname -s)"
      if [[ "$CURRENT_PLATFORM" == "Darwin" ]]; then
        ${npmInstallScript}
      fi
    '';
  };
}
