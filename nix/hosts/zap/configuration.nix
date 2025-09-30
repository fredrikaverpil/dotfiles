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

  host.extraBrews = [
    # podman added here as it also adds podman-mac-helper (not installed if installed via nix)
    "podman"
    "podman-compose"
    "vfkit" # for podman

  ];

  host.extraCasks = [
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
    "yubico-yubikey-manager"
  ];

  host.extraMasApps = {
    "FileZilla Pro" = 1298486723;
  };
}
