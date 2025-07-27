{
  description = "Fredrik's unified Nix configurations";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    # Stable nixpkgs for Linux/NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # Unstable nixpkgs for macOS/Darwin
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Unstable nixos for Linux/NixOS
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dotfiles = {
      url = "github:fredrikaverpil/dotfiles";
      flake = false;
      # Used by home-manager for dotfiles bootstrapping and git submodule init
    };
  };

  outputs = { self, ... }@inputs:
    let
      lib = import ./nix/lib { inherit inputs; };
    in
    {
      nixosConfigurations = {
        rpi5-homelab = lib.mkNixos { 
          configPath = ./nix/hosts/rpi5-homelab/configuration.nix;
        };
      };

      darwinConfigurations = {
         zap = lib.mkDarwin { 
           configPath = ./nix/hosts/zap/configuration.nix;
         };
         plumbus = lib.mkDarwin { 
           configPath = ./nix/hosts/plumbus/configuration.nix;
         };
      };

      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-darwin = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin.nixfmt;

      devShells = {
        x86_64-linux.default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = [
            inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt
          ];
        };
      };
    };
}
