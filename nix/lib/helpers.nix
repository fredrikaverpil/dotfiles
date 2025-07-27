{ inputs, ... }:
{
  mkDarwin = { configPath, ... }:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager-unstable.darwinModules.home-manager
        ../shared/users/default.nix
        ../shared/system/darwin.nix
        ../shared/system/common.nix
        configPath
      ] ++ (if builtins.pathExists (builtins.dirOf configPath + "/home.nix") then [ (builtins.dirOf configPath + "/home.nix") ] else [ ]);
    };

  # Standard NixOS systems (x86_64, regular ARM, etc.)
  # mkNixos = { configPath, ... }:
  #   inputs.nixpkgs.lib.nixosSystem {
  #     specialArgs = inputs // { 
  #       inherit (inputs) dotfiles; 
  #     };
  #     modules = [
  #       inputs.disko.nixosModules.disko
  #       inputs.home-manager.nixosModules.home-manager
  #       ../shared/users/default.nix
  #       ../shared/system/common.nix
  #       ../shared/system/linux.nix
  #       configPath
  #     ] ++ (if builtins.pathExists (builtins.dirOf configPath + "/home.nix") then [ (builtins.dirOf configPath + "/home.nix") ] else [ ])
  #       ++ (if builtins.pathExists (builtins.dirOf configPath + "/hardware.nix") then [ (builtins.dirOf configPath + "/hardware.nix") ] else [ ]);
  #   };

  mkRpiNixos = { configPath, ... }:
    inputs.nixos-raspberrypi.lib.nixosSystemFull {
      specialArgs = { 
        inherit inputs;
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
