{ inputs, ... }:
{
  mkDarwin = { hostname, system ? "aarch64-darwin", ... }:
  let
    inherit (inputs.nixpkgs-unstable.lib) mkDefault;
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
    };
  in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs pkgs; };
      modules = [
        inputs.home-manager-unstable.darwinModules.home-manager
        ../shared/system/darwin.nix
        ../shared/system/common.nix
        ../hosts/${hostname}/configuration.nix
      ] ++ (if builtins.pathExists ../hosts/${hostname}/home.nix then [ ../hosts/${hostname}/home.nix ] else [ ]);
    };

  mkNixos = { hostname, system ? "aarch64-linux", ... }:
    inputs.nixos-raspberrypi.lib.nixosSystemFull {
      specialArgs = inputs // { 
        nixos-raspberrypi = inputs.nixos-raspberrypi; 
        inherit (inputs) dotfiles; 
      };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        ../shared/system/common.nix
        ../shared/system/linux.nix
        ../hosts/${hostname}/configuration.nix
      ] ++ (if builtins.pathExists ../hosts/${hostname}/home.nix then [ ../hosts/${hostname}/home.nix ] else [ ])
        ++ (if builtins.pathExists ../hosts/${hostname}/hardware.nix then [ ../hosts/${hostname}/hardware.nix ] else [ ]);
    };
}
