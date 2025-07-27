{ inputs, ... }:
{
  mkDarwin = { configPath, system ? "aarch64-darwin", ... }:
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
        ../shared/users/default.nix
        ../shared/system/darwin.nix
        ../shared/system/common.nix
        configPath
      ] ++ (if builtins.pathExists (builtins.dirOf configPath + "/home.nix") then [ (builtins.dirOf configPath + "/home.nix") ] else [ ]);
    };

  mkNixos = { configPath, system ? "aarch64-linux", ... }:
    inputs.nixos-raspberrypi.lib.nixosSystemFull {
      specialArgs = inputs // { 
        nixos-raspberrypi = inputs.nixos-raspberrypi; 
        inherit (inputs) dotfiles; 
      };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        ../shared/users/default.nix
        ../shared/system/common.nix
        ../shared/system/linux.nix
        configPath
      ] ++ (if builtins.pathExists (builtins.dirOf configPath + "/home.nix") then [ (builtins.dirOf configPath + "/home.nix") ] else [ ])
        ++ (if builtins.pathExists (builtins.dirOf configPath + "/hardware.nix") then [ (builtins.dirOf configPath + "/hardware.nix") ] else [ ]);
    };
}
