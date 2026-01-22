{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Add npm-tools bin directory to PATH (macOS only)
  # Linux/NixOS: npm binaries have dynamic linking issues and won't run
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.sessionPath = [ "$HOME/.dotfiles/npm-tools/node_modules/.bin" ];
  };
}
