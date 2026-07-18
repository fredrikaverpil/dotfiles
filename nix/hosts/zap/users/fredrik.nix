{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Import helper functions for self-managed CLIs
  inherit (config.selfManagedCLIs.helpers) mkCurlInstaller mkWgetInstaller mkCustomInstaller;
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

  # zap-specific self-managed CLI tools
  selfManagedCLIs.clis = [
    (mkCurlInstaller "agent" "Cursor Agent" "https://cursor.com/install" "$HOME/.local/bin/agent")
  ];

  home.file = {
  };

  programs = {
  };
}
