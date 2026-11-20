# LLM agent CLIs from the numtide/llm-agents.nix flake input.
#
# These are plain Nix packages (patched, binary-cached on cache.numtide.com)
# and upgrade with the flake input via `nix flake update llm-agents`, then
# rebuild.
#
# Usage:
#   # In any config level (common.nix, darwin.nix, host/users/user.nix):
#   llmAgents = [
#     "claude-code"
#     "opencode"
#   ];
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  llmAgentPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.llmAgents = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      LLM agent CLIs to install from the numtide/llm-agents.nix flake input.
      Each entry must be an attribute name in that flake's packages set
      (e.g., "claude-code", "opencode"). Declarations merge across config
      levels (common, platform, host).
    '';
    example = [
      "claude-code"
      "opencode"
    ];
    apply = lib.unique;
  };

  config = {
    home.packages = map (name: llmAgentPackages.${name}) config.llmAgents;

    # Antigravity's terminal sandbox (sbox) mounts FHS paths, not /nix/store,
    # so `exec /proc/self/exe` fails on NixOS unless these are in read_file
    # allow rules. Merged into the live file rather than stowed because agy
    # also persists host-local state (trustedWorkspaces, model) in it.
    home.activation.antigravitySettings =
      lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && builtins.elem "antigravity-cli" config.llmAgents)
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            settings="$HOME/.gemini/antigravity-cli/settings.json"
            if [ -n "''${DRY_RUN_CMD:-}" ]; then
              echo "Would merge NixOS sandbox read_file rules into $settings"
            else
              mkdir -p "$(dirname "$settings")"
              [ -f "$settings" ] || printf '{}\n' > "$settings"
              tmp="$(mktemp "$(dirname "$settings")/.settings.json.XXXXXX")"
              if ${pkgs.jq}/bin/jq '
                .permissions.allow = ((.permissions.allow // []) + [
                  "read_file(/nix/store)",
                  "read_file(/run/current-system)"
                ] | unique)
              ' "$settings" > "$tmp"; then
                mv "$tmp" "$settings"
              else
                rm -f "$tmp"
                exit 1
              fi
            fi
          ''
        );
  };
}
