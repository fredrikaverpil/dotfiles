{ inputs, outputs, ... }:
{
  mkDarwin = { hostname, system ? "aarch64-darwin", ... }:
  let
    inherit (inputs.nixpkgs-unstable.lib) mkDefault;
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
    };
  in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = inputs // { 
        inherit pkgs;
        dotfiles = inputs.dotfiles;
      };
      modules = [
        inputs.home-manager-unstable.darwinModules.home-manager
        ../shared/darwin-system.nix
        ../shared/common-packages.nix
        ../hosts/${hostname}/configuration.nix
      ];
    };
}
