{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../../shared/home/darwin.nix
  ];

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    unstable.jira-cli-go
    unstable.openfga-cli
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://$HOME/.local/share/containers/podman/machine/podman.sock";
    TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/run/user/$UID/podman/podman.sock";
  };

  # zap-specific package-managed tools
  packageTools.npmPackages = [
    {
      package = "@googleworkspace/cli";
      bin = "gws";
    }
  ];
  packageTools.uvTools = [ ];

  # zap-specific LLM agent CLIs
  packageTools.llmAgents = [ "cursor-agent" ];

  home.file = {
  };

  programs = {
  };
}
