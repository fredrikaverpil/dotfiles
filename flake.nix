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
      url = "github:fredrikaverpil/dotfiles";  # NOTE: uses the branch 'nix'
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
        # Your Raspberry Pi 5 homelab system configuration
        rpi5-homelab = inputs.nixos-raspberrypi.lib.nixosSystemFull {
          specialArgs = inputs // { nixos-raspberrypi = inputs.nixos-raspberrypi; inherit (inputs) dotfiles; };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.home-manager.nixosModules.home-manager
            # Import hardware configuration from separate file
            ./nix/hosts/rpi5-homelab/hardware.nix
            # Import home-manager configuration from separate file
            ./nix/hosts/rpi5-homelab/home.nix
            # Import main configuration
            ./nix/hosts/rpi5-homelab/configuration.nix
          ];
        };
      };

      darwinConfigurations = {
        zap = lib.mkDarwin { hostname = "zap"; };
        plumbus = lib.mkDarwin { hostname = "plumbus"; };
      };
    };
}
