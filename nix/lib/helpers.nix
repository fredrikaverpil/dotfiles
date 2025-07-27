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
      specialArgs = inputs // { inherit pkgs; };
      modules = [
        inputs.home-manager-unstable.darwinModules.home-manager
        ../shared/system/darwin.nix
        ../shared/system/common.nix
        ../hosts/${hostname}/configuration.nix
      ] ++ (if builtins.pathExists ../hosts/${hostname}/home.nix then [ ../hosts/${hostname}/home.nix ] else [ ]);
    };
}
