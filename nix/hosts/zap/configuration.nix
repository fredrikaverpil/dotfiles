{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  stateVersions = {
    darwin = 6;
  };
in
{
  # Darwin state version 6 - defines system configuration schema/compatibility
  # See flake.nix for actual package channel selection (stable vs unstable)
  # Reference: https://github.com/LnL7/nix-darwin/blob/master/modules/system/default.nix
  system.stateVersion = stateVersions.darwin;

  networking.hostName = "zap";

  nixpkgs.hostPlatform = "aarch64-darwin";

  time.timeZone = "Europe/Stockholm";

  host.users = {
    fredrik = {
      isAdmin = true;
      isPrimary = true;
      shell = "zsh";
      homeConfig = ./users/fredrik.nix;
    };
  };

  host.extraPackages = with pkgs; [
  ];

  host.extraTaps = [
    "libkrun/krun" # krunkit
  ];

  host.extraBrews = [
    # podman added here as it also adds podman-mac-helper (not installed if installed via nix)
    "podman"
    "podman-compose"
    "libkrun/krun/krunkit" # required by podman to create VMs
  ];

  host.extraCasks = [
    "claude-devtools"
    "cursor"
    "podman-desktop"

    # NOTE: if cursor-cli errors on macOS quarantine error and "ERR_DLOPEN_FAILED" for node_sqlite3.node:
    # 1) Locate the latest installed cask dir
    # $ latest=$(ls -dt /opt/homebrew/Caskroom/cursor-cli/* | head -1); echo "$latest"
    # 2) (Optional) Inspect quarantine flag
    # $ xattr -l "$latest/dist-package/build/node_sqlite3.node" || true
    # 3) Remove quarantine recursively
    # $ sudo xattr -r -d com.apple.quarantine "$latest"
    "cursor-cli"

    "cyberduck"
    "pgadmin4"
    "podman-desktop"
    "spotify"
    # Disabled because the upstream app repo is archived; use EtienneLescot/openscreen instead.
    # "siddharthvaddem/openscreen/openscreen"
  ];

  host.extraMasApps = {
    "FileZilla Pro" = 1298486723;
  };
}
