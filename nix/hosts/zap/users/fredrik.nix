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
  ];

  # zap-specific package-managed tools
  packageTools.npmPackages = [ ];
  packageTools.uvTools = [ ];

  # zap-specific self-managed CLI tools
  selfManagedCLIs.clis = [
    (mkCurlInstaller "agent" "Cursor Agent" "https://cursor.com/install" "$HOME/.local/bin/agent")
    (mkCurlInstaller "slack" "Slack CLI" "https://downloads.slack-edge.com/slack-cli/install.sh" "$HOME/.slack/bin/slack")
  ];

  home.file = {
  };

  programs = {
  };
}
