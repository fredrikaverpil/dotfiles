{inputs, ...}: {
  mkDarwin = {configPath, ...}:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules =
        [
          {nixpkgs.overlays = [(import ../shared/overlays)];}
          inputs.home-manager-unstable.darwinModules.home-manager # unstable pkgs
          ./users.nix
          ../shared/system/darwin.nix
          ../shared/system/common.nix
          configPath
        ]
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/home.nix")
          then [(builtins.dirOf configPath + "/home.nix")]
          else []
        );
    };

  # Standard NixOS systems (x86_64, regular ARM, etc.)
  # Built from nixpkgs-unstable; set `nixpkgs.hostPlatform` in the host's
  # configuration.nix, the same way mkRpiNixos hosts do.
  mkNixos = {configPath, ...}:
    inputs.nixpkgs-unstable.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules =
        [
          {nixpkgs.overlays = [(import ../shared/overlays)];}
          inputs.home-manager-unstable.nixosModules.home-manager
          ./users.nix
          ../shared/system/common.nix
          ../shared/system/linux.nix
          configPath
        ]
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/home.nix")
          then [(builtins.dirOf configPath + "/home.nix")]
          else []
        )
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/hardware-configuration.nix")
          then [(builtins.dirOf configPath + "/hardware-configuration.nix")]
          else []
        );
    };

  mkRpiNixos = {configPath, ...}:
    inputs.nixos-raspberrypi.lib.nixosSystemFull {
      specialArgs = {
        inherit inputs;
        nixos-raspberrypi = inputs.nixos-raspberrypi;
      };
      modules =
        [
          {nixpkgs.overlays = [(import ../shared/overlays)];}
          inputs.disko.nixosModules.disko
          inputs.home-manager-rpi.nixosModules.home-manager # follows nixos-raspberrypi's nixpkgs
          ./users.nix
          ../shared/system/common.nix
          ../shared/system/linux.nix
          configPath
        ]
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/home.nix")
          then [(builtins.dirOf configPath + "/home.nix")]
          else []
        )
        ++ (
          if builtins.pathExists (builtins.dirOf configPath + "/hardware-configuration.nix")
          then [(builtins.dirOf configPath + "/hardware-configuration.nix")]
          else []
        );
    };
}
