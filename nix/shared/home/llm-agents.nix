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

  config.home.packages = map (name: llmAgentPackages.${name}) config.llmAgents;
}
