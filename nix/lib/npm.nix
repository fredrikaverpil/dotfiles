{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    # Kept for backwards compatibility - no longer used
    # npm tools are now managed via npm-tools/package.json and bun.lockb
    npmTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Deprecated: npm tools are now managed via npm-tools/package.json";
      apply = lib.unique;
    };
  };

  # Add npm-tools bin directory to PATH (macOS only)
  # Linux/NixOS: npm binaries have dynamic linking issues and won't run
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.sessionPath = [ "$HOME/.dotfiles/npm-tools/node_modules/.bin" ];
  };
}
