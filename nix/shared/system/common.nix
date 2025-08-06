# This file contains system-level settings that are common
# across all hosts (macOS and Linux).
{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    bandwhich
    gzip
  ];

  # Nix registry for easy access to stable and unstable packages
  #
  # Example usage:
  # nix shell u#neovim
  # nix run u#nodejs_22 -- --version
  #
  nix.registry = {
    n.to = {
      type = "path";
      path = inputs.nixpkgs;
    };
    u.to = {
      type = "path";
      path = inputs.nixpkgs-unstable;
    };
  };
}
